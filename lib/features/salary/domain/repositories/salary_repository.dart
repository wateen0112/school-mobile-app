import '../models/teacher_salary_model.dart';

abstract class SalaryRepository {
  Future<TeacherSalaryData> getTeacherSalary();
}