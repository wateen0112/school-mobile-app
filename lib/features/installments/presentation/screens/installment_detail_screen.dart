import 'package:flutter/material.dart';

import '../../../../core/localization/module_localization.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/refreshable_content.dart';
import '../../../../widgets/shared_widgets.dart';
import '../../domain/models/installment_receipt_model.dart';
import '../../domain/models/my_installment_model.dart';

class InstallmentDetailScreen extends StatelessWidget {
  const InstallmentDetailScreen({super.key, required this.installment});

  final MyInstallment installment;

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final planTitle = displayValue(installment.planTitle, languageCode: languageCode);
    final statusColor = _statusColor(installment.status);
    final urgencyColor = _urgencyColor(installment);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: AppTheme.softPanel(radius: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        planTitle,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _StatusBadge(
                          status: installment.status,
                          color: statusColor,
                          isArabic: isArabic,
                        ),
                        if (installment.urgency != 'normal' || installment.isOverdue) ...[
                          const SizedBox(height: 6),
                          _UrgencyBadge(
                            installment: installment,
                            color: urgencyColor,
                            isArabic: isArabic,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  installment.installmentTitle,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (installment.isUrgent) ...[
                  const SizedBox(height: 16),
                  _UrgentAlert(isArabic: isArabic),
                ],
                const SizedBox(height: 20),
                _DetailRow(
                  label: isArabic ? 'المبلغ الإجمالي' : 'Total amount',
                  value: _formatCurrency(installment.amount),
                  icon: Icons.payments_rounded,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: isArabic ? 'المبلغ المدفوع' : 'Paid amount',
                  value: _formatCurrency(installment.paidAmount),
                  icon: Icons.check_circle_rounded,
                  valueColor: AppTheme.success,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: isArabic ? 'المبلغ المتبقي' : 'Remaining amount',
                  value: _formatCurrency(installment.remainingAmount),
                  icon: Icons.pending_rounded,
                  valueColor: AppTheme.coral,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: isArabic ? 'تاريخ الاستحقاق' : 'Due date',
                  value: installment.dueDate,
                  icon: Icons.calendar_today_rounded,
                ),
                if (installment.isOverdue ||
                    installment.daysUntilDue != null) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: isArabic ? 'الحالة الزمنية' : 'Time status',
                    value: _timeStatusLabel(isArabic),
                    icon: Icons.access_time_rounded,
                    valueColor: installment.isOverdue
                        ? AppTheme.danger
                        : installment.daysUntilDue! <= 3
                            ? AppTheme.warning
                            : AppTheme.success,
                  ),
                ],
                if (installment.studentName != null &&
                    installment.studentName!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: isArabic ? 'الطالب' : 'Student',
                    value: installment.studentName!,
                    icon: Icons.child_care_rounded,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isArabic ? 'سندات القبض' : 'Receipts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          if (installment.receipts.isEmpty)
            NoDataWidget(
              compact: true,
              icon: Icons.receipt_long_outlined,
              title: isArabic ? 'لا توجد سندات قبض' : 'No receipts yet',
            )
          else
            for (final receipt in installment.receipts) ...[
              _ReceiptCard(receipt: receipt, isArabic: isArabic),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  String _timeStatusLabel(bool isArabic) {
    if (installment.isOverdue) {
      final days = installment.daysUntilDue;
      if (days == null || days == 0) return isArabic ? 'متأخر' : 'Overdue';
      final absDays = days.abs();
      if (absDays == 1) return isArabic ? 'متأخر يوم' : 'Overdue 1 day';
      return isArabic
          ? 'متأخر $absDays أيام'
          : 'Overdue $absDays days';
    }
    final days = installment.daysUntilDue;
    if (days == null) return '';
    if (days == 0) return isArabic ? 'مستحق اليوم' : 'Due today';
    if (days == 1) return isArabic ? 'مستحق غداً' : 'Due in 1 day';
    return isArabic ? 'مستحق خلال $days يوم' : 'Due in $days days';
  }

  Color _statusColor(String status) {
    return switch (status.toLowerCase()) {
      'paid' => AppTheme.success,
      'partial' => AppTheme.warning,
      'overdue' => AppTheme.danger,
      _ => AppTheme.muted,
    };
  }

  Color _urgencyColor(MyInstallment installment) {
    if (installment.isPaid) return AppTheme.success;
    if (installment.isOverdue || installment.urgency == 'urgent') {
      return AppTheme.danger;
    }
    if (installment.urgency == 'upcoming') return AppTheme.warning;
    return AppTheme.primary;
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }
}

class _UrgentAlert extends StatelessWidget {
  const _UrgentAlert({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.danger.withValues(alpha: .25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.priority_high_rounded,
            color: AppTheme.danger,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isArabic
                  ? 'يحتاج إلى دفع عاجل'
                  : 'Requires urgent payment',
              style: TextStyle(
                color: AppTheme.danger,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.color,
    required this.isArabic,
  });

  final String status;
  final Color color;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        _localizedStatus(status, isArabic),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }

  String _localizedStatus(String status, bool isArabic) {
    return switch (status.toLowerCase()) {
      'paid' => isArabic ? 'مدفوع' : 'Paid',
      'partial' => isArabic ? 'جزئي' : 'Partial',
      'overdue' => isArabic ? 'متأخر' : 'Overdue',
      _ => isArabic ? 'معلق' : 'Pending',
    };
  }
}

class _UrgencyBadge extends StatelessWidget {
  const _UrgencyBadge({
    required this.installment,
    required this.color,
    required this.isArabic,
  });

  final MyInstallment installment;
  final Color color;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        _label(isArabic),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _label(bool isArabic) {
    if (installment.isPaid) return isArabic ? 'مسدد' : 'Settled';
    if (installment.isOverdue) return isArabic ? 'متأخر' : 'Overdue';
    return switch (installment.urgency) {
      'urgent' => isArabic ? 'عاجل' : 'Urgent',
      'upcoming' => isArabic ? 'قريب' : 'Upcoming',
      _ => isArabic ? 'عادي' : 'Normal',
    };
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.cloud,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppTheme.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.receipt, required this.isArabic});

  final InstallmentReceipt receipt;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.softPanel(radius: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isArabic ? 'سند قبض' : 'Receipt'} #${receipt.id}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isArabic ? 'التاريخ' : 'Date'}: ${receipt.date}',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 13,
                  ),
                ),
                if (receipt.description != null &&
                    receipt.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    receipt.description!,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            _formatCurrency(receipt.debit),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }
}
