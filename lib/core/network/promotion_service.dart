import 'api_service.dart';

/// Service for Student Promotion API operations.
/// Connects to the existing Laravel backend promotion endpoints.
class PromotionService {
  PromotionService(this._api);

  final ApiService _api;

  /// Get eligible students for promotion from a specific grade/classroom/section.
  Future<List<dynamic>> getEligibleStudents({
    required String gradeId,
    required String classroomId,
    required String sectionId,
  }) async {
    final body = await _api.get(
      '/promotion/students-for-promotion',
      query: {
        'grade_id': gradeId,
        'classroom_id': classroomId,
        'section_id': sectionId,
      },
    );
    return body['data'] as List<dynamic>? ?? [];
  }

  /// Bulk promote selected students.
  /// Maps Flutter form field names to Laravel API field names.
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

  /// Promote ALL students in a grade/classroom/section (existing Laravel endpoint).
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
    return _api.post('/Promotion', data: {
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
    final body = await _api.get('/Promotion');
    return body['data'] as List<dynamic>? ?? [];
  }

  /// Revert a single promotion.
  Future<void> revertPromotion(int promotionId) async {
    await _api.delete('/Promotion/$promotionId');
  }

  /// Revert ALL promotions.
  Future<void> revertAllPromotions() async {
    await _api.delete('/Promotion/1', query: {'page_id': '1'});
  }
}
