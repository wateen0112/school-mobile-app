import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/installments/presentation/screens/installment_detail_screen.dart';
import '../../features/installments/presentation/screens/installment_plan_detail_screen.dart';
import '../../features/installments/presentation/screens/installment_plans_screen.dart';
import '../../features/installments/presentation/screens/my_installments_screen.dart';
import '../../features/notifications/notification_screen.dart';
import '../../features/shared/module_screen.dart';
import '../../features/parents/parent_detail_screen.dart';
import '../../features/exams/exams_list_screen.dart';
import '../../features/exams/exam_start_screen.dart';
import '../../features/exams/exam_result_screen.dart';
import '../auth/auth_guard.dart';
import '../data/school_modules.dart';
import '../models/app_models.dart';
import '../models/notification_models.dart';
import '../../features/installments/domain/models/my_installment_model.dart';
import '../state/session_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../../features/transportation/presentation/driver/driver_trip_screen.dart';
import '../../features/transportation/presentation/parent/parent_trip_screen.dart';

GoRouter createRouter(
  SessionController session, {
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  final guard = AuthGuard(session);
  final allModules = [
    ...teacherModules,
    ...studentModules,
    ...parentModules,
    ...driverModules,
    ...adminModules,
  ];
  final primaryModules = session.isAuthenticated
      ? primaryMobileModulesForRole(session.currentRole)
      : <ModuleSpec>[];
  final primaryRoutes = primaryModules.map((module) => module.route).toSet();
  final secondaryModules = allModules
      .where((module) => !primaryRoutes.contains(module.route))
      .toList();

  return GoRouter(
    navigatorKey: navigatorKey,
    refreshListenable: session.routerRefresh,
    initialLocation: session.isAuthenticated ? session.homeRoute : '/login',
    redirect: (context, state) => guard.redirect(state),
    errorBuilder: (context, state) {
      // Transient mismatch can occur while the router is being rebuilt
      // around an auth change (the old route table predates the new role's
      // routes). Never surface a navigation error to the user — resolve to
      // the user's home route instead.
      final home = session.homeRoute;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (state.uri.path != home) context.go(home);
      });
      return Scaffold(
        backgroundColor: AppTheme.surface,
        body: const SizedBox.shrink(),
      );
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) =>
            session.isAuthenticated ? session.homeRoute : '/login',
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
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
            GoRoute(
              path: '/notifications',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: const NotificationsScreen(),
              ),
            ),
            GoRoute(
              path: '/notification-detail',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: NotificationDetailScreen(
                  notification: state.extra as NotificationItem,
                ),
              ),
            ),
            GoRoute(
              path: '/parents/:id',
              pageBuilder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                return MaterialPage(
                  key: state.pageKey,
                  child: ParentDetailScreen(parentId: id),
                );
              },
            ),
            GoRoute(
              path: '/driver/active-trip',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: DriverTripScreen(tripId: state.extra as int),
              ),
            ),
            GoRoute(
              path: '/parent/transport-trip',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: ParentTripScreen(studentId: state.extra as int),
              ),
            ),
            GoRoute(
              path: '/my-installments',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: MyInstallmentsScreen(
                  studentInstallmentId: state.extra as int?,
                ),
              ),
            ),
            GoRoute(
              path: '/schedule',
              redirect: (context, state) {
                final module =
                    moduleByKey('${session.currentRole.name}-schedule');
                return module?.route ?? session.homeRoute;
              },
            ),
            GoRoute(
              path: '/installment-detail',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: InstallmentDetailScreen(
                  installment: state.extra as MyInstallment,
                ),
              ),
            ),
            GoRoute(
              path: '/installment-plans',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: const InstallmentPlansScreen(),
              ),
            ),
            GoRoute(
              path: '/installment-plan-detail',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: InstallmentPlanDetailScreen(
                  planId: state.extra as int,
                ),
              ),
            ),
            GoRoute(
              path: '/student/exams',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: const ExamsListScreen(),
              ),
            ),
            GoRoute(
              path: '/student/exams/:id/start',
              pageBuilder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                return MaterialPage(
                  key: state.pageKey,
                  child: ExamStartScreen(quizId: id),
                );
              },
            ),
            GoRoute(
              path: '/student/exams/:id/result',
              pageBuilder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                return MaterialPage(
                  key: state.pageKey,
                  child: ExamResultScreen(quizId: id),
                );
              },
            ),
          ],
        ),
    ],
  );
}
