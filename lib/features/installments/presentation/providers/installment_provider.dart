import 'package:flutter/material.dart';

import '../../../../core/models/app_models.dart';
import '../../data/installment_api_service.dart';
import '../../data/installment_repository_impl.dart';
import '../../domain/models/installment_plan_model.dart';
import '../../domain/models/my_installment_model.dart';
import '../../domain/repositories/installment_repository.dart';

enum InstallmentListState { initial, loading, loaded, error }

enum InstallmentFilter { all, pending, paid, overdue, urgent }

class InstallmentProvider extends ChangeNotifier {
  InstallmentProvider({
    required InstallmentApiService apiService,
    required this.role,
  })  : _repository = InstallmentRepositoryImpl(apiService: apiService);

  final InstallmentRepository _repository;
  final UserRole role;

  InstallmentListState _state = InstallmentListState.initial;
  InstallmentListState get state => _state;

  String? _error;
  String? get error => _error;

  List<MyInstallment> _allMyInstallments = [];
  List<MyInstallment> get myInstallments => _filteredMyInstallments;

  List<ParentInstallmentGroup> _allParentGroups = [];
  List<ParentInstallmentGroup> get parentGroups => _filteredParentGroups;

  /// When set (parent role), all lists/summaries are scoped to this student.
  int? _selectedStudentId;
  int? get selectedStudentId => _selectedStudentId;

  void setSelectedStudent(int? studentId) {
    if (_selectedStudentId == studentId) return;
    _selectedStudentId = studentId;
    notifyListeners();
  }

  List<ParentInstallmentGroup> get _visibleGroups => _allParentGroups
      .where(
        (g) => _selectedStudentId == null || g.studentId == _selectedStudentId,
      )
      .toList();

  List<InstallmentPlan> _plans = [];
  List<InstallmentPlan> get plans => _plans;

  InstallmentPlan? _selectedPlan;
  InstallmentPlan? get selectedPlan => _selectedPlan;

  InstallmentFilter _filter = InstallmentFilter.all;
  InstallmentFilter get filter => _filter;

  bool get isLoading => _state == InstallmentListState.loading;

  bool get isParent => role == UserRole.parent;

  /// All installments (unfiltered), across children for parent role.
  List<MyInstallment> get allInstallments {
    if (isParent) {
      return _visibleGroups.expand((g) => g.installments).toList();
    }
    return _allMyInstallments;
  }

  InstallmentSummary get summary {
    final all = isParent
        ? _visibleGroups.expand((g) => g.installments)
        : _allMyInstallments;
    return _calculateSummary(all);
  }

  List<MyInstallment> get _filteredMyInstallments {
    return _allMyInstallments.where(_matchesFilter).toList();
  }

  List<ParentInstallmentGroup> get _filteredParentGroups {
    return _visibleGroups
        .map((group) {
          final filtered = group.installments.where(_matchesFilter).toList();
          if (filtered.isEmpty) return null;
          return ParentInstallmentGroup(
            studentId: group.studentId,
            studentName: group.studentName,
            installments: filtered,
          );
        })
        .whereType<ParentInstallmentGroup>()
        .toList();
  }

  bool _matchesFilter(MyInstallment installment) {
    switch (_filter) {
      case InstallmentFilter.paid:
        return installment.isPaid;
      case InstallmentFilter.pending:
        return installment.status.toLowerCase() == 'pending' ||
            installment.status.toLowerCase() == 'partial';
      case InstallmentFilter.overdue:
        return installment.isOverdue ||
            installment.status.toLowerCase() == 'overdue';
      case InstallmentFilter.urgent:
        return !installment.isPaid &&
            (installment.isOverdue ||
                (installment.daysUntilDue != null &&
                    installment.daysUntilDue! <= 3));
      case InstallmentFilter.all:
        return true;
    }
  }

  InstallmentSummary _calculateSummary(Iterable<MyInstallment> installments) {
    final list = installments.toList();
    return InstallmentSummary(
      totalInstallments: list.length,
      paidCount: list.where((i) => i.isPaid).length,
      pendingCount: list.where((i) => i.status.toLowerCase() == 'pending').length,
      partialCount: list.where((i) => i.status.toLowerCase() == 'partial').length,
      overdueCount: list.where((i) => i.isOverdue || i.status.toLowerCase() == 'overdue').length,
      urgentCount: list.where((i) => !i.isPaid && (i.isOverdue || (i.daysUntilDue ?? 999) <= 3)).length,
    );
  }

  void setFilter(InstallmentFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  Future<void> loadMyInstallments() async {
    _state = InstallmentListState.loading;
    _error = null;
    notifyListeners();

    try {
      if (isParent) {
        final result = await _repository.getMyChildrenInstallments();
        _allParentGroups = result.groups;
        _allMyInstallments =
            _allParentGroups.expand((g) => g.installments).toList();
      } else {
        final result = await _repository.getMyInstallments();
        _allMyInstallments = result.installments;
        _allParentGroups = [];
      }
      _state = InstallmentListState.loaded;
    } catch (error) {
      _error = error.toString();
      _state = InstallmentListState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadInstallmentPlans() async {
    _state = InstallmentListState.loading;
    _error = null;
    notifyListeners();

    try {
      _plans = await _repository.getInstallmentPlans();
      _state = InstallmentListState.loaded;
    } catch (error) {
      _error = error.toString();
      _state = InstallmentListState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadInstallmentPlan(int id) async {
    _state = InstallmentListState.loading;
    _error = null;
    notifyListeners();

    try {
      _selectedPlan = await _repository.getInstallmentPlan(id);
      _state = InstallmentListState.loaded;
    } catch (error) {
      _error = error.toString();
      _state = InstallmentListState.error;
    } finally {
      notifyListeners();
    }
  }

  void clearSelectedPlan() {
    _selectedPlan = null;
    notifyListeners();
  }
}
