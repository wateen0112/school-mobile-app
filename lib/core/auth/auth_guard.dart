import 'package:go_router/go_router.dart';

import '../data/school_modules.dart';
import '../models/app_models.dart';
import '../state/session_controller.dart';

/// Central redirect rules for guest vs signed-in users and role-based routes.
class AuthGuard {
  AuthGuard(this.session);

  final SessionController session;

  static const publicPaths = <String>{
    '/roles',
    '/login',
    '/register',
    '/forgot-password',
    '/verify-email',
  };

  String? redirect(GoRouterState state) {
    if (session.isBootstrapping) return null;

    final path = state.uri.path;
    final isPublic = publicPaths.contains(path);

    if (!session.isAuthenticated) {
      if (isPublic) return null;
      return _guestRedirect(state);
    }

    if (isPublic) return session.homeRoute;

    if (!routeAllowedForRole(path, session.currentRole)) {
      return session.homeRoute;
    }

    return null;
  }

  String _guestRedirect(GoRouterState state) {
    final role = roleFromPath(state.uri.path);
    final params = <String, String>{
      if (role != null) 'role': role.name,
      'from': state.uri.toString(),
    };
    return Uri(path: '/login', queryParameters: params).toString();
  }

  static UserRole? roleFromPath(String path) {
    if (path.startsWith('/admin')) return UserRole.admin;
    if (path.startsWith('/teacher')) return UserRole.teacher;
    if (path.startsWith('/student')) return UserRole.student;
    if (path.startsWith('/parent')) return UserRole.parent;
    return null;
  }

  static bool isPublicPath(String path) => publicPaths.contains(path);

  /// Safe post-login return path (avoids redirect loops).
  static bool isSafeReturnPath(String? location) {
    if (location == null || location.isEmpty) return false;
    final path = Uri.tryParse(location)?.path ?? location;
    if (!path.startsWith('/')) return false;
    if (isPublicPath(path)) return false;
    return roleFromPath(path) != null;
  }
}

bool routeAllowedForRole(String path, UserRole role) {
  return modulesForRole(role).any((module) => module.route == path);
}
