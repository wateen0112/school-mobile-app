class InstallmentPlan {
  const InstallmentPlan({
    required this.id,
    required this.title,
    this.description,
    this.gradeId,
    this.classroomId,
    this.feeId,
    required this.totalAmount,
    required this.academicYear,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.installmentsCount,
    this.studentsCount,
    this.grade,
    this.classroom,
    this.fee,
    this.installments = const [],
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final Map<String, dynamic> title;
  final Map<String, dynamic>? description;
  final int? gradeId;
  final int? classroomId;
  final int? feeId;
  final double totalAmount;
  final String academicYear;
  final String startDate;
  final String endDate;
  final bool isActive;
  final int? installmentsCount;
  final int? studentsCount;
  final Map<String, dynamic>? grade;
  final Map<String, dynamic>? classroom;
  final Map<String, dynamic>? fee;
  final List<PlanInstallment> installments;
  final String? createdAt;
  final String? updatedAt;

  factory InstallmentPlan.fromJson(Map<String, dynamic> json) {
    return InstallmentPlan(
      id: json['id'] as int,
      title: json['title'] is Map
          ? Map<String, dynamic>.from(json['title'] as Map)
          : {'en': '${json['title']}', 'ar': '${json['title']}'},
      description: json['description'] is Map
          ? Map<String, dynamic>.from(json['description'] as Map)
          : null,
      gradeId: json['grade_id'] as int?,
      classroomId: json['classroom_id'] as int?,
      feeId: json['fee_id'] as int?,
      totalAmount: _parseDouble(json['total_amount']),
      academicYear: '${json['academic_year'] ?? ''}',
      startDate: '${json['start_date'] ?? ''}',
      endDate: '${json['end_date'] ?? ''}',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      installmentsCount: json['installments_count'] as int?,
      studentsCount: json['students_count'] as int?,
      grade: json['grade'] is Map
          ? Map<String, dynamic>.from(json['grade'] as Map)
          : null,
      classroom: json['classroom'] is Map
          ? Map<String, dynamic>.from(json['classroom'] as Map)
          : null,
      fee: json['fee'] is Map
          ? Map<String, dynamic>.from(json['fee'] as Map)
          : null,
      installments: _parseInstallments(json['installments']),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static List<PlanInstallment> _parseInstallments(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => PlanInstallment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class PlanInstallment {
  const PlanInstallment({
    required this.id,
    required this.installmentPlanId,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.sortOrder,
    this.description,
  });

  final int id;
  final int installmentPlanId;
  final String title;
  final double amount;
  final String dueDate;
  final int? sortOrder;
  final String? description;

  factory PlanInstallment.fromJson(Map<String, dynamic> json) {
    return PlanInstallment(
      id: json['id'] as int,
      installmentPlanId: json['installment_plan_id'] as int? ?? 0,
      title: '${json['title'] ?? ''}',
      amount: InstallmentPlan._parseDouble(json['amount']),
      dueDate: '${json['due_date'] ?? ''}',
      sortOrder: json['sort_order'] as int?,
      description: json['description'] as String?,
    );
  }
}
