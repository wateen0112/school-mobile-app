import 'dart:convert';

import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../localization/error_messages.dart';
import 'auth_storage.dart';
import 'logging_interceptor.dart';

class ApiFailure implements Exception {
  ApiFailure(this.message, {this.statusCode, this.errors});

  final String message;
  final int? statusCode;
  final Object? errors;

  @override
  String toString() => message;
}

class ApiService {
  ApiService(
    this._storage, {
    VoidCallback? onUnauthorized,
    bool showChucker = false,
  }) : _onUnauthorized = onUnauthorized,
       dio = Dio(
         BaseOptions(
           baseUrl: _storage.baseUrl,
           connectTimeout: const Duration(seconds: 20),
           receiveTimeout: const Duration(seconds: 30),
           sendTimeout: const Duration(seconds: 30),
           responseType: ResponseType.plain,
           headers: const {
             'Accept': 'application/json',
             'Content-Type': 'application/json',
           },
         ),
       ) {
    if (showChucker) {
      dio.interceptors.add(ChuckerDioInterceptor());
    }
    dio.interceptors.add(LoggingInterceptor());
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          dio.options.baseUrl = _storage.baseUrl;
          final lang = ErrorLocale.isArabic ? 'ar' : 'en';
          options.queryParameters['locale'] = lang;
          options.headers['lang'] = lang;
          options.headers['X-Locale'] = lang;
          options.headers['Accept-Language'] = lang;
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
    Options? options,
  }) async {
    return _decode(await dio.get(path, queryParameters: query, options: options));
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
    final raw = response.data;

    if (raw is Map) {
      return raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw);
    }

    if (raw is List) {
      return {'success': true, 'data': raw};
    }

    final body = raw is String ? raw : raw.toString();

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return decoded is Map<String, dynamic>
            ? decoded
            : Map<String, dynamic>.from(decoded);
      }
      if (decoded is List) {
        return {'success': true, 'data': decoded};
      }
      return {'success': true, 'data': decoded};
    } on FormatException catch (e) {
      final preview = body.length > 300 ? '${body.substring(0, 300)}...' : body;
      debugPrint('[ApiService] JSON decode error at ${e.offset}: $preview');
      throw ApiFailure(
        ErrorLocale.isArabic
            ? 'استجابة غير صالحة من الخادم. تأكد من صيغة البيانات المرسلة.'
            : 'Server returned an invalid response. Expected JSON but received: $preview',
      );
    }
  }

  static ApiFailure failureFrom(Object error) {
    if (error is ApiFailure) {
      return ApiFailure(
        translateServerError(error.message),
        statusCode: error.statusCode,
        errors: error.errors,
      );
    }
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      if (data is Map ||
          (data is String && data.trim().isNotEmpty)) {
        return ApiFailure(
          formatApiError(statusCode: status, responseData: data),
          statusCode: status,
          errors: data is Map
              ? data['errors'] ??
                    (data['message'] is String
                        ? data['message']
                        : null)
              : null,
        );
      }
      final message = connectionErrorMessage(error.type, error.message);
      return ApiFailure(message, statusCode: status);
    }
    final raw = error.toString();
    return ApiFailure(translateServerError(raw));
  }
}
