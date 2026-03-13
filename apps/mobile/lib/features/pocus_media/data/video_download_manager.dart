import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Download task state — immutable, equality by value.
// ---------------------------------------------------------------------------

enum DownloadStatus { idle, downloading, completed, error }

@immutable
class DownloadTask {
  const DownloadTask({
    this.status = DownloadStatus.idle,
    this.progress = 0.0,
    this.localPath,
    this.error,
  });

  final DownloadStatus status;
  final double progress;
  final String? localPath;
  final String? error;

  DownloadTask copyWith({
    DownloadStatus? status,
    double? progress,
    String? localPath,
    String? error,
  }) =>
      DownloadTask(
        status: status ?? this.status,
        progress: progress ?? this.progress,
        localPath: localPath ?? this.localPath,
        error: error ?? this.error,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadTask &&
          status == other.status &&
          progress == other.progress &&
          localPath == other.localPath &&
          error == other.error;

  @override
  int get hashCode => Object.hash(status, progress, localPath, error);
}

// ---------------------------------------------------------------------------
// VideoDownloadManager — global, keepAlive.
//
// Owns all video download state. Widgets observe via
// `ref.watch(videoDownloadManagerProvider.select(...))` and can detach/
// reattach freely without cancelling or duplicating downloads.
// ---------------------------------------------------------------------------

class VideoDownloadManager extends ChangeNotifier {
  final Map<String, DownloadTask> _tasks = {};
  final Map<String, Future<String?>> _inflight = {};
  String? _cacheDirPath;

  /// Current state for [storagePath]. Returns idle if never requested.
  DownloadTask taskFor(String storagePath) =>
      _tasks[storagePath] ?? const DownloadTask();

  /// Ensures the video at [storagePath] is downloaded.
  ///
  /// - Cache hit → returns local path immediately.
  /// - In-flight → attaches to the existing download (no duplicate).
  /// - Cache miss → starts a new download; progress emitted via
  ///   [ChangeNotifier.notifyListeners].
  Future<String?> ensureDownloaded(String storagePath) async {
    final existing = _tasks[storagePath];
    if (existing != null && existing.status == DownloadStatus.completed) {
      // Verify file still exists on disk.
      final file = File(existing.localPath!);
      if (await file.exists() && await file.length() > 0) {
        return existing.localPath;
      }
      // File was evicted from disk — re-download.
      _tasks.remove(storagePath);
    }

    return _inflight[storagePath] ??=
        _download(storagePath).whenComplete(() => _inflight.remove(storagePath));
  }

  // ── Private ──────────────────────────────────────────────────────────────

  Future<String?> _download(String storagePath) async {
    _emit(storagePath, const DownloadTask(status: DownloadStatus.downloading));

    try {
      final dir = await _ensureCacheDir();
      final localPath = p.join(dir, _cacheFileName(storagePath));
      final file = File(localPath);

      // Cache hit (file already on disk).
      if (await file.exists() && await file.length() > 0) {
        _emit(
          storagePath,
          DownloadTask(
            status: DownloadStatus.completed,
            progress: 1.0,
            localPath: localPath,
          ),
        );
        return localPath;
      }

      // Get Supabase signed URL.
      final signedUrl = await Supabase.instance.client.storage
          .from('pocus-media')
          .createSignedUrl(storagePath, 300)
          .timeout(const Duration(seconds: 10));

      // Stream download to disk (avoids OOM on large MP4s).
      final httpClient = HttpClient();
      try {
        final request = await httpClient.getUrl(Uri.parse(signedUrl));
        final response =
            await request.close().timeout(const Duration(seconds: 120));

        if (response.statusCode != 200) {
          _emit(
            storagePath,
            DownloadTask(
              status: DownloadStatus.error,
              error: 'HTTP ${response.statusCode}',
            ),
          );
          return null;
        }

        final contentLength = response.contentLength;
        final sink = file.openWrite();
        int received = 0;

        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;
          if (contentLength > 0) {
            _emit(
              storagePath,
              DownloadTask(
                status: DownloadStatus.downloading,
                progress: received / contentLength,
              ),
            );
          }
        }

        await sink.flush();
        await sink.close();

        // Validate download.
        if (await file.length() == 0) {
          await file.delete().catchError((_) => file);
          _emit(
            storagePath,
            const DownloadTask(
              status: DownloadStatus.error,
              error: 'Download vazio',
            ),
          );
          return null;
        }

        _emit(
          storagePath,
          DownloadTask(
            status: DownloadStatus.completed,
            progress: 1.0,
            localPath: localPath,
          ),
        );
        return localPath;
      } finally {
        httpClient.close();
      }
    } on TimeoutException {
      _emit(
        storagePath,
        const DownloadTask(
          status: DownloadStatus.error,
          error: 'Tempo esgotado',
        ),
      );
      return null;
    } catch (e) {
      debugPrint('VideoDownloadManager error for $storagePath: $e');
      _emit(
        storagePath,
        const DownloadTask(
          status: DownloadStatus.error,
          error: 'Falha ao carregar vídeo',
        ),
      );
      return null;
    }
  }

  void _emit(String storagePath, DownloadTask task) {
    _tasks[storagePath] = task;
    notifyListeners();
  }

  Future<String> _ensureCacheDir() async {
    if (_cacheDirPath != null) return _cacheDirPath!;
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'pocus_video_cache'));
    if (!await dir.exists()) await dir.create(recursive: true);
    _cacheDirPath = dir.path;
    return _cacheDirPath!;
  }

  /// Deterministic cache filename from a storage path.
  /// E.g. "E-Fast/teste1.mp4" → "a1b2c3d4e5.mp4"
  static String _cacheFileName(String storagePath) {
    final hash = md5.convert(utf8.encode(storagePath)).toString();
    final ext =
        p.extension(storagePath).isNotEmpty ? p.extension(storagePath) : '.mp4';
    return '$hash$ext';
  }
}

// ---------------------------------------------------------------------------
// Provider — keepAlive (ChangeNotifierProvider is NOT auto-dispose by default).
// ---------------------------------------------------------------------------

final videoDownloadManagerProvider =
    ChangeNotifierProvider<VideoDownloadManager>((ref) {
  return VideoDownloadManager();
});
