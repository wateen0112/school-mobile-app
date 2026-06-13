import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../network/api_service.dart';
import 'module_api_registry.dart';
import 'school_modules.dart';

class SchoolRecord {
  const SchoolRecord({required this.id, required this.raw});

  final int? id;
  final Map<String, dynamic> raw;
}

class SchoolRepository {
  SchoolRepository(this._api);

  final ApiService _api;

  Future<List<SchoolRecord>> list(
    ModuleSpec module, {
    Map<String, dynamic>? query,
  }) async {
    final config = apiConfigFor(module);
    if (config == null || module.specialView == 'dashboard') return const [];

    try {
      final body = await _api.get(
        config.endpoint,
        query: {...config.listQuery, ...?query},
      );
      final data = _extractData(body);
      return _recordsFromData(data, config.idField);
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<List<SchoolRecord>> filteredStudents({
    String? gradeId,
    String? sectionId,
  }) async {
    final module = moduleByKey('students');
    if (module == null) return const [];
    return list(
      module,
      query: {
        if (gradeId != null && gradeId.isNotEmpty) 'Grade_id': gradeId,
        if (sectionId != null && sectionId.isNotEmpty) 'section_id': sectionId,
      },
    );
  }

  Future<Map<String, dynamic>> dashboard() async {
    try {
      final body = await _api.get('/dashboard');
      final normalized = _normalizeDashboardBody(body);
      if (normalized['stats'] is Map) return normalized;

      final statsBody = await _api.get('/dashboard/stats');
      return _normalizeDashboardBody(statsBody);
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Map<String, dynamic> _normalizeDashboardBody(Map<String, dynamic> body) {
    final nested = body['data'];
    final result = Map<String, dynamic>.from(body);
    if (nested is Map) {
      for (final entry in nested.entries) {
        result.putIfAbsent('${entry.key}', () => entry.value);
      }
    }

    final rawStats = result['stats'];
    if (rawStats is Map) {
      result['stats'] = _normalizeDashboardStats(rawStats);
    }
    return result;
  }

  Map<String, dynamic> _normalizeDashboardStats(Map<dynamic, dynamic> raw) {
    final stats = Map<String, dynamic>.from(raw);
    stats['students_count'] ??= stats['total_students'];
    stats['teachers_count'] ??= stats['total_teachers'];
    stats['parents_count'] ??= stats['total_parents'];
    stats['grades_count'] ??= stats['total_grades'];
    stats['classrooms_count'] ??=
        stats['total_classrooms'] ??
        stats['classes_count'] ??
        stats['total_classes'];
    stats['classes_count'] ??= stats['classrooms_count'];
    stats['sections_count'] ??= stats['total_sections'];
    stats['subjects_count'] ??= stats['total_subjects'];
    return stats;
  }

  Future<void> create(ModuleSpec module, Map<String, dynamic> values) async {
    final config = apiConfigFor(module);
    if (config == null) return;
    final payload = _payloadFor(config, values);
    debugPrint(
      '[SchoolRepository] POST ${config.createEndpoint ?? config.endpoint}\npayload: ${jsonEncode(payload)}',
    );
    try {
      await _api.post(config.createEndpoint ?? config.endpoint, data: payload);
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<List<FormOption>> optionsFor(
    String moduleKey, {
    String languageCode = 'en',
  }) async {
    final module = moduleByKey(moduleKey);
    final records = module == null
        ? await _listByConfigKey(moduleKey)
        : await list(module);
    return [
      for (final record in records)
        FormOption(
          value: '${record.id ?? _fallbackOptionValue(record.raw)}',
          label: _optionLabel(record.raw, languageCode: languageCode),
        ),
    ];
  }

  Future<List<FormOption>> sectionsForGrade(
    String gradeId, {
    String languageCode = 'en',
  }) async {
    if (gradeId.isEmpty) return const [];
    try {
      final body = await _api.get('/Students/sections-by-grade/$gradeId');
      return [
        for (final record in _recordsFromData(_extractData(body), 'id'))
          FormOption(
            value: '${record.id ?? _fallbackOptionValue(record.raw)}',
            label: _optionLabel(record.raw, languageCode: languageCode),
          ),
      ];
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<List<FormOption>> classroomsForGrade(
    String gradeId, {
    String languageCode = 'en',
  }) async {
    if (gradeId.isEmpty) return const [];
    try {
      final body = await _api.get('/Students/classrooms-by-grade/$gradeId');
      return [
        for (final record in _recordsFromData(_extractData(body), 'id'))
          FormOption(
            value: '${record.id ?? _fallbackOptionValue(record.raw)}',
            label: _optionLabel(record.raw, languageCode: languageCode),
          ),
      ];
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<List<FormOption>> sectionsForClassroom(
    String classroomId, {
    String languageCode = 'en',
  }) async {
    if (classroomId.isEmpty) return const [];
    try {
      final body = await _api.get(
        '/Students/sections-by-classroom/$classroomId',
      );
      return [
        for (final record in _recordsFromData(_extractData(body), 'id'))
          FormOption(
            value: '${record.id ?? _fallbackOptionValue(record.raw)}',
            label: _optionLabel(record.raw, languageCode: languageCode),
          ),
      ];
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<List<SchoolRecord>> attendanceStudentsForSection(
    String sectionId,
  ) async {
    if (sectionId.isEmpty) return const [];
    try {
      final body = await _api.get('/Attendance/$sectionId');
      return _recordsFromData(_extractData(body), 'id');
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<void> submitAttendance({
    required String gradeId,
    required String classroomId,
    required String sectionId,
    required Map<int, String> attendances,
  }) async {
    try {
      await _api.post(
        '/Attendance',
        data: {
          'grade_id': int.tryParse(gradeId) ?? gradeId,
          'classroom_id': int.tryParse(classroomId) ?? classroomId,
          'section_id': int.tryParse(sectionId) ?? sectionId,
          'attendences': {
            for (final entry in attendances.entries)
              '${entry.key}': entry.value == 'present' ? 'presence' : 'absent',
          },
        },
      );
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<List<SchoolRecord>> attendanceHistory({
    String? gradeId,
    String? classroomId,
    String? sectionId,
    String? date,
  }) async {
    try {
      final body = await _api.get(
        '/Attendance',
        query: {
          if (gradeId != null && gradeId.isNotEmpty) 'grade_id': gradeId,
          if (classroomId != null && classroomId.isNotEmpty)
            'classroom_id': classroomId,
          if (sectionId != null && sectionId.isNotEmpty)
            'section_id': sectionId,
          if (date != null && date.isNotEmpty) 'date': date,
        },
      );
      return _recordsFromData(_extractData(body), 'id');
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<List<SchoolRecord>> _listByConfigKey(String configKey) async {
    final config = apiConfigForKey(configKey);
    if (config == null) return const [];
    try {
      final body = await _api.get(config.endpoint, query: config.listQuery);
      return _recordsFromData(_extractData(body), config.idField);
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<void> update(
    ModuleSpec module,
    SchoolRecord record,
    Map<String, dynamic> values,
  ) async {
    final config = apiConfigFor(module);
    final id = record.id;
    if (config == null || id == null) return;
    final payload = _payloadFor(config, values)..putIfAbsent('id', () => id);
    try {
      await _api.put(
        config.updateEndpoint ?? '${config.endpoint}/$id',
        data: payload,
      );
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<void> delete(ModuleSpec module, SchoolRecord record) async {
    final config = apiConfigFor(module);
    final id = record.id;
    if (config == null || id == null) return;
    try {
      await _api.delete(
        config.deleteEndpoint ?? '${config.endpoint}/$id',
        data: {'id': id},
      );
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  List<String> rowFor(
    ModuleSpec module,
    SchoolRecord record, {
    String languageCode = 'en',
  }) {
    final raw = record.raw;
    return [
      for (final column in module.columns.take(
        module.columns.length.clamp(0, 4),
      ))
        _valueForColumn(column, raw, languageCode: languageCode),
    ];
  }

  List<dynamic> _extractData(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    if (data is Map) {
      return [
        for (final entry in data.entries)
          {'id': entry.key, 'Name': entry.value},
      ];
    }
    if (body['stats'] is Map) return [body['stats']];
    return const [];
  }

  List<SchoolRecord> _recordsFromData(List<dynamic> data, String idField) {
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map((item) => SchoolRecord(id: _extractId(item, idField), raw: item))
        .toList();
  }

  Map<String, dynamic> _payloadFor(
    ModuleApiConfig config,
    Map<String, dynamic> values,
  ) {
    final payload = Map<String, dynamic>.from(config.defaultPayload);
    if (config.endpoint == '/Teachers') {
      payload.remove('Specialization_id');
      payload.remove('Gender_id');
      payload.remove('Email');
      payload.remove('Password');
    }
    for (final entry in values.entries) {
      final target = config.fieldMap[entry.key] ?? entry.key;
      payload[target] = _coerceValue(target, entry.value);
    }

    if (payload.containsKey('Name_en') && !payload.containsKey('Name')) {
      payload['Name'] = payload['Name_en'];
    }
    if (payload.containsKey('Name_en')) {
      payload['Name_ar'] = config.endpoint == '/Teachers'
          ? payload['Name_en']
          : payload['Name_ar'] ?? payload['Name_en'];
    }
    if (payload.containsKey('title_en')) {
      payload['title_ar'] = payload['title_ar'] ?? payload['title_en'];
    }
    if (payload.containsKey('name_en')) {
      payload['name_ar'] = payload['name_en'];
    }
    if (config.endpoint == '/parents' && payload['password'] != null) {
      payload['password_confirmation'] = payload['password'];
    }
    _syncNestedClassroomPayload(payload);
    _syncNestedInvoicePayload(payload);
    return payload;
  }

  void _syncNestedClassroomPayload(Map<String, dynamic> payload) {
    final classes = payload['List_Classes'];
    if (classes is! List || classes.isEmpty || classes.first is! Map) return;

    final first = Map<String, dynamic>.from(classes.first as Map);
    final name = payload['Name'];
    final gradeId = payload['Grade_id'];
    if (name != null) {
      first['Name'] = name;
      first['Name_class_en'] = name;
    }
    if (gradeId != null) {
      first['Grade_id'] = gradeId;
    }
    payload['List_Classes'] = [first];
    payload.remove('Name');
    payload.remove('Grade_id');
  }

  void _syncNestedInvoicePayload(Map<String, dynamic> payload) {
    final fees = payload['List_Fees'];
    if (fees is! List || fees.isEmpty || fees.first is! Map) return;

    final first = Map<String, dynamic>.from(fees.first as Map);
    final studentId = payload['student_id'];
    final feeId = payload['fee_id'];
    final amount = payload['amount'];
    if (studentId != null) first['student_id'] = studentId;
    if (feeId != null) first['fee_id'] = feeId;
    if (amount != null) first['amount'] = amount;
    payload['List_Fees'] = [first];
    payload.remove('student_id');
    payload.remove('fee_id');
    payload.remove('amount');
  }

  dynamic _coerceValue(String key, dynamic value) {
    if (value is List) {
      return value.map((item) => _coerceValue(key, item)).toList();
    }
    if (value is String) {
      final numericKeys = {
        'id',
        'Grade_id',
        'Class_id',
        'Classroom_id',
        'section_id',
        'teacher_id',
        'student_id',
        'parent_id',
        'gender_id',
        'nationalitie_id',
        'blood_id',
        'Specialization_id',
        'Gender_id',
        'amount',
        'Debit',
        'score',
        'Fee_type',
        'fee_id',
        'subject_id',
        'quizze_id',
      };
      if (numericKeys.contains(key)) {
        return int.tryParse(value) ?? 1;
      }
    }
    return value;
  }

  static int? _extractId(Map<String, dynamic> raw, String idField) {
    final value = raw[idField] ?? raw['ID'];
    if (value is int) return value;
    return int.tryParse('$value');
  }

  String _valueForColumn(
    String column,
    Map<String, dynamic> raw, {
    String languageCode = 'en',
  }) {
    final lower = column.toLowerCase();
    final isDateColumn = lower.contains('date');
    final candidates = <String>[
      if (lower.contains('name') ||
          lower.contains('title') ||
          lower.contains('student') ||
          lower.contains('parent')) ...[
        'Name_Father',
        'Name_Section',
        'Name_Class',
        'name',
        'Name',
        'title',
        'email',
      ],
      if (lower.contains('email')) ...['email', 'Email'],
      if (lower == 'from' || lower.contains('from')) ...[
        'f_grade',
        'f_classroom',
        'f_section',
        'from_grade',
        'from_Classroom',
        'from_section',
      ],
      if (lower == 'to' || lower.contains('to')) ...[
        't_grade',
        't_classroom',
        't_section',
        'to_grade',
        'to_Classroom',
        'to_section',
      ],
      if (lower.contains('grade')) ...[
        'Grades',
        'grade',
        'Grade_id',
        'Grade_id_new',
      ],
      if (lower.contains('class')) ...[
        'My_classs',
        'Name',
        'Name_class_en',
        'Name_class_ar',
        'Name_Class',
        'classroom',
        'classroom_name',
        'Classroom_id',
        'classroom_id',
      ],
      if (lower.contains('section')) ...[
        'section',
        'section_id',
      ],
      if (lower.contains('phone')) ...['Phone_Father', 'phone'],
      if (lower.contains('children')) ...['students'],
      if (lower.contains('teacher') || lower.contains('subject')) ...[
        'teacher',
        'subject',
        'specializations',
        'genders',
        'teacher_id',
      ],
      if (lower.contains('amount') || lower.contains('value')) ...[
        'amount',
        'Debit',
        'credit',
      ],
      if (lower.contains('date') || lower.contains('year')) ...[
        'date',
        'invoice_date',
        'attendence_date',
        'academic_year',
        'created_at',
      ],
      if (lower.contains('status')) ...[
        'Status',
        'attendence_status',
        'status',
      ],
      'id',
    ];

    for (final key in candidates) {
      if (!raw.containsKey(key) || raw[key] == null) continue;
      final display = _trimDisplay(
        _display(raw[key], languageCode: languageCode),
      );
      return isDateColumn ? _formatDate(display) : display;
    }
    return raw.isEmpty
        ? '-'
        : _trimDisplay(_display(raw.values.first, languageCode: languageCode));
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }

  String _display(dynamic value, {int depth = 0, String languageCode = 'en'}) {
    if (value == null) return '-';
    final decoded = _decodeTranslatedString(value);
    if (decoded != null) {
      return _display(decoded, depth: depth, languageCode: languageCode);
    }
    if (value is Map) {
      if (depth > 3) return '-';
      final map = Map<String, dynamic>.from(value);
      final direct =
          map[languageCode] ??
          map[languageCode == 'ar' ? 'en' : 'ar'] ??
          map['Name'] ??
          map['Name_Father'] ??
          map['Name_Mother'] ??
          map['Name_Section'] ??
          map['Name_Class'] ??
          map['Name_class_en'] ??
          map['Name_class_ar'] ??
          map['name_en'] ??
          map['name_ar'] ??
          map['name'] ??
          map['title_en'] ??
          map['title_ar'] ??
          map['title'] ??
          map['id'];
      if (direct != null) {
        return _display(direct, depth: depth + 1, languageCode: languageCode);
      }
      return '-';
    }
    if (value is bool) return value ? 'Present' : 'Absent';
    if (value is List) return '${value.length}';
    return '$value';
  }

  String _trimDisplay(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '-';
    return trimmed.length > 60 ? '${trimmed.substring(0, 57)}...' : trimmed;
  }

  Object _fallbackOptionValue(Map<String, dynamic> raw) {
    return raw['id'] ?? raw['ID'] ?? raw.values.firstOrNull ?? '';
  }

  String _optionLabel(Map<String, dynamic> raw, {String languageCode = 'en'}) {
    final candidates = [
      'Name',
      'Name_en',
      'Name_ar',
      'Name_Section',
      'Name_Class',
      'Name_class_en',
      'Name_class_ar',
      'name_en',
      'name_ar',
      'name',
      'title_en',
      'title_ar',
      'title',
      'id',
    ];
    for (final key in candidates) {
      final value = raw[key];
      if (value == null) continue;
      return _trimDisplay(_display(value, languageCode: languageCode));
    }
    return _trimDisplay(
      _display(raw.values.firstOrNull, languageCode: languageCode),
    );
  }

  Map<String, dynamic>? _decodeTranslatedString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
    return null;
  }
}
