import 'api_service.dart';

/// Service for Student Promotion API operations.
/// Connects to Laravel backend promotion endpoints.
class PromotionService {
  PromotionService(this._api);

  final ApiService _api;

  /// Get eligible students for promotion from a specific classroom.
  Future<List<dynamic>> getEligibleStudents({
    required int fromClassId,
    required String academicYear,
  }) async {
    final body = await _api.get(
      '/promotions/eligible',
      query: {
        'from_class_id': '$fromClassId',
        'academic_year': academicYear,
      },
    );
    return body['data'] as List<dynamic>? ?? [];
  }

  /// Promote a single student.
  Future<Map<String, dynamic>> promoteStudent({
    required int studentId,
    required int fromClassId,
    required int toClassId,
    required int toGradeId,
    required int toSectionId,
    required String academicYear,
    required String decision,
    String? notes,
  }) async {
    return _api.post('/promotions/single', data: {
      'student_id': studentId,
      'from_class_id': fromClassId,
      'to_class_id': toClassId,
      'to_grade_id': toGradeId,
      'to_section_id': toSectionId,
      'academic_year': academicYear,
      'decision': decision,
      if (notes != null) 'notes': notes,
    });
  }

  /// Bulk promote multiple students.
  Future<Map<String, dynamic>> bulkPromote({
    required List<int> studentIds,
    required int fromClassId,
    required int toClassId,
    required int toGradeId,
    required int toSectionId,
    required String academicYear,
    required String decision,
  }) async {
    return _api.post('/promotions/bulk', data: {
      'student_ids': studentIds,
      'from_class_id': fromClassId,
      'to_class_id': toClassId,
      'to_grade_id': toGradeId,
      'to_section_id': toSectionId,
      'academic_year': academicYear,
      'decision': decision,
    });
  }

  /// Get promotion statistics.
  Future<Map<String, dynamic>> getStatistics(String academicYear) async {
    final body = await _api.get('/promotions/statistics', query: {
      'academic_year': academicYear,
    });
    return body['data'] as Map<String, dynamic>? ?? {};
  }

  /// Reverse a promotion.
  Future<void> reversePromotion(int promotionId) async {
    await _api.delete('/promotions/$promotionId/reverse');
  }
}
