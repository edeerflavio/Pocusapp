import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:powersync/powersync.dart';

part 'auth_repository.g.dart';

@riverpod
GoTrueClient authRepository(AuthRepositoryRef ref) {
  return Supabase.instance.client.auth;
}

@riverpod
Stream<AuthState> authStateChanges(AuthStateChangesRef ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChange;
}

class SupabaseConnector extends PowerSyncBackendConnector {
  final SupabaseClient supabase;

  SupabaseConnector(this.supabase);

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    // Refresh se o token estiver expirado ou próximo de expirar
    final response = await supabase.auth.refreshSession();
    final session = response.session ?? supabase.auth.currentSession;
    if (session == null) return null;

    return PowerSyncCredentials(
      endpoint: const String.fromEnvironment('POWERSYNC_URL'),
      token: session.accessToken,
      userId: session.user.id,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    // Implement upload data behavior here when modifying data offline.
  }
}
