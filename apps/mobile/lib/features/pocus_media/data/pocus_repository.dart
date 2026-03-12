import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/powersync_database.dart';
import 'media_cache_manager.dart';
import 'models/media_asset.dart';
import 'models/pocus_item.dart';

part 'pocus_repository.g.dart';

class PocusRepository {
  const PocusRepository(this._db, this._cache);

  final PowerSyncDatabase _db;
  final MediaCacheManager _cache;

  // ── Queries ─────────────────────────────────────────────────────────────

  /// Reactive stream of published POCUS items ordered by category then title.
  Stream<List<PocusItem>> watchPocusItems() {
    return _db
        .watch(
          "SELECT * FROM pocus_items "
          "WHERE status = 'published' "
          "ORDER BY category ASC, title_pt ASC",
        )
        .map((rs) {
          debugPrint('DEBUG: Itens encontrados no SQLite (pocus_items): ${rs.length}');
          if (rs.isNotEmpty) {
            final first = rs.first;
            debugPrint('DEBUG: Primeiro pocus_item — title_pt="${first['title_pt']}", '
                'category="${first['category']}", is_premium="${first['is_premium']}", '
                'status="${first['status']}"');
          }
          return rs.map(PocusItem.fromRow).toList();
        });
  }

  /// Reactive stream of media assets associated with a given [pocusItemId].
  Stream<List<MediaAsset>> watchMediaAssets(String pocusItemId) {
    return _db
        .watch(
          "SELECT * FROM media_assets "
          "WHERE owner_type = 'pocus_items' AND owner_id = ?",
          parameters: [pocusItemId],
        )
        .map((rs) => rs.map(MediaAsset.fromRow).toList());
  }

  // ── Cache façade ─────────────────────────────────────────────────────────

  /// Returns the local file path for [asset], downloading it if needed.
  Future<String?> resolveLocalPath(MediaAsset asset) {
    return _cache.ensureCached(asset.id, asset.path);
  }

  /// Pre-downloads all video assets for a given POCUS item for offline use.
  Future<void> downloadItemForOffline(String pocusItemId) async {
    final rows = await _db.getAll(
      "SELECT id, path FROM media_assets "
      "WHERE owner_type = 'pocus_items' AND owner_id = ? AND kind = 'video'",
      [pocusItemId],
    );
    final assets = rows
        .map((r) => (assetId: r['id'] as String, storagePath: r['path'] as String))
        .toList();
    await _cache.downloadForOffline(assets);
  }
}

@riverpod
PocusRepository pocusRepository(PocusRepositoryRef ref) {
  final db = ref.watch(powerSyncDatabaseProvider);
  final cache = ref.watch(mediaCacheManagerProvider);
  return PocusRepository(db, cache);
}

@riverpod
Stream<List<PocusItem>> watchPocusItems(WatchPocusItemsRef ref) {
  return ref.watch(pocusRepositoryProvider).watchPocusItems();
}

@riverpod
Stream<List<MediaAsset>> watchMediaAssets(
  WatchMediaAssetsRef ref,
  String pocusItemId,
) {
  return ref.watch(pocusRepositoryProvider).watchMediaAssets(pocusItemId);
}
