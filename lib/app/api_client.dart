import 'package:dio/dio.dart';

import '../core/network/logging_interceptor.dart';
import 'app_state.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class SchoolApiClient {
  SchoolApiClient({required this.appState})
      : _dio = Dio(
          BaseOptions(
            baseUrl: appState.baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 30),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(LoggingInterceptor());
  }

  final AppState appState;
  final Dio _dio;

  Options _options() {
    final token = appState.token;
    return Options(
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final body = await _request(
      () => _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      ),
    );
    final token = body['access_token'] ?? body['data']?['access_token'];
    final user = body['user'] ?? body['data']?['user'] ?? const {};
    final type = body['type'] ?? user['type'] ?? body['data']?['type'] ?? 'admin';
    if (token is! String || token.isEmpty) {
      throw ApiException('Login response did not include an access token.');
    }
    await appState.signIn(
      accessToken: token,
      name: '${user['name'] ?? user['Name'] ?? email}',
      type: '$type',
    );
    return body;
  }

  Future<void> logout() async {
    try {
      await _request(() => _dio.post('/logout', options: _options()));
    } finally {
      await appState.signOut();
    }
  }

  Future<Map<String, dynamic>> getDashboard() {
    return _request(() => _dio.get('/dashboard', options: _options()));
  }

  Future<List<dynamic>> list(String endpoint, {Map<String, dynamic>? query}) async {
    final body = await _request(
      () => _dio.get(endpoint, queryParameters: query, options: _options()),
    );
    final data = body['data'];
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'];
    if (body['stats'] is Map) return [body['stats']];
    return const [];
  }

  Future<Map<String, dynamic>> create(String endpoint, Map<String, dynamic> data) {
    return _request(() => _dio.post(endpoint, data: data, options: _options()));
  }

  Future<Map<String, dynamic>> update(String endpoint, int id, Map<String, dynamic> data) {
    return _request(() => _dio.put('$endpoint/$id', data: data, options: _options()));
  }

  Future<Map<String, dynamic>> delete(String endpoint, int id) {
    return _request(() => _dio.delete('$endpoint/$id', options: _options()));
  }

  Future<Map<String, dynamic>> bulkAttendance(Map<String, dynamic> data) {
    return create('/attendance', data);
  }

  Future<Map<String, dynamic>> _request(Future<Response<dynamic>> Function() call) async {
    try {
      _dio.options.baseUrl = appState.baseUrl;
      final response = await call();
      final body = response.data;
      if (body is Map<String, dynamic>) return body;
      if (body is Map) return Map<String, dynamic>.from(body);
      return {'data': body};
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map) {
        throw ApiException(
          '${data['message'] ?? data['error'] ?? error.message ?? 'Request failed'}',
          statusCode: error.response?.statusCode,
        );
      }
      throw ApiException(error.message ?? 'Request failed', statusCode: error.response?.statusCode);
    }
  }
}
