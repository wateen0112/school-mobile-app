import '../../../core/network/api_service.dart';
import '../domain/models/teacher_salary_model.dart';

class SalaryApiService {
  SalaryApiService({required ApiService api}) : _api = api;

  final ApiService _api;

  Future<TeacherSalaryData> getTeacherSalary() async {
    try {
      final body = await _api.get('/teacher/salaries');
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return TeacherSalaryData.fromJson(data);
      }
      throw ApiFailure('Invalid response format');
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }
}