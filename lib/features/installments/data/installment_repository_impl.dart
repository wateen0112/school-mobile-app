import '../domain/models/installment_plan_model.dart';
import '../domain/models/my_installment_model.dart';
import '../domain/repositories/installment_repository.dart';
import 'installment_api_service.dart';

class InstallmentRepositoryImpl implements InstallmentRepository {
  InstallmentRepositoryImpl({required InstallmentApiService apiService})
      : _apiService = apiService;

  final InstallmentApiService _apiService;

  @override
  Future<({List<MyInstallment> installments, InstallmentSummary? summary})>
      getMyInstallments({String? status, String? urgency}) {
    return _apiService.getMyInstallments(status: status, urgency: urgency);
  }

  @override
  Future<({List<ParentInstallmentGroup> groups, InstallmentSummary? summary})>
      getMyChildrenInstallments({String? status, String? urgency}) {
    return _apiService.getMyChildrenInstallments(
        status: status, urgency: urgency);
  }

  @override
  Future<List<InstallmentPlan>> getInstallmentPlans() {
    return _apiService.getInstallmentPlans();
  }

  @override
  Future<InstallmentPlan> getInstallmentPlan(int id) {
    return _apiService.getInstallmentPlan(id);
  }
}
