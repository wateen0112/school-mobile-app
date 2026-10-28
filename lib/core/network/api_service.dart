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
           connectTimeout: const Duration(seconds: 60),
           receiveTimeout: const Duration(seconds: 120),
           sendTimeout: const Duration(seconds: 60),
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
    try {
      final response = await dio.get(path, queryParameters: query, options: options);
      return _decode(response);
    } catch (e) {
      if (e is ApiFailure) rethrow;
      // Try to handle Dio errors that might contain response data
      if (e is DioException) {
        if (e.response != null) {
          try {
            return _decode(e.response!);
          } catch (_) {}
        }
        // If it's a connection/receive timeout with partial data
        if (e.response?.data != null) {
          try {
            return _decode(e.response!);
          } catch (_) {}
        }
      }
      rethrow;
    }
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
    // If raw is already parsed as Map/List by Dio (though we set plain, be defensive)
    if (raw is Map && raw is! String) {
      // Check if it's actually a Map
    }

    if (raw is Map) {
      return raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw);
    }

    if (raw is List) {
      return {'success': true, 'data': raw};
    }

    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return {'success': true, 'data': null};
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
      if (raw != null && raw is! String) {
        return {'success': true, 'data': raw};
      }

      // Try to find JSON start anywhere in the body
      try {
        final jsonStart = body.indexOf('{');
        final jsonArrayStart = body.indexOf('[');
        String candidate = body;
        if (jsonStart != -1 && (jsonArrayStart == -1 || jsonStart < jsonArrayStart)) {
          candidate = body.substring(jsonStart);
        } else if (jsonArrayStart != -1) {
          candidate = body.substring(jsonArrayStart);
        }
        // Try the extracted candidate
        try {
          final decoded = jsonDecode(candidate);
          if (decoded is Map) {
            return decoded is Map<String, dynamic>
                ? decoded
                : Map<String, dynamic>.from(decoded);
          }
          if (decoded is List) {
            return {'success': true, 'data': decoded};
          }
        } catch (_) {
          // Try to close it aggressively
          int lastBrace = candidate.lastIndexOf('}');
          int lastBracket = candidate.lastIndexOf(']');
          int cutIndex = lastBrace > lastBracket ? lastBrace : lastBracket;
          if (cutIndex != -1) {
            final trimmed = candidate.substring(0, cutIndex + 1);
            try {
              final decoded = jsonDecode(trimmed);
              if (decoded is Map) {
                return decoded is Map<String, dynamic>
                    ? decoded
                    : Map<String, dynamic>.from(decoded);
              }
              if (decoded is List) {
                return {'success': true, 'data': decoded};
              }
            } catch (_) {}
            // Try to close brackets/braces
            try {
              String toClose = trimmed;
              int openBraces = '{'.allMatches(toClose).length - '}'.allMatches(toClose).length;
              int openBrackets = '['.allMatches(toClose).length - ']'.allMatches(toClose).length;
              for (int i = 0; i < openBrackets && openBrackets < 10000; i++) toClose += ']';
              for (int i = 0; i < openBraces && openBraces < 10000; i++) toClose += '}';
              final decoded = jsonDecode(toClose);
              if (decoded is Map) {
                return decoded is Map<String, dynamic>
                    ? decoded
                    : Map<String, dynamic>.from(decoded);
              }
              if (decoded is List) {
                return {'success': true, 'data': decoded};
              }
            } catch (_) {}
          }
        }
      } catch (_) {}
      // Try to extract all objects from the body
      try {
        final objRegex = RegExp(r'\{[^{}]*(\{[^{}]*\}[^{}]*)*\}', dotAll: true);
        final matches = objRegex.allMatches(body);
        if (matches.isNotEmpty) {
          final objects = <String>[];
          for (final m in matches) {
            objects.add(m.group(0)!);
          }
          if (objects.isNotEmpty) {
            final reconstructed = '{"success":true,"data":[' + objects.join(',') + ']}';
            final decoded = jsonDecode(reconstructed);
            if (decoded is Map) {
              return decoded is Map<String, dynamic>
                  ? decoded
                  : Map<String, dynamic>.from(decoded);
            }
          }
        }
      } catch (_) {}

      // Fallback: try parsing using dart_json or lenient parsing if possible, or attempt recovering truncated json
      try {
        // If it was truncated, try to close open brackets/braces or find last valid JSON object/array
        int lastBrace = body.lastIndexOf('}');
        int lastBracket = body.lastIndexOf(']');
        int cutIndex = lastBrace > lastBracket ? lastBrace : lastBracket;
        if (cutIndex != -1 && cutIndex < body.length - 1) {
          final trimmed = body.substring(0, cutIndex + 1);
          final decoded = jsonDecode(trimmed);
          if (decoded is Map) {
            return decoded is Map<String, dynamic>
                ? decoded
                : Map<String, dynamic>.from(decoded);
          }
          if (decoded is List) {
            return {'success': true, 'data': decoded};
          }
        }
      } catch (_) {}

      // Try to recover truncated array of objects (common case)
      try {
        // Try from the full JSON object start
        final objStart = body.indexOf('{');
        String searchBody = body;
        if (objStart != -1 && objStart > 0) {
          searchBody = body.substring(objStart);
        }
        final dataStart = searchBody.indexOf('"data"');
        if (dataStart != -1) {
          final arrayStart = searchBody.indexOf('[', dataStart);
          if (arrayStart != -1) {
            int depth = 0;
            int lastCompleteObjectEnd = -1;
            bool inString = false;
            String stringChar = '"';
            for (int i = arrayStart; i < searchBody.length; i++) {
              final c = searchBody[i];
              if (inString) {
                if (c == '\\') {
                  if (i + 1 < searchBody.length) i++;
                  continue;
                }
                if (c == stringChar) {
                  inString = false;
                }
                continue;
              } else {
                if (c == '"' || c == "'") {
                  inString = true;
                  stringChar = c;
                  continue;
                }
                if (c == '{') {
                  depth++;
                } else if (c == '}') {
                  depth--;
                  if (depth == 0 && i >= arrayStart) {
                    lastCompleteObjectEnd = i;
                  }
                } else if (c == ']') {
                  if (depth == 0) break;
                }
              }
            }
            if (lastCompleteObjectEnd != -1 && lastCompleteObjectEnd >= arrayStart) {
              final prefix = searchBody.substring(0, dataStart);
              final startOfElements = arrayStart + 1;
              final middle = searchBody.substring(startOfElements, lastCompleteObjectEnd + 1);
              String cleanedMiddle = middle.replaceAll(RegExp(r',\s*$'), '');
              // Use regex to extract complete objects
              final objRegex = RegExp(r'\{[^{}]*(\{[^{}]*\}[^{}]*)*\}', dotAll: true);
              final matches = objRegex.allMatches(cleanedMiddle);
              if (matches.isNotEmpty) {
                final objects = <String>[];
                for (final m in matches) {
                  objects.add(m.group(0)!);
                }
                final aggressive = '{"success":true,"data":[' + objects.join(',') + ']}';
                try {
                  final decoded = jsonDecode(aggressive);
                  if (decoded is Map) {
                    return decoded is Map<String, dynamic>
                        ? decoded
                        : Map<String, dynamic>.from(decoded);
                  }
                } catch (_) {}
              }
              final attempts = [
                '$prefix"data":[$cleanedMiddle]}',
                '{"success":true,"message":"recovered","data":[$cleanedMiddle]}',
                '{"data":[$cleanedMiddle]}',
              ];
              for (final reconstructed in attempts) {
                try {
                  final decoded = jsonDecode(reconstructed);
                  if (decoded is Map) {
                    return decoded is Map<String, dynamic>
                        ? decoded
                        : Map<String, dynamic>.from(decoded);
                  }
                } catch (_) {}
              }
            } else {
              // No complete objects, try to extract all objects with regex
              final objRegex = RegExp(r'\{[^{}]*(\{[^{}]*\}[^{}]*)*\}', dotAll: true);
              final matches = objRegex.allMatches(searchBody);
              if (matches.isNotEmpty) {
                final objects = <String>[];
                for (final m in matches) {
                  objects.add(m.group(0)!);
                }
                final aggressive = '{"success":true,"data":[' + objects.join(',') + ']}';
                try {
                  final decoded = jsonDecode(aggressive);
                  if (decoded is Map) {
                    return decoded is Map<String, dynamic>
                        ? decoded
                        : Map<String, dynamic>.from(decoded);
                  }
                } catch (_) {}
              }
              final lastBrace = searchBody.lastIndexOf('}');
              if (lastBrace > arrayStart) {
                final prefix = searchBody.substring(0, dataStart);
                String middle = searchBody.substring(arrayStart + 1, lastBrace + 1);
                String cleanedMiddle = middle.replaceAll(RegExp(r',\s*$'), '');
                final attempts = [
                  '$prefix"data":[$cleanedMiddle]}',
                  '{"success":true,"data":[$cleanedMiddle]}',
                ];
                for (final reconstructed in attempts) {
                  try {
                    final decoded = jsonDecode(reconstructed);
                    if (decoded is Map) {
                      return decoded is Map<String, dynamic>
                          ? decoded
                          : Map<String, dynamic>.from(decoded);
                    }
                  } catch (_) {}
                }
              } else {
                // No objects found, just empty array
                try {
                  final reconstructed = '{"success":true,"data":[]}';
                  return Map<String, dynamic>.from(jsonDecode(reconstructed) as Map);
                } catch (_) {}
              }
            }
          }
        }
      } catch (_) {}

      try {
        final sanitized = body.replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), ' ');
        final decoded = jsonDecode(sanitized);
        if (decoded is Map) {
          return decoded is Map<String, dynamic>
              ? decoded
              : Map<String, dynamic>.from(decoded);
        }
        if (decoded is List) {
          return {'success': true, 'data': decoded};
        }
      } catch (_) {}

      // Last resort: try to salvage as much as possible by extracting all objects
      try {
        final objRegex = RegExp(r'\{[^{}]*(\{[^{}]*\}[^{}]*)*\}', dotAll: true);
        final matches = objRegex.allMatches(body);
        if (matches.isNotEmpty) {
          final objects = <String>[];
          for (final m in matches) {
            objects.add(m.group(0)!);
          }
          if (objects.isNotEmpty) {
            final reconstructed = '{"success":true,"data":[' + objects.join(',') + ']}';
            try {
              final decoded = jsonDecode(reconstructed);
              if (decoded is Map) {
                return decoded is Map<String, dynamic>
                    ? decoded
                    : Map<String, dynamic>.from(decoded);
              }
            } catch (_) {}
          }
        }
      } catch (_) {}

      final preview = body.length > 300 ? '${body.substring(0, 300)}...' : body;
      debugPrint('[ApiService] JSON decode error at ${e.offset}: $preview');
      // Try one more time with very aggressive extraction
      try {
        // Extract everything between [ and last complete object
        final dataStart = body.indexOf('"data"');
        if (dataStart != -1) {
          final arrStart = body.indexOf('[', dataStart);
          if (arrStart != -1) {
            // Find all complete JSON objects
            final objects = <String>[];
            int i = arrStart + 1;
            while (i < body.length) {
              // skip whitespace
              while (i < body.length && RegExp(r'\s').hasMatch(body[i])) i++;
              if (i < body.length && body[i] == '{') {
                int depth = 0;
                int start = i;
                bool inStr = false;
                String strChar = '"';
                while (i < body.length) {
                  final c = body[i];
                  if (inStr) {
                    if (c == '\\' && i + 1 < body.length) {
                      i += 2;
                      continue;
                    }
                    if (c == strChar) {
                      inStr = false;
                    }
                    i++;
                    continue;
                  } else {
                    if (c == '"' || c == "'") {
                      inStr = true;
                      strChar = c;
                      i++;
                      continue;
                    }
                    if (c == '{') {
                      depth++;
                      i++;
                      continue;
                    }
                    if (c == '}') {
                      depth--;
                      i++;
                      if (depth == 0) {
                        objects.add(body.substring(start, i));
                        break;
                      }
                      continue;
                    }
                    if (c == '[' || c == ']') {
                      i++;
                      continue;
                    }
                    i++;
                    continue;
                  }
                }
                if (depth != 0) break; // truncated
                // skip comma
                while (i < body.length && RegExp(r'\s').hasMatch(body[i])) i++;
                if (i < body.length && body[i] == ',') {
                  i++;
                  continue;
                }
                if (i < body.length && body[i] == ']') break;
                continue;
              } else if (body[i] == ']') {
                break;
              } else {
                i++;
              }
            }
            if (objects.isNotEmpty) {
              final reconstructed = '{"success":true,"data":[' + objects.join(',') + ']}';
              try {
                final decoded = jsonDecode(reconstructed);
                if (decoded is Map) {
                  return decoded is Map<String, dynamic>
                      ? decoded
                      : Map<String, dynamic>.from(decoded);
                }
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
      // Last fallback: try to extract all objects with regex
      try {
        final objRegex = RegExp(r'\{[^{}]*(\{[^{}]*\}[^{}]*)*\}', dotAll: true);
        final matches = objRegex.allMatches(body);
        if (matches.isNotEmpty) {
          final objects = <String>[];
          for (final m in matches) {
            objects.add(m.group(0)!);
          }
          if (objects.isNotEmpty) {
            final reconstructed = '{"success":true,"data":[' + objects.join(',') + ']}';
            final decoded = jsonDecode(reconstructed);
            if (decoded is Map) {
              return decoded is Map<String, dynamic>
                  ? decoded
                  : Map<String, dynamic>.from(decoded);
            }
          }
        }
      } catch (_) {}

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
