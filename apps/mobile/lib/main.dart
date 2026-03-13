import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/database/powersync_database.dart';
import 'features/auth/data/auth_repository.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://fhcreismmrjlexpukeit.supabase.co',
);

const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZoY3JlaXNtbXJqbGV4cHVla2l0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI3NDA1NzMsImV4cCI6MjA4ODMxNjU3M30.Af_pj2Opm4yw36oQZwnOwqWlYUiDSnJweNlG8aiVUrI',
);

String _resolveEnv(String value, String fallback, String name) {
  if (value.isNotEmpty) return value;
  if (kDebugMode) {
    debugPrint('⚠️  $name está vazio no --dart-define, usando fallback.');
  }
  return fallback;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- 1. Resolve & validate Supabase credentials ---
  final url = _resolveEnv(
    _supabaseUrl,
    'https://fhcreismmrjlexpukeit.supabase.co',
    'SUPABASE_URL',
  );
  final anonKey = _resolveEnv(
    _supabaseAnonKey,
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZoY3JlaXNtbXJqbGV4cHVla2l0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI3NDA1NzMsImV4cCI6MjA4ODMxNjU3M30.Af_pj2Opm4yw36oQZwnOwqWlYUiDSnJweNlG8aiVUrI',
    'SUPABASE_ANON_KEY',
  );

  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw StateError(
      'SUPABASE_URL inválida ("$url"). '
      'Verifique --dart-define=SUPABASE_URL=https://…',
    );
  }

  await Supabase.initialize(url: url, anonKey: anonKey);

  // --- 2. Initialize PowerSync (local DB only) ---
  final powerSyncService = PowerSyncService.instance;
  await powerSyncService.initialize();

  // --- 3. Connect PowerSync only when there is a valid session ---
  final supabase = Supabase.instance.client;
  final connector = SupabaseConnector(supabase);

  void connectPowerSyncIfAuthenticated() {
    if (supabase.auth.currentSession != null) {
      powerSyncService.db.connect(connector: connector);
    }
  }

  // Try to connect now (user may have a persisted session)
  connectPowerSyncIfAuthenticated();

  // Re-connect whenever auth state changes (login / token refresh)
  supabase.auth.onAuthStateChange.listen((event) {
    if (event.event == AuthChangeEvent.signedIn ||
        event.event == AuthChangeEvent.tokenRefreshed) {
      connectPowerSyncIfAuthenticated();
    }
    if (event.event == AuthChangeEvent.signedOut) {
      powerSyncService.db.disconnect();
    }
  });

  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'AMPLE',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
