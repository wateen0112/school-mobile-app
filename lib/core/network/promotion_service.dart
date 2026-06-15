import 'dart:math';
import 'api_service.dart';

/// Service for Student Promotion API operations.
/// Supports both real API calls and web mock mode.
class PromotionService {
  PromotionService(this._api);

  final ApiService _api;

  // Mock data for web demo
  final List<Map<String, dynamic>> _mockStudents = [
    {"id": 1, "name": "Ahmed Hassan", "email": "ahmed@student.com", "grade_id": 1, "classroom_id": 1, "section_id": 1, "academic_year": "2024-2025", "status": "active", "average_score": 85},
    {"id": 2, "name": "Sara Mohammed", "email": "sara@student.com", "grade_id": 1, "classroom_id": 1, "section_id": 1, "academic_year": "2024-2025", "status": "active", "average_score": 92},
    {"id": 3, "name": "Omar Ali", "email": "omar@student.com", "grade_id": 1, "classroom_id": 1, "section_id": 1, "academic_year": "2024-2025", "status": "active", "average_score": 78},
    {"id": 4, "name": "Lina Khaled", "email": "lina@student.com", "grade_id": 1, "classroom_id": 1, "section_id": 1, "academic_year": "2024-2025", "status": "active", "average_score": 88},
    {"id": 5, "name": "Youssef Amr", "email": "youssef@student.com", "grade_id": 1, "classroom_id": 1, "section_id": 1, "academic_year": "2024-2025", "status": "active", "average_score": 65},
    {"id": 6, "name": "Nour Ibrahim", "email": "nour@student.com", "grade_id": 1, "classroom_id": 1, "section_id": 1, "academic_year": "2024-2025", "status": "active", "average_score": 95},
    {"id": 7, "name": "Kareem Samir", "email": "kareem@student.com", "grade_id": 1, "classroom_id": 1, "section_id": 1, "academic_year": "2024-2025", "status": "active", "average_score": 72},
    {"id": 8, "name": "Mariam Tarek", "email": "mariam@student.com", "grade_id": 1, "classroom_id": 1, "section_id": 1, "academic_year": "2024-2025", "status": "active", "average_score": 81},
  ];

  final List<Map<String, dynamic>> _mockPromotions = [];

  bool get _isWeb => identical(0, 0.0);

  /// Get eligible students for promotion.
  Future<List<dynamic>> getEligibleStudents({
    int? fromClassId,
    String? academicYear,
  }) async {
    if (_isWeb) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockStudents;
    }
    final body = await _api.get(
      '/promotion/students-for-promotion',
      query: {
        if (fromClassId != null) 'classroom_id': '$fromClassId',
        if (academicYear != null) 'academic_year': academicYear,
      },
    );
    return body['data'] as List<dynamic>? ?? [];
  }

  /// Bulk promote selected students.
  Future<Map<String, dynamic>> bulkPromote({
    required List<String> studentIds,
    required String fromGradeId,
    required String fromClassroomId,
    required String fromSectionId,
    required String toGradeId,
    required String toClassroomId,
    required String toSectionId,
    required String academicYear,
    required String academicYearNew,
  }) async {
    if (_isWeb) {
      await Future.delayed(const Duration(milliseconds: 800));
      final promoted = <Map<String, dynamic>>[];
      for (final sid in studentIds) {
        final student = _mockStudents.firstWhere(
          (s) => s['id'].toString() == sid,
          orElse: () => <String, dynamic>{},
        );
        if (student.isNotEmpty) {
          student['grade_id'] = int.tryParse(toGradeId) ?? student['grade_id'];
          student['classroom_id'] = int.tryParse(toClassroomId) ?? student['classroom_id'];
          student['section_id'] = int.tryParse(toSectionId) ?? student['section_id'];
          student['academic_year'] = academicYearNew;
          _mockPromotions.add({
            'id': _mockPromotions.length + 1,
            'student_id': int.parse(sid),
            'student_name': student['name'],
            'from_grade': fromGradeId,
            'to_grade': toGradeId,
            'decision': 'promoted',
            'created_at': DateTime.now().toIso8601String(),
          });
          promoted.add(student);
        }
      }
      return {
        'success': true,
        'message': '${promoted.length} promoted, 0 failed.',
        'data': {'promoted': promoted.length, 'failed': 0},
      };
    }
    return _api.post('/promotion/bulk', data: {
      'student_ids': studentIds.map(int.parse).toList(),
      'Grade_id': int.parse(fromGradeId),
      'Classroom_id': int.parse(fromClassroomId),
      'section_id': int.parse(fromSectionId),
      'Grade_id_new': int.parse(toGradeId),
      'Classroom_id_new': int.parse(toClassroomId),
      'section_id_new': int.parse(toSectionId),
      'academic_year': academicYear,
      'academic_year_new': academicYearNew,
    });
  }

  /// Promote ALL students (existing Laravel endpoint).
  Future<Map<String, dynamic>> promoteAll({
    required String fromGradeId,
    required String fromClassroomId,
    required String fromSectionId,
    required String toGradeId,
    required String toClassroomId,
    required String toSectionId,
    required String academicYear,
    required String academicYearNew,
  }) async {
    if (_isWeb) {
      return bulkPromote(
        studentIds: _mockStudents.map((s) => s['id'].toString()).toList(),
        fromGradeId: fromGradeId,
        fromClassroomId: fromClassroomId,
        fromSectionId: fromSectionId,
        toGradeId: toGradeId,
        toClassroomId: toClassroomId,
        toSectionId: toSectionId,
        academicYear: academicYear,
        academicYearNew: academicYearNew,
      );
    }
    return _api.post('/promotion', data: {
      'Grade_id': int.parse(fromGradeId),
      'Classroom_id': int.parse(fromClassroomId),
      'section_id': int.parse(fromSectionId),
      'Grade_id_new': int.parse(toGradeId),
      'Classroom_id_new': int.parse(toClassroomId),
      'section_id_new': int.parse(toSectionId),
      'academic_year': academicYear,
      'academic_year_new': academicYearNew,
    });
  }

  /// List all promotions.
  Future<List<dynamic>> listPromotions() async {
    if (_isWeb) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockPromotions;
    }
    final body = await _api.get('/promotion');
    return body['data'] as List<dynamic>? ?? [];
  }

  /// Revert a single promotion.
  Future<void> revertPromotion(int promotionId) async {
    if (_isWeb) {
      _mockPromotions.removeWhere((p) => p['id'] == promotionId);
      return;
    }
    await _api.delete('/promotion/$promotionId');
  }

  /// Revert ALL promotions.
  Future<void> revertAllPromotions() async {
    if (_isWeb) {
      _mockPromotions.clear();
      return;
    }
    await _api.delete('/promotion/1', data: {'page_id': '1'});
  }
}
