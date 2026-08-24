import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Global locale used when formatting backend/connection errors so that
/// messages can be produced in the active language (Arabic) without needing a
/// BuildContext. Updated by the session controller whenever the locale changes.
class ErrorLocale {
  static String languageCode = 'en';

  static bool get isArabic => languageCode == 'ar';
}

bool get isArabicLocale => ErrorLocale.isArabic;

final _arabicRange = RegExp(r'[\u0600-\u06FF]');

bool _hasArabic(String value) => _arabicRange.hasMatch(value);

/// Translates known backend/English messages into Arabic. Unknown text is
/// replaced with a generic Arabic message (the original is logged for
/// debugging) so the UI never shows raw English errors.
String translateServerError(String message) {
  final trimmed = message.trim();
  if (trimmed.isEmpty) return '';
  if (!ErrorLocale.isArabic) return trimmed;
  if (_hasArabic(trimmed)) return trimmed;

  final normalized = trimmed
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[.!]$'), '')
      .trim();

  return _serverMessagesAr[normalized] ??
      _serverMessagesAr[normalized.replaceAll(RegExp(r'^the '), '')] ??
      _serverMessagesAr[normalized.replaceAll(' field', '')] ??
      genericServerError(trimmed);
}

/// Returns a generic Arabic message when the backend sent an unrecognized
/// English message. The original is logged for debugging.
String genericServerError(String original) {
  if (!ErrorLocale.isArabic) return original;
  // ignore: avoid_print
  debugPrint('[API] Untranslated server message: $original');
  return 'حدث خطأ في الخادم. حاول مرة أخرى لاحقاً.';
}

String statusLabel(int? statusCode) {
  if (statusCode == null) return '';
  const labels = <int, String>{
    400: 'طلب غير صالح',
    401: 'غير مصرح - يرجى تسجيل الدخول مرة أخرى',
    403: 'ممنوع الوصول',
    404: 'المورد غير موجود',
    405: 'الطريقة غير مسموحة',
    409: 'تعارض في البيانات',
    419: 'انتهت الجلسة - يرجى تسجيل الدخول مرة أخرى',
    422: 'البيانات المدخلة غير صالحة',
    429: 'عدد كبير من الطلبات - حاول لاحقاً',
    500: 'خطأ في الخادم',
    502: 'البوابة غير صالحة',
    503: 'الخدمة غير متاحة حالياً',
  };
  return labels[statusCode] ?? 'خطأ $statusCode';
}

String connectionErrorMessage(DioExceptionType type, [String? message]) {
  final raw = message;
  if (raw != null && raw.isNotEmpty && !_hasArabic(raw) && ErrorLocale.isArabic) {
    final base = translateServerError(raw);
    if (base != genericServerError(raw)) {
      return base;
    }
  }
  return switch (type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => ErrorLocale.isArabic
        ? 'انتهت مهلة الاتصال. تحقق من اتصال الإنترنت ورابط الخادم.'
        : 'Connection timed out. Please check your internet and server URL.',
    DioExceptionType.connectionError => ErrorLocale.isArabic
        ? 'تعذر الاتصال بالخادم. تحقق من رابط الخادم وتأكد من تشغيله.'
        : 'Cannot connect to server. Please check the server URL and make sure the server is running.',
    DioExceptionType.badCertificate => ErrorLocale.isArabic
        ? 'خطأ في شهادة SSL. تحقق من رابط الخادم.'
        : 'SSL certificate error. Please check the server URL.',
    DioExceptionType.badResponse => ErrorLocale.isArabic
        ? 'استجابة غير صالحة من الخادم.'
        : 'Server returned an invalid response.',
    DioExceptionType.cancel => ErrorLocale.isArabic
        ? 'تم إلغاء الطلب.'
        : 'Request was cancelled.',
    DioExceptionType.unknown => ErrorLocale.isArabic
        ? 'تعذر الاتصال بالخادم. تحقق من اتصال الإنترنت ورابط الخادم.'
        : 'Cannot connect to server. Please check your internet connection and server URL.',
  };
}

/// Flattens a Laravel-style `errors` map into readable Arabic/text lines.
List<String> flattenFieldErrors(Object? errors) {
  if (errors is! Map) return const [];
  final lines = <String>[];
  errors.forEach((field, value) {
    if (value is List && value.isNotEmpty) {
      for (final item in value) {
        lines.add(translateServerError('$item'));
      }
    } else if (value is String && value.isNotEmpty) {
      lines.add(translateServerError(value));
    }
  });
  return lines.toSet().toList();
}

/// Builds a single localized error message from an HTTP error response.
String formatApiError({
  int? statusCode,
  Object? responseData,
  DioExceptionType? type,
  String connectionMessage = '',
}) {
  final isAr = ErrorLocale.isArabic;
  final parts = <String>[];

  var serverMessage = '';
  var serverErrors = const <String>[];

  try {
    final data = responseData;
    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) serverMessage = msg;
      serverErrors = flattenFieldErrors(data['errors']);
    } else if (data is String && data.trim().isNotEmpty) {
      final decoded = _tryDecode(data);
      if (decoded is Map) {
        final msg = decoded['message'];
        if (msg is String && msg.isNotEmpty) serverMessage = msg;
        serverErrors = flattenFieldErrors(decoded['errors']);
      } else if (decoded is List) {
        serverErrors = flattenFieldErrors({'errors': decoded});
      } else {
        serverMessage = data.trim();
      }
    } else if (data != null) {
      serverMessage = '$data';
    }
  } catch (_) {
    // Ignore malformed response bodies.
  }

  if (serverErrors.isNotEmpty) {
    final status = statusLabel(statusCode);
    if (isAr) {
      parts.add(status.isNotEmpty ? status : 'حدث خطأ');
    } else {
      parts.add(serverMessage.isNotEmpty
          ? serverMessage
          : status.isNotEmpty
              ? 'HTTP $statusCode'
              : 'Request failed');
    }
    for (final error in serverErrors.take(3)) {
      parts.add('• $error');
    }
    if (serverErrors.length > 3) {
      parts.add(isAr
          ? '…و ${serverErrors.length - 3} من الأخطاء الأخرى'
          : '…and ${serverErrors.length - 3} more errors');
    }
    return parts.join('\n');
  }

  if (serverMessage.isNotEmpty) {
    final translated = translateServerError(serverMessage);
    if (isAr) {
      final status = statusLabel(statusCode);
      return status.isNotEmpty ? '$status\n$translated' : translated;
    }
    return statusCode != null ? 'HTTP $statusCode\n$translated' : translated;
  }

  final status = statusLabel(statusCode);
  if (status.isNotEmpty) return status;
  if (connectionMessage.isNotEmpty) return connectionMessage;
  return isAr ? 'حدث خطأ غير متوقع.' : 'An unexpected error occurred.';
}

Object? _tryDecode(String body) {
  try {
    return jsonDecode(body);
  } catch (_) {
    return body;
  }
}

const _serverMessagesAr = <String, String>{
  'the given data was invalid': 'البيانات المدخلة غير صالحة.',
  'validation failed': 'فشل التحقق من البيانات.',
  'the given data was invalid.': 'البيانات المدخلة غير صالحة.',
  'unauthenticated': 'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى.',
  'unauthorised': 'غير مصرح لك بتنفيذ هذا الإجراء.',
  'unauthorized': 'غير مصرح لك بتنفيذ هذا الإجراء.',
  'forbidden': 'ممنوع الوصول.',
  'access denied': 'تم رفض الوصول.',
  'permission denied': 'تم رفض الإذن.',
  'not found': 'المورد غير موجود.',
  'resource not found': 'المورد غير موجود.',
  'no query results for model': 'السجل المطلوب غير موجود.',
  'invalid credentials': 'بيانات الدخول غير صحيحة.',
  'these credentials do not match our records': 'بيانات الدخول غير صحيحة.',
  'wrong credentials': 'بيانات الدخول غير صحيحة.',
  'invalid email or password': 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
  'email or password is incorrect': 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
  'invalid email or password.': 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
  'invalid token': 'رمز التحقق غير صالح.',
  'token has expired': 'انتهت صلاحية رمز التحقق.',
  'token expired': 'انتهت صلاحية رمز التحقق.',
  'no token provided': 'لم يتم تقديم رمز التحقق.',
  'unable to authenticate': 'تعذر التحقق من الهوية.',
  'account disabled': 'الحساب معطل.',
  'account is disabled': 'الحساب معطل.',
  'your account is disabled': 'حسابك معطل.',
  'your account is not active': 'حسابك غير نشط.',
  'account not found': 'الحساب غير موجود.',
  'user not found': 'المستخدم غير موجود.',
  'student not found': 'الطالب غير موجود.',
  'teacher not found': 'المعلم غير موجود.',
  'parent not found': 'ولي الأمر غير موجود.',
  'too many requests': 'تم إرسال عدد كبير من الطلبات. حاول لاحقاً.',
  'server error': 'حدث خطأ في الخادم.',
  'internal server error': 'حدث خطأ في الخادم.',
  'method not allowed': 'الطريقة غير مسموحة.',
  'page not found': 'الصفحة غير موجودة.',
  'route not found': 'الصفحة غير موجودة.',
  'the email field is required': 'حقل البريد الإلكتروني مطلوب.',
  'email is required': 'حقل البريد الإلكتروني مطلوب.',
  'the password field is required': 'حقل كلمة المرور مطلوب.',
  'password is required': 'حقل كلمة المرور مطلوب.',
  'the name field is required': 'حقل الاسم مطلوب.',
  'name is required': 'حقل الاسم مطلوب.',
  'the password must be at least 8 characters': 'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل.',
  'the password must be at least 8 characters.': 'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل.',
  'the password confirmation does not match': 'تأكيد كلمة المرور غير متطابق.',
  'password confirmation does not match': 'تأكيد كلمة المرور غير متطابق.',
  'the email has already been taken': 'البريد الإلكتروني مسجل مسبقاً.',
  'email has already been taken': 'البريد الإلكتروني مسجل مسبقاً.',
  'email already exists': 'البريد الإلكتروني موجود مسبقاً.',
  'the phone has already been taken': 'رقم الهاتف مسجل مسبقاً.',
  'phone already exists': 'رقم الهاتف موجود مسبقاً.',
  'the national id has already been taken': 'الرقم الوطني مسجل مسبقاً.',
  'the email must be a valid email address': 'يجب إدخال بريد إلكتروني صالح.',
  'the email must be a valid email address.': 'يجب إدخال بريد إلكتروني صالح.',
  'invalid email address': 'بريد إلكتروني غير صالح.',
  'the selected grade is invalid': 'المرحلة المختارة غير صالحة.',
  'the selected classroom is invalid': 'الفصل المختار غير صالح.',
  'the selected section is invalid': 'القسم المختار غير صالح.',
  'the selected teacher is invalid': 'المعلم المختار غير صالح.',
  'the selected parent is invalid': 'ولي الأمر المختار غير صالح.',
  'the amount must be a positive number': 'يجب أن يكون المبلغ رقماً موجباً.',
  'the amount field is required': 'حقل المبلغ مطلوب.',
  'amount is required': 'حقل المبلغ مطلوب.',
  'the date field is required': 'حقل التاريخ مطلوب.',
  'invalid date': 'التاريخ غير صالح.',
  'invalid input': 'المدخلات غير صالحة.',
  'the title field is required': 'حقل العنوان مطلوب.',
  'the question text field is required': 'حقل نص السؤال مطلوب.',
  'answer is required': 'الإجابة مطلوبة.',
  'the answer field is required': 'حقل الإجابة مطلوب.',
  'this action is unauthorized': 'هذا الإجراء غير مصرح به.',
  'you do not have permission to perform this action': 'ليس لديك صلاحية لتنفيذ هذا الإجراء.',
  'this action is not allowed': 'هذا الإجراء غير مسموح به.',
  'quiz not started': 'لم يبدأ الاختبار بعد.',
  'quiz already submitted': 'تم تسليم الاختبار مسبقاً.',
  'quiz already started': 'تم بدء الاختبار مسبقاً.',
  'quiz is not active': 'الاختبار غير نشط حالياً.',
  'exam not found': 'الاختبار غير موجود.',
  'time expired': 'انتهى الوقت المخصص للاختبار.',
  'exam time expired': 'انتهى وقت الاختبار.',
  'installment not found': 'القسط غير موجود.',
  'installment plan not found': 'خطة الأقساط غير موجودة.',
  'invoice not found': 'الفاتورة غير موجودة.',
  'receipt not found': 'سند القبض غير موجود.',
  'fee not found': 'الرسم غير موجود.',
  'complaint not found': 'الشكوى غير موجودة.',
  'notification not found': 'الإشعار غير موجود.',
  'no installments found': 'لم يتم العثور على أقساط.',
  'no students found': 'لم يتم العثور على طلاب.',
  'no records found': 'لم يتم العثور على سجلات.',
  'no data found': 'لم يتم العثور على بيانات.',
  'the server returned an invalid response': 'استجابة غير صالحة من الخادم.',
  'server returned an invalid response': 'استجابة غير صالحة من الخادم.',
  'invalid response format': 'صيغة الاستجابة غير صالحة.',
  'login succeeded but no access token was returned': 'تم تسجيل الدخول لكن لم يتم إرجاع رمز الوصول.',
  'no access token returned': 'لم يتم إرجاع رمز الوصول.',
  'failed to connect to server': 'تعذر الاتصال بالخادم.',
  'failed to connect': 'تعذر الاتصال.',
  'please check your internet connection and server url': 'تحقق من اتصال الإنترنت ورابط الخادم.',
  'connection timed out': 'انتهت مهلة الاتصال.',
  'request was cancelled': 'تم إلغاء الطلب.',
  'the appointment is already booked': 'الموعد محجوز مسبقاً.',
  'already exists': 'موجود مسبقاً.',
  'duplicate entry': 'سجل مكرر.',
  'cannot delete this record because it is in use': 'لا يمكن حذف هذا السجل لأنه قيد الاستخدام.',
  'cannot delete record': 'لا يمكن حذف السجل.',
  'record cannot be deleted': 'لا يمكن حذف السجل.',
  'this record is linked to other records': 'هذا السجل مرتبط بسجلات أخرى.',
  'operation failed': 'فشلت العملية.',
  'operation is failed': 'فشلت العملية.',
  'something went wrong': 'حدث خطأ ما.',
  'an error occurred': 'حدث خطأ.',
  'unexpected error': 'خطأ غير متوقع.',
  'the file is too large': 'الملف كبير جداً.',
  'unsupported file type': 'نوع الملف غير مدعوم.',
  'file not found': 'الملف غير موجود.',
};