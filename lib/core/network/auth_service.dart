import '../models/app_models.dart';
import 'api_service.dart';
import 'auth_storage.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
    required this.role,
  });

  final String token;
  final Map<String, dynamic> user;
  final UserRole role;
}

class AuthService {
  AuthService({required ApiService api, required AuthStorage storage})
    : _api = api,
      _storage = storage;

  final ApiService _api;
  final AuthStorage _storage;

  Future<AuthSession> login({
    required String email,
    required String password,
    required UserRole requestedRole,
  }) async {
    try {
      final body = await _api.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final token =
          body['access_token'] ??
          body['token'] ??
          body['data']?['access_token'];
      final userValue =
          body['user'] ?? body['data']?['user'] ?? <String, dynamic>{};
      final user = userValue is Map<String, dynamic>
          ? userValue
          : Map<String, dynamic>.from(userValue as Map);
      final role = _parseRole(
        '${body['type'] ?? body['guard'] ?? requestedRole.name}',
      );

      if (token is! String || token.isEmpty) {
        throw ApiFailure('Login succeeded but no access token was returned.');
      }

      await _storage.saveSession(token: token, user: user, role: role);
      return AuthSession(token: token, user: user, role: role);
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<Map<String, dynamic>> me() async {
    try {
      final body = await _api.post('/me');
      final user = body['user'] ?? body['data']?['user'] ?? body;
      return user is Map<String, dynamic>
          ? user
          : Map<String, dynamic>.from(user as Map);
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/logout');
    } catch (_) {
      // Local session must still be cleared when the token is expired/revoked.
    } finally {
      await _storage.clearSession();
    }
  }

  UserRole _parseRole(String value) {
    final normalized = value.toLowerCase().replaceAll('web', 'admin');
    return UserRole.values.firstWhere(
      (role) => role.name == normalized,
      orElse: () => UserRole.admin,
    );
  }
}
