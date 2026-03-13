import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pocusapp/features/pocus_media/data/media_cache_manager.dart';
import 'package:powersync/powersync.dart';
import 'package:sqlite3/sqlite3.dart';

class MockPowerSyncDatabase extends Mock implements PowerSyncDatabase {}

class MockMediaCacheFileSystem extends Mock implements MediaCacheFileSystem {}

void main() {
  late MockPowerSyncDatabase db;
  late MockMediaCacheFileSystem fileSystem;
  late MediaCacheManager manager;

  setUpAll(() {
    registerFallbackValue(<Object?>[]);
  });

  setUp(() {
    db = MockPowerSyncDatabase();
    fileSystem = MockMediaCacheFileSystem();
    manager = MediaCacheManager(db, fileSystem: fileSystem);
  });

  test(
    'evicts the oldest file and stops once total reaches the cache limit after subtraction',
    () async {
      final oldestSize = 10;
      final newestSize = 250 * 1024 * 1024;
      final resultSet = ResultSet(
        ['asset_id', 'local_path', 'file_size_bytes'],
        [null, null, null],
        [
          ['oldest', '/cache/oldest.mp4', oldestSize],
          ['newest', '/cache/newest.mp4', newestSize],
        ],
      );

      when(
        () => db.getAll(
          any(),
        ),
      ).thenAnswer((_) async => resultSet);
      when(() => fileSystem.deleteFile('/cache/oldest.mp4'))
          .thenAnswer((_) async {});
      when(() => db.execute(any(), any()))
          .thenAnswer((_) async => ResultSet(const [], const [], const []));

      await manager.evictIfNeededForTest();

      verify(() => fileSystem.deleteFile('/cache/oldest.mp4')).called(1);
      verify(
        () => db.execute(
          'DELETE FROM media_cache_entries WHERE asset_id = ?',
          ['oldest'],
        ),
      ).called(1);
      verifyNever(() => fileSystem.deleteFile('/cache/newest.mp4'));
      verifyNever(
        () => db.execute(
          'DELETE FROM media_cache_entries WHERE asset_id = ?',
          ['newest'],
        ),
      );
    },
  );
}
