import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/powersync_database.dart';

part 'media_cache_manager.g.dart';

/// Maximum total disk space used for cached media files (250 MB).
const _kMaxCacheSizeBytes = 250 * 1024 * 1024;

/// Supabase Storage bucket that holds POCUS media assets.
/// Bucket name confirmed via public URL: /storage/v1/object/public/pocus-media/
const _kMediaBucket = 'pocus-media';

/// Validity window for Supabase signed URLs (seconds). Short-lived by design.
const _kSignedUrlTtl = 300; // 5 minutes

/// Lightweight record returned to callers.
class CacheEntry {
  const CacheEntry({
    required this.assetId,
    required this.localPath,
    required this.fileSizeBytes,
    required this.lastAccessedAt,
  });

  final String assetId;
  final String localPath;
  final int fileSizeBytes;
  final DateTime lastAccessedAt;
}

abstract class MediaCacheFileSystem {
  Future<void> deleteFile(String path);
}

class IoMediaCacheFileSystem implements MediaCacheFileSystem {
  @override
  Future<void> deleteFile(String path) async {
    await File(path).delete().catchError((_) => File(path));
  }
}

/// Manages on-disk cache for POCUS media (MP4 / images).
class MediaCacheManager {
  MediaCacheManager(
    this._db, {
    MediaCacheFileSystem? fileSystem,
  }) : _fileSystem = fileSystem ?? IoMediaCacheFileSystem();

  final PowerSyncDatabase _db;
  final MediaCacheFileSystem _fileSystem;

  // In-flight download futures keyed by assetId to prevent duplicate fetches.
  final Map<String, Future<String?>> _inflight = {};

  // ── Public API ─────────────────────────────────────────────────────────

  Future<String?> getLocalPath(String assetId) async {
    final row = await _fetchEntry(assetId);
    if (row == null) return null;

    final file = File(row.localPath);
    if (!await file.exists()) {
      await _deleteEntry(assetId);
      return null;
    }

    await _touchEntry(assetId);
    return row.localPath;
  }

  Future<String?> ensureCached(String assetId, String storagePath) async {
    final cached = await getLocalPath(assetId);
    if (cached != null) return cached;

    return _inflight[assetId] ??= _download(assetId, storagePath).whenComplete(
      () => _inflight.remove(assetId),
    );
  }

  Future<void> downloadForOffline(
    List<({String assetId, String storagePath})> assets,
  ) async {
    for (final a in assets) {
      await ensureCached(a.assetId, a.storagePath);
    }
  }

  Future<List<CacheEntry>> listCachedAssets() async {
    final rows = await _db.getAll(
      'SELECT asset_id, local_path, file_size_bytes, last_accessed_at '
      'FROM media_cache_entries ORDER BY last_accessed_at DESC',
    );
    return rows.map(_rowToCacheEntry).toList();
  }

  Future<void> clearCache() async {
    final entries = await listCachedAssets();
    for (final e in entries) {
      await _fileSystem.deleteFile(e.localPath);
    }
    await _db.execute('DELETE FROM media_cache_entries');
  }

  Future<void> evict(String assetId) async {
    final row = await _fetchEntry(assetId);
    if (row != null) {
      await _fileSystem.deleteFile(row.localPath);
      await _deleteEntry(assetId);
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────

  Future<String?> _download(String assetId, String storagePath) async {
    final ext = p.extension(storagePath).isNotEmpty
        ? p.extension(storagePath)
        : '.mp4';
    final dir = await _cacheDir();
    final localPath = p.join(dir.path, '$assetId$ext');

    Future<void> cleanup() async {
      final f = File(localPath);
      if (await f.exists()) await _fileSystem.deleteFile(localPath);
      await _deleteEntry(assetId);
    }

    try {
      final signedUrl = await Supabase.instance.client.storage
          .from(_kMediaBucket)
          .createSignedUrl(storagePath, _kSignedUrlTtl)
          .timeout(const Duration(seconds: 10));

      final httpClient = HttpClient();
      try {
        final request = await httpClient.getUrl(Uri.parse(signedUrl));
        final response =
            await request.close().timeout(const Duration(seconds: 60));

        if (response.statusCode != 200) {
          await cleanup();
          return null;
        }

        final contentType = response.headers.contentType?.mimeType ?? '';
        final isVideo = contentType.startsWith('video/');
        final isOctet = contentType == 'application/octet-stream';
        if (!isVideo && !isOctet && contentType.isNotEmpty) {
          await cleanup();
          return null;
        }

        final file = File(localPath);
        final sink = file.openWrite();
        await response.pipe(sink);
        await sink.flush();
        await sink.close();

        final fileSizeBytes = await file.length();
        if (fileSizeBytes == 0) {
          await cleanup();
          return null;
        }

        await _upsertEntry(assetId, localPath, fileSizeBytes);
        await _evictIfNeeded();

        return localPath;
      } finally {
        httpClient.close();
      }
    } on TimeoutException {
      await cleanup();
      return null;
    } catch (_) {
      await cleanup();
      return null;
    }
  }

  Future<void> _evictIfNeeded() async {
    final rows = await _db.getAll(
      'SELECT asset_id, local_path, file_size_bytes '
      'FROM media_cache_entries ORDER BY last_accessed_at ASC',
    );

    int total = rows.fold(0, (sum, r) => sum + (r['file_size_bytes'] as int? ?? 0));

    for (final row in rows) {
      final assetId = row['asset_id'] as String;
      final localPath = row['local_path'] as String;
      final size = row['file_size_bytes'] as int? ?? 0;

      await _fileSystem.deleteFile(localPath);
      await _deleteEntry(assetId);
      total -= size;
      if (total <= _kMaxCacheSizeBytes) break;
    }
  }

  @visibleForTesting
  Future<void> evictIfNeededForTest() => _evictIfNeeded();

  Future<Directory> _cacheDir() async {
    final base = await getApplicationCacheDirectory();
    final dir = Directory(p.join(base.path, 'pocus_media'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<CacheEntry?> _fetchEntry(String assetId) async {
    final rows = await _db.getAll(
      'SELECT asset_id, local_path, file_size_bytes, last_accessed_at '
      'FROM media_cache_entries WHERE asset_id = ?',
      [assetId],
    );
    if (rows.isEmpty) return null;
    return _rowToCacheEntry(rows.first);
  }

  Future<void> _upsertEntry(
      String assetId, String localPath, int fileSizeBytes) async {
    final now = DateTime.now().toIso8601String();
    await _db.execute(
      'INSERT OR REPLACE INTO media_cache_entries '
      '(id, asset_id, local_path, file_size_bytes, downloaded_at, last_accessed_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      [assetId, assetId, localPath, fileSizeBytes, now, now],
    );
  }

  Future<void> _touchEntry(String assetId) async {
    await _db.execute(
      'UPDATE media_cache_entries SET last_accessed_at = ? WHERE asset_id = ?',
      [DateTime.now().toIso8601String(), assetId],
    );
  }

  Future<void> _deleteEntry(String assetId) async {
    await _db.execute(
      'DELETE FROM media_cache_entries WHERE asset_id = ?',
      [assetId],
    );
  }

  CacheEntry _rowToCacheEntry(Map<String, dynamic> row) => CacheEntry(
        assetId: row['asset_id'] as String,
        localPath: row['local_path'] as String,
        fileSizeBytes: row['file_size_bytes'] as int? ?? 0,
        lastAccessedAt: DateTime.parse(row['last_accessed_at'] as String),
      );
}

@Riverpod(keepAlive: true)
MediaCacheManager mediaCacheManager(MediaCacheManagerRef ref) {
  final db = ref.watch(powerSyncDatabaseProvider);
  return MediaCacheManager(db);
}
