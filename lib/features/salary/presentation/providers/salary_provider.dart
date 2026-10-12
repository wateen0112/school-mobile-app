import 'package:flutter/material.dart';

import '../../data/salary_api_service.dart';
import '../../data/salary_repository_impl.dart';
import '../../domain/models/teacher_salary_model.dart';
import '../../domain/repositories/salary_repository.dart';

enum SalaryListState { initial, loading, loaded, error }

class SalaryProvider extends ChangeNotifier {
  SalaryProvider({required SalaryApiService apiService})
      : _repository = SalaryRepositoryImpl(apiService: apiService);

  final SalaryRepository _repository;

  SalaryListState _state = SalaryListState.initial;
  SalaryListState get state => _state;

  String? _error;
  String? get error => _error;

  TeacherSalaryData? _data;
  TeacherSalaryData? get data => _data;

  bool get isLoading => _state == SalaryListState.loading;

  double get totalPaid =>
      (_data?.history.where((h) => h.isPaid).fold<double>(0, (sum, h) => sum + h.amount) ?? 0);

  int get paidCount => _data?.history.where((h) => h.isPaid).length ?? 0;

  int get pendingCount => _data?.history.where((h) => !h.isPaid).length ?? 0;

  Future<void> load() async {
    _state = SalaryListState.loading;
    _error = null;
    notifyListeners();

    try {
      _data = await _repository.getTeacherSalary();
      _state = SalaryListState.loaded;
    } catch (error) {
      _error = error.toString();
      _state = SalaryListState.error;
    } finally {
      notifyListeners();
    }
  }
}