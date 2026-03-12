import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/powersync_database.dart';
import 'models/clinical_guide.dart';

part 'clinical_guides_repository.g.dart';

class ClinicalGuidesRepository {
  const ClinicalGuidesRepository(this._db);

  final PowerSyncDatabase _db;

  /// All published guides ordered by scenario then title.
  Stream<List<ClinicalGuide>> watchAll() {
    return _db
        .watch(
          "SELECT * FROM clinical_guides "
          "WHERE status = 'published' "
          "ORDER BY scenario ASC, title ASC",
        )
        .map((rs) {
          debugPrint('DEBUG: Itens encontrados no SQLite: ${rs.length}');
          if (rs.isNotEmpty) {
            final first = rs.first;
            debugPrint('DEBUG: Primeiro item — title="${first['title']}", '
                'specialty="${first['specialty']}", status="${first['status']}", '
                'tags="${first['tags']}"');
          }
          return rs.map(ClinicalGuide.fromRow).toList();
        });
  }

  /// Single guide by slug — null if not found.
  Future<ClinicalGuide?> findBySlug(String slug) async {
    final rows = await _db.getAll(
      "SELECT * FROM clinical_guides WHERE slug = ? LIMIT 1",
      [slug],
    );
    if (rows.isEmpty) return null;
    return ClinicalGuide.fromRow(rows.first);
  }
}

@riverpod
ClinicalGuidesRepository clinicalGuidesRepository(
    ClinicalGuidesRepositoryRef ref) {
  final db = ref.watch(powerSyncDatabaseProvider);
  return ClinicalGuidesRepository(db);
}

@riverpod
Stream<List<ClinicalGuide>> watchClinicalGuides(
    WatchClinicalGuidesRef ref) {
  return ref.watch(clinicalGuidesRepositoryProvider).watchAll();
}
