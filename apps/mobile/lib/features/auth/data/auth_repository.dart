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

  static const _powerSyncUrl = String.fromEnvironment(
    'POWERSYNC_URL',
    defaultValue: 'https://69ac23f57c4f8b306a198f06.powersync.journeyapps.com',
  );

  SupabaseConnector(this.supabase);

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    // Refresh the session to ensure we have a valid token
    final session = supabase.auth.currentSession;
    if (session == null) {
      throw CredentialsException('Sessão Supabase ausente — usuário não autenticado.');
    }

    // If token is about to expire, refresh it
    if (session.isExpired) {
      await supabase.auth.refreshSession();
      final refreshed = supabase.auth.currentSession;
      if (refreshed == null) {
        throw CredentialsException('Falha ao renovar sessão Supabase.');
      }
      return PowerSyncCredentials(
        endpoint: _powerSyncUrl,
        token: refreshed.accessToken,
        userId: refreshed.user.id,
      );
    }

    return PowerSyncCredentials(
      endpoint: _powerSyncUrl,
      token: session.accessToken,
      userId: session.user.id,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    // Implement upload data behavior here when modifying data offline.
  }
}
