import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'auth_storage.dart';

class ApiFailure implements Exception {
  ApiFailure(this.message, {this.statusCode, this.errors});

  final String message;
  final int? statusCode;
  final Object? errors;

  @override
  String toString() => message;
}

class ApiService {
  ApiService(this._storage, {VoidCallback? onUnauthorized})
    : _onUnauthorized = onUnauthorized,
      dio = Dio(
        BaseOptions(
          baseUrl: _storage.baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          dio.options.baseUrl = _storage.baseUrl;
          final token = _storage.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final AuthStorage _storage;
  final VoidCallback? _onUnauthorized;
  final Dio dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    return _decode(await dio.get(path, queryParameters: query));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    Object? rawData,
    Options? options,
  }) async {
    return _decode(
      await dio.post(path, data: rawData ?? data, options: options),
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    return _decode(await dio.put(path, data: data));
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    return _decode(await dio.delete(path, data: data));
  }

  Future<Map<String, dynamic>> multipart(
    String path, {
    required FormData formData,
    bool put = false,
  }) async {
    final options = Options(contentType: 'multipart/form-data');
    return _decode(
      put
          ? await dio.put(path, data: formData, options: options)
          : await dio.post(path, data: formData, options: options),
    );
  }

  Map<String, dynamic> _decode(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);
    if (body is List) return {'success': true, 'data': body};
    return {'success': true, 'data': body};
  }

  static ApiFailure failureFrom(Object error) {
    if (error is ApiFailure) return error;
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      if (data is Map) {
        return ApiFailure(
          '${data['message'] ?? data['error'] ?? error.message ?? 'Request failed'}',
          statusCode: status,
          errors: data['errors'],
        );
      }
      return ApiFailure(
        error.message ?? 'Network request failed',
        statusCode: status,
      );
    }
    return ApiFailure(error.toString());
  }
}
