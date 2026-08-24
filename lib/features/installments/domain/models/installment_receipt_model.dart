class InstallmentReceipt {
  const InstallmentReceipt({
    required this.id,
    required this.date,
    required this.debit,
    this.description,
  });

  final int id;
  final String date;
  final double debit;
  final String? description;

  factory InstallmentReceipt.fromJson(Map<String, dynamic> json) {
    return InstallmentReceipt(
      id: json['id'] as int,
      date: '${json['date'] ?? ''}',
      debit: _parseDouble(json['debit']),
      description: json['description'] as String?,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
