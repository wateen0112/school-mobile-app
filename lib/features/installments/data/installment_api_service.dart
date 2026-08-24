import '../../../core/network/api_service.dart';
import '../domain/models/installment_plan_model.dart';
import '../domain/models/my_installment_model.dart';

class InstallmentApiService {
  InstallmentApiService({required ApiService api}) : _api = api;

  final ApiService _api;

  Future<({List<MyInstallment> installments, InstallmentSummary? summary})>
      getMyInstallments({String? status, String? urgency}) async {
    try {
      final query = <String, dynamic>{};
      if (status != null && status.isNotEmpty) query['status'] = status;
      if (urgency != null && urgency.isNotEmpty) query['urgency'] = urgency;

      final body = await _api.get('/my-installments', query: query);
      final data = body['data'];

      if (data is Map<String, dynamic>) {
        final summary = data['summary'] is Map<String, dynamic>
            ? InstallmentSummary.fromJson(data['summary'] as Map<String, dynamic>)
            : null;
        final rawInstallments = data['installments'];
        if (rawInstallments is List) {
          return (
            installments: rawInstallments
                .whereType<Map>()
                .map((e) =>
                    MyInstallment.fromJson(Map<String, dynamic>.from(e)))
                .toList(),
            summary: summary,
          );
        }
        return (installments: const <MyInstallment>[], summary: summary);
      }

      if (data is List) {
        return (
          installments: data
              .whereType<Map>()
              .map((e) => MyInstallment.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
          summary: null,
        );
      }

      return (installments: const <MyInstallment>[], summary: null);
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<
      ({
        List<ParentInstallmentGroup> groups,
        InstallmentSummary? summary
      })> getMyChildrenInstallments({String? status, String? urgency}) async {
    try {
      final query = <String, dynamic>{};
      if (status != null && status.isNotEmpty) query['status'] = status;
      if (urgency != null && urgency.isNotEmpty) query['urgency'] = urgency;

      final body = await _api.get('/my-installments', query: query);
      final data = body['data'];

      if (data is Map<String, dynamic>) {
        final summary = data['summary'] is Map<String, dynamic>
            ? InstallmentSummary.fromJson(data['summary'] as Map<String, dynamic>)
            : null;
        final rawChildren = data['children'];
        if (rawChildren is List) {
          return (
            groups: rawChildren
                .whereType<Map>()
                .map((e) =>
                    ParentInstallmentGroup.fromJson(Map<String, dynamic>.from(e)))
                .toList(),
            summary: summary,
          );
        }
        return (groups: const <ParentInstallmentGroup>[], summary: summary);
      }

      if (data is List) {
        return (
          groups: data
              .whereType<Map>()
              .map((e) =>
                  ParentInstallmentGroup.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
          summary: null,
        );
      }

      return (groups: const <ParentInstallmentGroup>[], summary: null);
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<List<InstallmentPlan>> getInstallmentPlans() async {
    try {
      final body = await _api.get('/installment-plans');
      final data = body['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => InstallmentPlan.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<InstallmentPlan> getInstallmentPlan(int id) async {
    try {
      final body = await _api.get('/installment-plans/$id');
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return InstallmentPlan.fromJson(data);
      }
      throw ApiFailure('Invalid response format');
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }
}
