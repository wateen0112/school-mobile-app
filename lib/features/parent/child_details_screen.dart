import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_service.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/localization/module_localization.dart';
import '../../widgets/shared_widgets.dart';
import '../installments/domain/models/my_installment_model.dart';

class ChildDetailsScreen extends StatefulWidget {
  const ChildDetailsScreen({
    super.key,
    required this.childId,
    required this.childRaw,
  });

  final int childId;
  final Map<String, dynamic> childRaw;

  @override
  State<ChildDetailsScreen> createState() => _ChildDetailsScreenState();
}

class _ChildDetailsScreenState extends State<ChildDetailsScreen> {
  late final ApiService _api;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _report;
  List<MyInstallment> _installments = const [];

  @override
  void initState() {
    super.initState();
    _api = context.read<SessionController>().api;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final evalBody = await _api.get(
        '/evaluations/report/student/${widget.childId}',
      );
      Map<String, dynamic>? installmentsBody;
      try {
        installmentsBody = await _api.get('/my-installments');
      } catch (_) {
        installmentsBody = null;
      }
      if (!mounted) return;
      setState(() {
        _report = evalBody['data'] is Map
            ? Map<String, dynamic>.from(evalBody['data'] as Map)
            : null;
        _installments = _parseInstallments(installmentsBody);
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = ApiService.failureFrom(error).message;
          _loading = false;
        });
      }
    }
  }

  List<MyInstallment> _parseInstallments(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is! Map) return const [];
    final children = data['children'];
    if (children is! List) return const [];
    for (final child in children.whereType<Map>()) {
      final group = ParentInstallmentGroup.fromJson(
        Map<String, dynamic>.from(child),
      );
      if (group.studentId == widget.childId) return group.installments;
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t(context, 'childDetails'))),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const LoadingShimmer();
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.danger),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(t(context, 'retry')),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _buildBasicInfo(context),
        const SizedBox(height: 20),
        _buildRatings(context),
        const SizedBox(height: 20),
        _buildInstallments(context),
      ],
    );
  }

  Widget _buildBasicInfo(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final raw = widget.childRaw;
    final name = displayValue(raw['name'] ?? raw['Name'], languageCode: languageCode);
    final email = raw['email']?.toString() ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF1E3C72),
                  child: Text(
                    name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            _InfoRow(
              icon: Icons.school_rounded,
              label: t(context, 'grade'),
              value: displayValue(raw['grade'], languageCode: languageCode),
            ),
            _InfoRow(
              icon: Icons.meeting_room_rounded,
              label: t(context, 'classroom'),
              value: displayValue(raw['classroom'], languageCode: languageCode),
            ),
            _InfoRow(
              icon: Icons.groups_rounded,
              label: t(context, 'section'),
              value: displayValue(raw['section'], languageCode: languageCode),
            ),
            _InfoRow(
              icon: Icons.cake_rounded,
              label: t(context, 'birthDate'),
              value: _first(raw, ['Date_Birth', 'Birth_Date', 'birth_date']),
            ),
            _InfoRow(
              icon: Icons.calendar_month_rounded,
              label: t(context, 'academicYear'),
              value: _first(raw, ['academic_year', 'academicYear', 'Year']),
            ),
            _InfoRow(
              icon: Icons.person_rounded,
              label: t(context, 'parent'),
              value: displayValue(raw['myparent'], languageCode: languageCode),
            ),
          ],
        ),
      ),
    );
  }

  String _first(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  Widget _buildRatings(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final data = _report;
    final evaluations = data?['evaluations'] is List
        ? (data!['evaluations'] as List)
        : const <dynamic>[];
    final statistics = data?['statistics'] is Map
        ? Map<String, dynamic>.from(data!['statistics'] as Map)
        : <String, dynamic>{};
    final total = _statInt(statistics, 'total');
    final averageLevel = _statInt(statistics, 'average_level');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${t(context, 'ratings')} (${evaluations.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (total > 0)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _StatCell(
                    value: '$total',
                    label: t(context, 'total'),
                  ),
                  Container(
                    width: 1,
                    height: 34,
                    color: AppTheme.borderColor,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _averageLabel(context, averageLevel),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t(context, 'average'),
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _emptyCard(t(context, 'noRatings')),
        const SizedBox(height: 8),
        if (evaluations.isNotEmpty)
          ...evaluations.map<Widget>(
            (e) => _evaluationCard(context, e, languageCode),
          ),
      ],
    );
  }

  Widget _evaluationCard(
    BuildContext context,
    dynamic e,
    String languageCode,
  ) {
    final map = e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{};
    final level = map['evaluation_level']?.toString() ?? '';
    final subject = displayValue(
      map['subject'],
      languageCode: languageCode,
    );
    final teacher = displayValue(
      map['teacher'],
      languageCode: languageCode,
    );
    final notes = map['notes']?.toString() ?? '';
    final month = map['month'] is int ? map['month'] as int : 0;
    final year = map['year']?.toString() ?? '';
    final dateText = [
      if (month > 0) _monthName(context, month),
      if (year.isNotEmpty) year,
    ].join(' ');
    final levelColor = _levelColor(level);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    subject.isEmpty ? t(context, 'unknown') : subject,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _levelLabel(context, level),
                    style: TextStyle(
                      color: levelColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  teacher.isEmpty ? t(context, 'unknown') : teacher,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                if (dateText.isNotEmpty)
                  Text(
                    dateText,
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  notes,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstallments(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${t(context, 'installments')} (${_installments.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (_installments.isEmpty)
          _emptyCard(t(context, 'noInstallments'))
        else
          ..._installments.map<Widget>((i) => _installmentCard(context, i)),
      ],
    );
  }

  Widget _installmentCard(BuildContext context, MyInstallment i) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final planTitle = displayValue(i.planTitle, languageCode: languageCode);
    final statusColor = _installmentColor(i.status);
    final statusLabel = _installmentLabel(context, i.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    planTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (i.installmentTitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                i.installmentTitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
            const SizedBox(height: 10),
            _amountRow(context, t(context, 'amount'), _formatMoney(i.amount),
                AppTheme.ink),
            _amountRow(context, t(context, 'paidAmount'),
                _formatMoney(i.paidAmount), AppTheme.success),
            _amountRow(context, t(context, 'remainingAmount'),
                _formatMoney(i.remainingAmount), AppTheme.danger),
            if (i.dueDate.isNotEmpty) ...[
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.event_rounded,
                      size: 16, color: AppTheme.muted),
                  const SizedBox(width: 6),
                  Text(
                    '${t(context, 'dueDate')}: ${i.dueDate}',
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _amountRow(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.payments_rounded, size: 15, color: Colors.grey[400]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(message, style: TextStyle(color: Colors.grey[500])),
        ),
      ),
    );
  }

  int _statInt(Map<String, dynamic> statistics, String key) {
    final value = statistics[key];
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _averageLabel(BuildContext context, int averageLevel) {
    if (averageLevel <= 0) return t(context, 'unknown');
    final level = switch (averageLevel) {
      1 => 'bad',
      2 => 'good',
      3 => 'very_good',
      4 => 'excellent',
      _ => 'good',
    };
    return _levelLabel(context, level);
  }

  String _levelLabel(BuildContext context, String level) {
    if (!appIsArabic(context)) {
      return level
          .replaceAll('_', ' ')
          .split(' ')
          .where((w) => w.isNotEmpty)
          .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
    }
    return switch (level) {
      'bad' => 'ضعيف',
      'good' => 'جيد',
      'very_good' => 'جيد جداً',
      'excellent' => 'ممتاز',
      _ => level,
    };
  }

  Color _levelColor(String level) {
    return switch (level) {
      'bad' => AppTheme.danger,
      'good' => AppTheme.warning,
      'very_good' => AppTheme.primaryLight,
      'excellent' => AppTheme.success,
      _ => AppTheme.muted,
    };
  }

  String _monthName(BuildContext context, int month) {
    final names = appIsArabic(context)
        ? [
            'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
            'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
          ]
        : [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December',
          ];
    if (month < 1 || month > 12) return '';
    return names[month - 1];
  }

  String _installmentLabel(BuildContext context, String status) {
    return switch (status.toLowerCase()) {
      'paid' => t(context, 'paid'),
      'partial' => t(context, 'partial'),
      'overdue' => t(context, 'overdue'),
      _ => t(context, 'pending'),
    };
  }

  Color _installmentColor(String status) {
    return switch (status.toLowerCase()) {
      'paid' => AppTheme.success,
      'partial' => AppTheme.warning,
      'overdue' => AppTheme.danger,
      _ => AppTheme.muted,
    };
  }

  String _formatMoney(num value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}