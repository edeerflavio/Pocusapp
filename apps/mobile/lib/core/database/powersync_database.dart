import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'schema.dart';

part 'powersync_database.g.dart';

class PowerSyncService {
  static final PowerSyncService instance = PowerSyncService._internal();

  PowerSyncService._internal();

  late final PowerSyncDatabase db;

  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'powersync.db');

    db = PowerSyncDatabase(
      schema: schema,
      path: path,
    );
    await db.initialize();
  }
}

@Riverpod(keepAlive: true)
PowerSyncService powerSyncService(PowerSyncServiceRef ref) {
  return PowerSyncService.instance;
}

@Riverpod(keepAlive: true)
PowerSyncDatabase powerSyncDatabase(PowerSyncDatabaseRef ref) {
  return ref.watch(powerSyncServiceProvider).db;
}
