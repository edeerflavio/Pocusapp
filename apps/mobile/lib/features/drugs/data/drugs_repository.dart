import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';

import '../../../core/database/powersync_database.dart';
import 'models/drug.dart';

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class DrugsRepository {
  const DrugsRepository(this._db);

  final PowerSyncDatabase _db;

  /// All published drugs ordered alphabetically by Portuguese title.
  Stream<List<Drug>> watchAll() {
    return _db
        .watch(
          "SELECT * FROM drugs "
          "WHERE status = 'published' "
          "ORDER BY title_pt ASC",
        )
        .map((rs) => rs.map(Drug.fromRow).toList());
  }

  /// Single drug by slug — null if not found.
  Future<Drug?> findBySlug(String slug) async {
    final rows = await _db.getAll(
      "SELECT * FROM drugs WHERE slug = ? LIMIT 1",
      [slug],
    );
    if (rows.isEmpty) return null;
    return Drug.fromRow(rows.first);
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final drugsRepositoryProvider = Provider<DrugsRepository>((ref) {
  final db = ref.watch(powerSyncDatabaseProvider);
  return DrugsRepository(db);
});

final watchDrugsProvider = StreamProvider<List<Drug>>((ref) {
  return ref.watch(drugsRepositoryProvider).watchAll();
});
