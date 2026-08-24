import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  void _log(String buffer, String name) {
    // Use stdout.writeln for guaranteed terminal output
    stdout.writeln(buffer);
    // Also log to debug console
    developer.log(buffer, name: name);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final buffer = StringBuffer();
    buffer.writeln('┌─────────────────────────────────────────────────────────────');
    buffer.writeln('│ ➡️  REQUEST');
    buffer.writeln('├─────────────────────────────────────────────────────────────');
    buffer.writeln('│ ${options.method.toUpperCase()} ${options.uri}');
    buffer.writeln('├─────────────────────────────────────────────────────────────');
    buffer.writeln('│ Headers:');
    options.headers.forEach((key, value) {
      buffer.writeln('│   $key: $value');
    });
    if (options.queryParameters.isNotEmpty) {
      buffer.writeln('├─────────────────────────────────────────────────────────────');
      buffer.writeln('│ Query Parameters:');
      options.queryParameters.forEach((key, value) {
        buffer.writeln('│   $key: $value');
      });
    }
    if (options.data != null) {
      buffer.writeln('├─────────────────────────────────────────────────────────────');
      buffer.writeln('│ Body:');
      buffer.writeln('│   ${options.data}');
    }
    buffer.writeln('└─────────────────────────────────────────────────────────────');
    _log(buffer.toString(), 'API_REQUEST');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final buffer = StringBuffer();
    buffer.writeln('┌─────────────────────────────────────────────────────────────');
    buffer.writeln('│ ⬅️  RESPONSE');
    buffer.writeln('├─────────────────────────────────────────────────────────────');
    buffer.writeln('│ ${response.statusCode} ${response.statusMessage}');
    buffer.writeln('│ ${response.requestOptions.method.toUpperCase()} ${response.requestOptions.uri}');
    buffer.writeln('├─────────────────────────────────────────────────────────────');
    buffer.writeln('│ Headers:');
    response.headers.map.forEach((key, value) {
      buffer.writeln('│   $key: ${value.join(", ")}');
    });
    buffer.writeln('├─────────────────────────────────────────────────────────────');
    buffer.writeln('│ Body:');
    buffer.writeln('│   ${response.data}');
    buffer.writeln('└─────────────────────────────────────────────────────────────');
    _log(buffer.toString(), 'API_RESPONSE');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final buffer = StringBuffer();
    buffer.writeln('┌─────────────────────────────────────────────────────────────');
    buffer.writeln('│ ❌ ERROR');
    buffer.writeln('├─────────────────────────────────────────────────────────────');
    buffer.writeln('│ ${err.requestOptions.method.toUpperCase()} ${err.requestOptions.uri}');
    buffer.writeln('├─────────────────────────────────────────────────────────────');
    buffer.writeln('│ Type: ${err.type}');
    if (err.response != null) {
      buffer.writeln('│ Status Code: ${err.response?.statusCode}');
      buffer.writeln('│ Status Message: ${err.response?.statusMessage}');
      buffer.writeln('├─────────────────────────────────────────────────────────────');
      buffer.writeln('│ Response Body:');
      final errorData = err.response?.data;
      if (errorData is Map || errorData is List) {
        const encoder = JsonEncoder.withIndent('  ');
        for (final line in encoder.convert(errorData).split('\n')) {
          buffer.writeln('│   $line');
        }
      } else {
        buffer.writeln('│   $errorData');
      }
    } else {
      buffer.writeln('│ Message: ${err.message}');
    }
    buffer.writeln('└─────────────────────────────────────────────────────────────');
    _log(buffer.toString(), 'API_ERROR');
    handler.next(err);
  }
}
