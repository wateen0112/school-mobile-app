import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/session_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/module_localization.dart';
import '../../../../core/widgets/refreshable_content.dart';
import '../../../../widgets/shared_widgets.dart';
import '../../data/installment_api_service.dart';
import '../../domain/models/my_installment_model.dart';
import '../providers/installment_provider.dart';

class MyInstallmentsScreen extends StatelessWidget {
  const MyInstallmentsScreen({super.key, this.studentInstallmentId});

  final int? studentInstallmentId;

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionController>();
    return ChangeNotifierProvider(
      create: (_) => InstallmentProvider(
        apiService: InstallmentApiService(api: session.api),
        role: session.currentRole,
      ),
      child: _MyInstallmentsBody(
        studentInstallmentId: studentInstallmentId,
      ),
    );
  }
}

class _MyInstallmentsBody extends StatefulWidget {
  const _MyInstallmentsBody({this.studentInstallmentId});

  final int? studentInstallmentId;

  @override
  State<_MyInstallmentsBody> createState() => _MyInstallmentsBodyState();
}

class _MyInstallmentsBodyState extends State<_MyInstallmentsBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<InstallmentProvider>();
      provider.loadMyInstallments().then((_) {
        if (widget.studentInstallmentId != null) {
          _maybeOpenDetail(widget.studentInstallmentId!);
        }
      });
    });
  }

  void _maybeOpenDetail(int id) {
    final provider = context.read<InstallmentProvider>();
    MyInstallment? installment;
    if (provider.isParent) {
      for (final group in provider.parentGroups) {
        installment = group.installments.where((i) => i.id == id).firstOrNull;
        if (installment != null) break;
      }
    } else {
      installment = provider.myInstallments.where((i) => i.id == id).firstOrNull;
    }
    if (installment != null && mounted) {
      context.push('/installment-detail', extra: installment);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    return Consumer<InstallmentProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return RefreshablePage(
            onRefresh: provider.loadMyInstallments,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (provider.error != null) {
          return RefreshablePage(
            onRefresh: provider.loadMyInstallments,
            child: _ErrorState(
              message: provider.error!,
              onRetry: provider.loadMyInstallments,
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: provider.loadMyInstallments,
          color: AppTheme.primary,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).padding.bottom + 100,
            ),
            itemCount: _itemCount(provider),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _HeaderCard(isParent: provider.isParent);
              }
              if (index == 1) {
                return _SummaryCard(summary: provider.summary);
              }
              if (index == 2) {
                return _FilterChips(
                  selected: provider.filter,
                  onSelected: provider.setFilter,
                );
              }
              if (provider.isParent) {
                final groupIndex = index - 3;
                if (provider.parentGroups.isEmpty) {
                  return NoDataWidget(
                    compact: true,
                    icon: Icons.account_balance_wallet_outlined,
                    title: isArabic
                        ? 'لا توجد أقساط مسجلة لأبنائك'
                        : 'No installments found for your children',
                    onRefresh: provider.loadMyInstallments,
                  );
                }
                final group = provider.parentGroups[groupIndex];
                return _StudentInstallmentGroup(
                  group: group,
                  onTap: (installment) => _openDetail(context, installment),
                );
              }
              if (provider.myInstallments.isEmpty) {
                return NoDataWidget(
                  compact: true,
                  icon: Icons.account_balance_wallet_outlined,
                  title: isArabic
                      ? 'لا توجد أقساط مسجلة'
                      : 'No installments found',
                  onRefresh: provider.loadMyInstallments,
                );
              }
              final installment = provider.myInstallments[index - 3];
              return _InstallmentCard(
                installment: installment,
                onTap: () => _openDetail(context, installment),
              );
            },
          ),
        );
      },
    );
  }

  int _itemCount(InstallmentProvider provider) {
    if (provider.isParent) {
      return provider.parentGroups.isEmpty
          ? 4
          : provider.parentGroups.length + 3;
    }
    return provider.myInstallments.isEmpty
        ? 4
        : provider.myInstallments.length + 3;
  }

  void _openDetail(BuildContext context, MyInstallment installment) {
    context.push('/installment-detail', extra: installment);
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.isParent});

  final bool isParent;

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    final title = isParent
        ? (isArabic ? 'أقساط الأبناء' : 'Children Installments')
        : (isArabic ? 'أقساطي' : 'My Installments');
    final subtitle = isParent
        ? (isArabic
            ? 'متابعة أقساط الرسوم لجميع الأبناء المرتبطين'
            : 'Track tuition installments for all linked children')
        : (isArabic
            ? 'عرض الأقساط المستحقة والمدفوعة'
            : 'View due and paid installments');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: AppTheme.promoGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: .18),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final InstallmentSummary summary;

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.softPanel(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'ملخص الأقساط' : 'Installment Summary',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(
                label: isArabic ? 'الكل' : 'Total',
                value: summary.totalInstallments,
                color: AppTheme.primary,
                icon: Icons.wallet_rounded,
              ),
              _SummaryChip(
                label: isArabic ? 'مدفوع' : 'Paid',
                value: summary.paidCount,
                color: AppTheme.success,
                icon: Icons.check_circle_rounded,
              ),
              _SummaryChip(
                label: isArabic ? 'مستحق' : 'Pending',
                value: summary.pendingCount + summary.partialCount,
                color: AppTheme.warning,
                icon: Icons.pending_rounded,
              ),
              _SummaryChip(
                label: isArabic ? 'متأخر' : 'Overdue',
                value: summary.overdueCount,
                color: AppTheme.danger,
                icon: Icons.warning_rounded,
              ),
              _SummaryChip(
                label: isArabic ? 'عاجل' : 'Urgent',
                value: summary.urgentCount,
                color: AppTheme.coral,
                icon: Icons.priority_high_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.onSelected,
  });

  final InstallmentFilter selected;
  final ValueChanged<InstallmentFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: isArabic ? 'الكل' : 'All',
              filter: InstallmentFilter.all,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: isArabic ? 'مستحق' : 'Pending',
              filter: InstallmentFilter.pending,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: isArabic ? 'مدفوع' : 'Paid',
              filter: InstallmentFilter.paid,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: isArabic ? 'متأخر' : 'Overdue',
              filter: InstallmentFilter.overdue,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: isArabic ? 'عاجل' : 'Urgent',
              filter: InstallmentFilter.urgent,
              selected: selected,
              onSelected: onSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.filter,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final InstallmentFilter filter;
  final InstallmentFilter selected;
  final ValueChanged<InstallmentFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(filter),
      selectedColor: AppTheme.primary.withValues(alpha: .16),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primary : AppTheme.ink,
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primary : const Color(0xffe3e8fb),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}

class _StudentInstallmentGroup extends StatelessWidget {
  const _StudentInstallmentGroup({
    required this.group,
    required this.onTap,
  });

  final ParentInstallmentGroup group;
  final ValueChanged<MyInstallment> onTap;

  @override
  Widget build(BuildContext context) {
    if (group.installments.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
          child: Row(
            children: [
              const Icon(Icons.child_care_rounded, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                group.studentName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
        for (final installment in group.installments) ...[
          _InstallmentCard(
            installment: installment,
            onTap: () => onTap(installment),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _InstallmentCard extends StatelessWidget {
  const _InstallmentCard({
    required this.installment,
    required this.onTap,
  });

  final MyInstallment installment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final planTitle = displayValue(installment.planTitle, languageCode: languageCode);
    final isArabic = appIsArabic(context);
    final accentColor = _accentColor(installment);
    final statusColor = _statusColor(installment.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.softPanel(radius: 20).copyWith(
        border: Border.all(
          color: accentColor.withValues(alpha: .35),
          width: 1.5,
        ),
      ),
      child: Material(
        color: accentColor.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        planTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    _StatusBadge(
                      status: installment.status,
                      color: statusColor,
                      isArabic: isArabic,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  installment.installmentTitle,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                _AmountRow(
                  label: isArabic ? 'المبلغ' : 'Amount',
                  value: _formatCurrency(installment.amount),
                  icon: Icons.payments_rounded,
                ),
                const SizedBox(height: 8),
                _AmountRow(
                  label: isArabic ? 'المدفوع' : 'Paid',
                  value: _formatCurrency(installment.paidAmount),
                  icon: Icons.check_circle_rounded,
                  valueColor: AppTheme.success,
                ),
                const SizedBox(height: 8),
                _AmountRow(
                  label: isArabic ? 'المتبقي' : 'Remaining',
                  value: _formatCurrency(installment.remainingAmount),
                  icon: Icons.pending_rounded,
                  valueColor: AppTheme.coral,
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: accentColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${isArabic ? 'تاريخ الاستحقاق' : 'Due date'}: ${installment.dueDate}',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _DueChip(
                      installment: installment,
                      color: accentColor,
                      isArabic: isArabic,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _accentColor(MyInstallment installment) {
    if (installment.isPaid) return AppTheme.success;
    if (installment.isOverdue || installment.urgency == 'urgent') {
      return AppTheme.danger;
    }
    if (installment.urgency == 'upcoming') return AppTheme.warning;
    return AppTheme.primary;
  }

  Color _statusColor(String status) {
    return switch (status.toLowerCase()) {
      'paid' => AppTheme.success,
      'partial' => AppTheme.warning,
      'overdue' => AppTheme.danger,
      _ => AppTheme.muted,
    };
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }
}

class _DueChip extends StatelessWidget {
  const _DueChip({
    required this.installment,
    required this.color,
    required this.isArabic,
  });

  final MyInstallment installment;
  final Color color;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final label = _dueLabel(isArabic);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _dueLabel(bool isArabic) {
    if (installment.isPaid) return isArabic ? 'مدفوع' : 'Paid';
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
    if (days == null) return isArabic ? 'مستحق' : 'Due';
    if (days == 0) return isArabic ? 'مستحق اليوم' : 'Due today';
    if (days == 1) return isArabic ? 'مستحق غداً' : 'Due in 1 day';
    return isArabic
        ? 'مستحق خلال $days يوم'
        : 'Due in $days days';
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

class _AmountRow extends StatelessWidget {
  const _AmountRow({
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
        Icon(icon, size: 18, color: AppTheme.muted),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: const TextStyle(
            color: AppTheme.muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppTheme.ink,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppTheme.coral,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
          ),
        ],
      ),
    );
  }
}
