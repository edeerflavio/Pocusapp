import 'dart:async';
import 'dart:io';

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
const _kMediaBucket = 'pocus-media';

/// Validity window for Supabase signed URLs (seconds). Short-lived by design.
const _kSignedUrlTtl = 300; // 5 minutes

/// Status of a single asset's cache entry.
enum CacheStatus { notCached, downloading, cached, error }

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

/// Manages on-disk cache for POCUS media (MP4 / images).
///
/// Design:
///  • Metadata is stored in the local-only `media_cache_entries` table
///    (PowerSync, never synced to server).
///  • Binary files live in `<cacheDir>/pocus_media/<assetId>.<ext>`.
///  • Eviction uses LRU: files with the oldest `last_accessed_at` are
///    removed first when the total cache exceeds [_kMaxCacheSizeBytes].
///  • Signed URLs are fetched on-demand and never persisted, keeping
///    tokens ephemeral and rotation-safe.
class MediaCacheManager {
  MediaCacheManager(this._db);

  final PowerSyncDatabase _db;

  // In-flight download futures keyed by assetId to prevent duplicate fetches.
  final Map<String, Future<String?>> _inflight = {};

  // ── Public API ─────────────────────────────────────────────────────────

  /// Returns the local file path if [assetId] is cached, otherwise null.
  /// Updates last_accessed_at so the entry stays warm in LRU order.
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

  /// Returns a local path, downloading the asset first if necessary.
  /// Returns null if the download fails.
  Future<String?> ensureCached(String assetId, String storagePath) async {
    final cached = await getLocalPath(assetId);
    if (cached != null) return cached;

    // Coalesce concurrent callers for the same asset.
    return _inflight[assetId] ??= _download(assetId, storagePath).whenComplete(
      () => _inflight.remove(assetId),
    );
  }

  /// Pre-fetches a list of assets for offline use.
  /// Skips assets that are already cached. Downloads are sequential to
  /// avoid saturating the connection on mobile.
  Future<void> downloadForOffline(
    List<({String assetId, String storagePath})> assets,
  ) async {
    for (final a in assets) {
      await ensureCached(a.assetId, a.storagePath);
    }
  }

  /// Returns cache metadata for all currently cached assets.
  Future<List<CacheEntry>> listCachedAssets() async {
    final rows = await _db.getAll(
      'SELECT asset_id, local_path, file_size_bytes, last_accessed_at '
      'FROM media_cache_entries ORDER BY last_accessed_at DESC',
    );
    return rows.map(_rowToCacheEntry).toList();
  }

  /// Removes all cached files and their metadata records.
  Future<void> clearCache() async {
    final entries = await listCachedAssets();
    for (final e in entries) {
      await File(e.localPath).delete().catchError((_) {});
    }
    await _db.execute('DELETE FROM media_cache_entries');
  }

  /// Removes a single cached asset from disk and metadata store.
  Future<void> evict(String assetId) async {
    final row = await _fetchEntry(assetId);
    if (row != null) {
      await File(row.localPath).delete().catchError((_) {});
      await _deleteEntry(assetId);
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────

  Future<String?> _download(String assetId, String storagePath) async {
    try {
      // 1. Fetch a short-lived signed URL — token is never stored.
      // Timeout prevents indefinite hang when the device is offline.
      final signedUrl = await Supabase.instance.client.storage
          .from(_kMediaBucket)
          .createSignedUrl(storagePath, _kSignedUrlTtl)
          .timeout(const Duration(seconds: 10));

      // 2. Determine local destination path.
      final ext = p.extension(storagePath).isNotEmpty
          ? p.extension(storagePath)
          : '.mp4';
      final dir = await _cacheDir();
      final localPath = p.join(dir.path, '$assetId$ext');

      // 3. Stream download directly to disk (avoids loading MP4 into memory).
      final httpClient = HttpClient();
      try {
        final request = await httpClient.getUrl(Uri.parse(signedUrl));
        final response = await request.close();

        if (response.statusCode != 200) return null;

        final file = File(localPath);
        final sink = file.openWrite();
        await response.pipe(sink);
        await sink.flush();
        await sink.close();

        final fileSizeBytes = await file.length();

        // 4. Persist metadata and run LRU eviction if needed.
        await _upsertEntry(assetId, localPath, fileSizeBytes);
        await _evictIfNeeded();

        return localPath;
      } finally {
        httpClient.close();
      }
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Removes LRU entries until total cache usage is below the size cap.
  Future<void> _evictIfNeeded() async {
    final rows = await _db.getAll(
      'SELECT asset_id, local_path, file_size_bytes '
      'FROM media_cache_entries ORDER BY last_accessed_at ASC',
    );

    int total = rows.fold(0, (sum, r) => sum + (r['file_size_bytes'] as int? ?? 0));

    for (final row in rows) {
      if (total <= _kMaxCacheSizeBytes) break;
      final assetId = row['asset_id'] as String;
      final localPath = row['local_path'] as String;
      final size = row['file_size_bytes'] as int? ?? 0;

      await File(localPath).delete().catchError((_) {});
      await _deleteEntry(assetId);
      total -= size;
    }
  }

  // ── DB helpers ─────────────────────────────────────────────────────────

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

@riverpod
MediaCacheManager mediaCacheManager(MediaCacheManagerRef ref) {
  final db = ref.watch(powerSyncDatabaseProvider);
  return MediaCacheManager(db);
}
