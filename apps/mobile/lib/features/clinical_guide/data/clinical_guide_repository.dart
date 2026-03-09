import 'package:powersync/powersync.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/powersync_database.dart';
import 'models/disease.dart';

part 'clinical_guide_repository.g.dart';

class ClinicalGuideRepository {
  const ClinicalGuideRepository(this._db);

  final PowerSyncDatabase _db;

  Stream<List<Disease>> watchDiseases() {
    return _db
        .watch('SELECT * FROM diseases ORDER BY title_pt ASC')
        .map((results) => results.map(Disease.fromRow).toList());
  }
}

@riverpod
ClinicalGuideRepository clinicalGuideRepository(
    ClinicalGuideRepositoryRef ref) {
  final db = ref.watch(powerSyncDatabaseProvider);
  return ClinicalGuideRepository(db);
}

@riverpod
Stream<List<Disease>> watchDiseases(WatchDiseasesRef ref) {
  return ref.watch(clinicalGuideRepositoryProvider).watchDiseases();
}
