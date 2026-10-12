import '../domain/models/teacher_salary_model.dart';
import '../domain/repositories/salary_repository.dart';
import 'salary_api_service.dart';

class SalaryRepositoryImpl implements SalaryRepository {
  SalaryRepositoryImpl({required SalaryApiService apiService})
      : _apiService = apiService;

  final SalaryApiService _apiService;

  @override
  Future<TeacherSalaryData> getTeacherSalary() {
    return _apiService.getTeacherSalary();
  }
}