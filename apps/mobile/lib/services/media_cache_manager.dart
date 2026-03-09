import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages downloading and caching media files from Supabase Storage.
///
/// Key design decisions:
/// - Timeout on createSignedUrl to avoid infinite spinner
/// - Files cached on disk so they work offline
/// - Errors are surfaced, not swallowed silently
class MediaCacheManager {
  static const _bucketName = 'pocus_media';
  static const _signedUrlTimeout = Duration(seconds: 10);
  static const _downloadTimeout = Duration(seconds: 60);
  static const _signedUrlExpiry = 3600; // 1 hour

  final SupabaseClient _supabase;

  /// In-flight download futures to avoid duplicate requests.
  final Map<String, Future<File?>> _pending = {};

  MediaCacheManager(this._supabase);

  /// Returns a local [File] for the given storage [path].
  ///
  /// If the file is already cached on disk, returns it immediately.
  /// Otherwise downloads it from Supabase Storage.
  /// Returns `null` only if the download fails (error is logged).
  Future<File?> getFile(String storagePath) {
    // Deduplicate concurrent requests for the same path
    return _pending.putIfAbsent(storagePath, () async {
      try {
        return await _resolveFile(storagePath);
      } finally {
        _pending.remove(storagePath);
      }
    });
  }

  Future<File?> _resolveFile(String storagePath) async {
    final localFile = await _localFile(storagePath);

    // Return cached file if it exists
    if (await localFile.exists()) {
      return localFile;
    }

    // Download from Supabase Storage
    return _download(storagePath, localFile);
  }

  Future<File?> _download(String storagePath, File destination) async {
    try {
      // 1. Get signed URL with timeout to avoid infinite hang
      final signedUrl = await _supabase.storage
          .from(_bucketName)
          .createSignedUrl(storagePath, _signedUrlExpiry)
          .timeout(
            _signedUrlTimeout,
            onTimeout: () => throw TimeoutException(
              'createSignedUrl timed out after ${_signedUrlTimeout.inSeconds}s '
              'for path: $storagePath',
            ),
          );

      // 2. Download bytes with timeout
      final httpClient = HttpClient();
      try {
        final request = await httpClient
            .getUrl(Uri.parse(signedUrl))
            .timeout(_downloadTimeout);
        final response = await request.close().timeout(_downloadTimeout);

        if (response.statusCode != 200) {
          print('[MediaCacheManager] HTTP ${response.statusCode} '
              'downloading $storagePath');
          return null;
        }

        final bytes = await _collectBytes(response).timeout(_downloadTimeout);

        // 3. Write to disk
        await destination.parent.create(recursive: true);
        await destination.writeAsBytes(bytes);

        return destination;
      } finally {
        httpClient.close();
      }
    } on TimeoutException catch (e) {
      print('[MediaCacheManager] TIMEOUT: $e');
      return null;
    } catch (e, stack) {
      print('[MediaCacheManager] ERROR downloading $storagePath: $e');
      print('[MediaCacheManager] Stack: $stack');
      return null;
    }
  }

  Future<Uint8List> _collectBytes(HttpClientResponse response) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  /// Returns the expected local cache path for a storage path.
  Future<File> _localFile(String storagePath) async {
    final cacheDir = await getApplicationCacheDirectory();
    final safePath = storagePath.replaceAll('/', Platform.pathSeparator);
    return File(p.join(cacheDir.path, 'media_cache', safePath));
  }

  /// Clears all cached media files.
  Future<void> clearCache() async {
    final cacheDir = await getApplicationCacheDirectory();
    final mediaDir = Directory(p.join(cacheDir.path, 'media_cache'));
    if (await mediaDir.exists()) {
      await mediaDir.delete(recursive: true);
    }
  }
}

/// Thrown when an operation exceeds its time limit.
class TimeoutException implements Exception {
  final String message;
  const TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
