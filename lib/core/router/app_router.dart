import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/role_selection_screen.dart';
import '../../features/shared/module_screen.dart';
import '../auth/auth_guard.dart';
import '../data/school_modules.dart';
import '../models/app_models.dart';
import '../state/session_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../../widgets/shared_widgets.dart';

GoRouter createRouter(SessionController session) {
  final guard = AuthGuard(session);
  final allModules = [
    ...adminModules,
    ...teacherModules,
    ...studentModules,
    ...parentModules,
  ];
  final primaryModules = session.isAuthenticated
      ? primaryMobileModulesForRole(session.currentRole)
      : <ModuleSpec>[];
  final primaryRoutes = primaryModules.map((module) => module.route).toSet();
  final secondaryModules = allModules
      .where((module) => !primaryRoutes.contains(module.route))
      .toList();

  return GoRouter(
    refreshListenable: session.routerRefresh,
    initialLocation: session.isAuthenticated ? session.homeRoute : '/roles',
    redirect: (context, state) => guard.redirect(state),
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: Text(t(context, 'navError'))),
      body: Center(
        child: Text(state.error?.toString() ?? 'Unknown route: ${state.uri}'),
      ),
    ),
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) =>
            session.isAuthenticated ? session.homeRoute : '/roles',
      ),
      GoRoute(
        path: '/roles',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final roleName = state.uri.queryParameters['role'];
          final role = UserRole.values.firstWhere(
            (item) => item.name == roleName,
            orElse: () => UserRole.admin,
          );
          return LoginScreen(role: role);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      if (session.isAuthenticated)
        ShellRoute(
          builder: (context, state, child) {
            final navigationShell = child is StatefulNavigationShell
                ? child
                : null;
            return AppShell(
              navigationShell: navigationShell,
              child: child,
            );
          },
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (context, state, navigationShell) => navigationShell,
              branches: [
                for (final module in primaryModules)
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: module.route,
                        pageBuilder: (context, state) => NoTransitionPage(
                          key: state.pageKey,
                          child: ModuleScreen(module: module),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            for (final module in secondaryModules)
              GoRoute(
                path: module.route,
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: ModuleScreen(module: module),
                ),
              ),
          ],
        ),
    ],
  );
}
