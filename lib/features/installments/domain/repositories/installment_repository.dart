import '../models/installment_plan_model.dart';
import '../models/my_installment_model.dart';

abstract class InstallmentRepository {
  Future<({List<MyInstallment> installments, InstallmentSummary? summary})>
      getMyInstallments({String? status, String? urgency});

  Future<({List<ParentInstallmentGroup> groups, InstallmentSummary? summary})>
      getMyChildrenInstallments({String? status, String? urgency});

  Future<List<InstallmentPlan>> getInstallmentPlans();

  Future<InstallmentPlan> getInstallmentPlan(int id);
}
