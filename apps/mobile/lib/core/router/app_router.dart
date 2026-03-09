import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/clinical_guide/presentation/clinical_guide_screen.dart';
import '../../features/clinical_guide/presentation/disease_details_screen.dart';
import '../../features/clinical_guide/data/models/disease.dart';
import '../../features/pocus_media/presentation/pocus_screen.dart';
import '../../features/pocus_media/presentation/pocus_player_screen.dart';
import '../../features/pocus_media/data/models/pocus_item.dart';
import '../../features/account/presentation/account_screen.dart';
import '../../../simulator/ui/simulator_screen.dart';
import 'main_navigation.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/guide',
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      final session = authState.value?.session;
      
      final isLoggingIn = state.matchedLocation == '/login';
      
      if (session == null && !isLoggingIn) {
        return '/login';
      }
      if (session != null && isLoggingIn) {
        return '/guide';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => '/guide',
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guide',
                builder: (context, state) => const ClinicalGuideScreen(),
                routes: [
                  GoRoute(
                    path: 'disease/:id',
                    builder: (context, state) {
                      final disease = state.extra as Disease;
                      return DiseaseDetailsScreen(disease: disease);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pocus',
                builder: (context, state) => const PocusScreen(),
                routes: [
                  GoRoute(
                    path: 'player/:id',
                    builder: (context, state) {
                      final item = state.extra as PocusItem;
                      return PocusPlayerScreen(pocusItem: item);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/simulator',
                builder: (context, state) => const SimulatorScreen(),
              ),
            ],
          ),
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
