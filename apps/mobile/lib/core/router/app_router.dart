import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/powersync_database.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/calculators/presentation/calculator_detail_screen.dart';
import '../../features/calculators/presentation/calculators_hub_screen.dart';
import '../../features/drugs/data/models/drug.dart';
import '../../features/drugs/presentation/drug_detail_screen.dart';
import '../../features/drugs/presentation/drugs_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/clinical_guide/presentation/clinical_guides_screen.dart';
import '../../features/clinical_guide/presentation/clinical_guide_detail_screen.dart';
import '../../features/clinical_guide/presentation/clinical_topic_screen.dart';
import '../../features/clinical_guide/presentation/clinical_guides_by_topic_screen.dart';
import '../../features/clinical_guide/data/models/clinical_guide.dart';
import '../../features/pocus_media/presentation/pocus_screen.dart';
import '../../features/pocus_media/presentation/pocus_player_screen.dart';
import '../../features/pocus_media/data/models/pocus_item.dart';
import '../../features/account/presentation/account_screen.dart';
import '../../features/simulator/presentation/screens/simulator_screen.dart';
import 'main_navigation.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      final session = authState.value?.session;

      final isLoggingIn = state.matchedLocation == '/login';

      if (session == null && !isLoggingIn) {
        return '/login';
      }
      if (session != null && isLoggingIn) {
        // Reconecta PowerSync após login bem-sucedido
        PowerSyncService.instance.db.connect(
          connector: SupabaseConnector(Supabase.instance.client),
        );
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => '/home',
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigation(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0 — Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'calculators',
                    builder: (context, state) => const CalculatorsHubScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return CalculatorDetailScreen(calculatorId: id);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'drugs',
                    builder: (context, state) => const DrugsScreen(),
                    routes: [
                      GoRoute(
                        path: 'detail/:slug',
                        redirect: (context, state) {
                          if (state.extra is! Drug) return '/home/drugs';
                          return null;
                        },
                        builder: (context, state) {
                          final drug = state.extra! as Drug;
                          return DrugDetailScreen(drug: drug);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Branch 1 — Guia Clínico
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guide',
                builder: (context, state) => const ClinicalGuidesScreen(),
                routes: [
                  GoRoute(
                    path: 'detail/:slug',
                    redirect: (context, state) {
                      if (state.extra is! ClinicalGuide) return '/guide';
                      return null;
                    },
                    builder: (context, state) {
                      final guide = state.extra! as ClinicalGuide;
                      return ClinicalGuideDetailScreen(guide: guide);
                    },
                  ),
                  GoRoute(
                    path: 'category/:categoryId',
                    builder: (context, state) {
                      final id = state.pathParameters['categoryId']!;
                      return ClinicalTopicScreen(categoryId: id);
                    },
                  ),
                  GoRoute(
                    path: 'topic/:topicId',
                    builder: (context, state) {
                      final id = state.pathParameters['topicId']!;
                      return ClinicalGuidesByTopicScreen(topicId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 2 — POCUS
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pocus',
                builder: (context, state) => const PocusScreen(),
                routes: [
                  GoRoute(
                    path: 'player/:id',
                    redirect: (context, state) {
                      if (state.extra is! PocusItem) return '/pocus';
                      return null;
                    },
                    builder: (context, state) {
                      final item = state.extra! as PocusItem;
                      return PocusPlayerScreen(pocusItem: item);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 3 — Simulador
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/simulator',
                builder: (context, state) => const SimulatorScreen(),
              ),
            ],
          ),
          // Branch 4 — Conta
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account',
                builder: (context, state) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.listen(authStateChangesProvider, (_, __) => router.refresh());
  ref.onDispose(router.dispose);

  return router;
}
