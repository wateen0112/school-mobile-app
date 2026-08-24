import 'installment_receipt_model.dart';

class MyInstallment {
  const MyInstallment({
    required this.id,
    required this.planTitle,
    required this.installmentTitle,
    required this.amount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    required this.dueDate,
    required this.isOverdue,
    this.daysUntilDue,
    this.urgency = 'normal',
    this.studentId,
    this.studentName,
    this.receipts = const [],
  });

  final int id;
  final Map<String, String> planTitle;
  final String installmentTitle;
  final double amount;
  final double paidAmount;
  final double remainingAmount;
  final String status;
  final String dueDate;
  final bool isOverdue;
  final int? daysUntilDue;
  final String urgency;
  final int? studentId;
  final String? studentName;
  final List<InstallmentReceipt> receipts;

  factory MyInstallment.fromJson(Map<String, dynamic> json) {
    return MyInstallment(
      id: json['id'] as int,
      planTitle: json['plan_title'] is Map
          ? Map<String, String>.from(
              (json['plan_title'] as Map).map(
                (key, value) => MapEntry('$key', '$value'),
              ),
            )
          : {'en': '${json['plan_title']}', 'ar': '${json['plan_title']}'},
      installmentTitle: '${json['installment_title'] ?? ''}',
      amount: _parseDouble(json['amount']),
      paidAmount: _parseDouble(json['paid_amount']),
      remainingAmount: _parseDouble(json['remaining_amount']),
      status: '${json['status'] ?? 'pending'}',
      dueDate: '${json['due_date'] ?? ''}',
      isOverdue: json['is_overdue'] == 1 || json['is_overdue'] == true,
      daysUntilDue: json['days_until_due'] as int?,
      urgency: _parseUrgency(json['urgency']),
      studentId: json['student_id'] as int?,
      studentName: json['student_name'] as String?,
      receipts: _parseReceipts(json['receipts']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static List<InstallmentReceipt> _parseReceipts(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => InstallmentReceipt.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static String _parseUrgency(dynamic value) {
    final urgency = '$value'.toLowerCase();
    if (urgency == 'urgent' || urgency == 'upcoming') return urgency;
    return 'normal';
  }

  bool get isPaid => status.toLowerCase() == 'paid';

  bool get isUrgent => urgency == 'urgent' || isOverdue;

  MyInstallment copyWith({
    int? id,
    Map<String, String>? planTitle,
    String? installmentTitle,
    double? amount,
    double? paidAmount,
    double? remainingAmount,
    String? status,
    String? dueDate,
    bool? isOverdue,
    int? daysUntilDue,
    String? urgency,
    int? studentId,
    String? studentName,
    List<InstallmentReceipt>? receipts,
  }) {
    return MyInstallment(
      id: id ?? this.id,
      planTitle: planTitle ?? this.planTitle,
      installmentTitle: installmentTitle ?? this.installmentTitle,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      isOverdue: isOverdue ?? this.isOverdue,
      daysUntilDue: daysUntilDue ?? this.daysUntilDue,
      urgency: urgency ?? this.urgency,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      receipts: receipts ?? this.receipts,
    );
  }
}

class ParentInstallmentGroup {
  const ParentInstallmentGroup({
    required this.studentId,
    required this.studentName,
    required this.installments,
  });

  final int studentId;
  final String studentName;
  final List<MyInstallment> installments;

  factory ParentInstallmentGroup.fromJson(Map<String, dynamic> json) {
    final rawInstallments = json['installments'];
    return ParentInstallmentGroup(
      studentId: json['student_id'] as int? ?? 0,
      studentName: '${json['student_name'] ?? ''}',
      installments: rawInstallments is List
          ? rawInstallments
              .whereType<Map>()
              .map((e) => MyInstallment.fromJson(
                    Map<String, dynamic>.from(e)
                      ..['student_id'] = json['student_id']
                      ..['student_name'] = json['student_name'],
                  ))
              .toList()
          : const [],
    );
  }
}

class InstallmentSummary {
  const InstallmentSummary({
    this.totalInstallments = 0,
    this.paidCount = 0,
    this.pendingCount = 0,
    this.partialCount = 0,
    this.overdueCount = 0,
    this.urgentCount = 0,
  });

  final int totalInstallments;
  final int paidCount;
  final int pendingCount;
  final int partialCount;
  final int overdueCount;
  final int urgentCount;

  factory InstallmentSummary.fromJson(Map<String, dynamic> json) {
    return InstallmentSummary(
      totalInstallments: _parseInt(json['total_installments']),
      paidCount: _parseInt(json['paid_count']),
      pendingCount: _parseInt(json['pending_count']),
      partialCount: _parseInt(json['partial_count']),
      overdueCount: _parseInt(json['overdue_count']),
      urgentCount: _parseInt(json['urgent_count']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
