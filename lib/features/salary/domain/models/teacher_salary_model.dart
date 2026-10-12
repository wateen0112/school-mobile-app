double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _asInt(dynamic value, int fallback) {
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
  }
  return fallback;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value == 'true' || value == '1';
  return false;
}

class TeacherSalaryNextDue {
  const TeacherSalaryNextDue({
    required this.amount,
    required this.dueDate,
    required this.periodYear,
    required this.periodMonth,
    required this.isOverdue,
  });

  final double amount;
  final String dueDate;
  final int periodYear;
  final int periodMonth;
  final bool isOverdue;

  factory TeacherSalaryNextDue.fromJson(Map<String, dynamic> json) =>
      TeacherSalaryNextDue(
        amount: _asDouble(json['amount']),
        dueDate: json['due_date']?.toString() ?? '',
        periodYear: _asInt(json['period_year'], DateTime.now().year),
        periodMonth: _asInt(json['period_month'], 1),
        isOverdue: _asBool(json['is_overdue']),
      );
}

class SalaryHistoryItem {
  const SalaryHistoryItem({
    required this.id,
    required this.periodYear,
    required this.periodMonth,
    required this.amount,
    required this.dueDate,
    this.paidAt,
    required this.status,
    this.paymentMethod,
    this.notes,
    required this.isOverdue,
  });

  final int id;
  final int periodYear;
  final int periodMonth;
  final double amount;
  final String dueDate;
  final String? paidAt;
  final String status;
  final String? paymentMethod;
  final String? notes;
  final bool isOverdue;

  bool get isPaid => status == 'paid';

  factory SalaryHistoryItem.fromJson(Map<String, dynamic> json) =>
      SalaryHistoryItem(
        id: _asInt(json['id'], 0),
        periodYear: _asInt(json['period_year'], DateTime.now().year),
        periodMonth: _asInt(json['period_month'], 1),
        amount: _asDouble(json['amount']),
        dueDate: json['due_date']?.toString() ?? '',
        paidAt: json['paid_at']?.toString(),
        status: json['status']?.toString() ?? 'pending',
        paymentMethod: json['payment_method']?.toString(),
        notes: json['notes']?.toString(),
        isOverdue: _asBool(json['is_overdue']),
      );
}

class TeacherSalaryData {
  const TeacherSalaryData({
    this.baseSalary,
    this.nextDue,
    required this.history,
  });

  final double? baseSalary;
  final TeacherSalaryNextDue? nextDue;
  final List<SalaryHistoryItem> history;

  factory TeacherSalaryData.fromJson(Map<String, dynamic> json) {
    final rawNext = json['next_due'];
    final rawHistory = json['history'];
    final base = json['base_salary'];
    return TeacherSalaryData(
      baseSalary: base is num
          ? base.toDouble()
          : base is String
              ? double.tryParse(base)
              : null,
      nextDue: rawNext is Map<String, dynamic>
          ? TeacherSalaryNextDue.fromJson(rawNext)
          : null,
      history: rawHistory is List
          ? rawHistory
              .whereType<Map>()
              .map((e) =>
                  SalaryHistoryItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const <SalaryHistoryItem>[],
    );
  }
}