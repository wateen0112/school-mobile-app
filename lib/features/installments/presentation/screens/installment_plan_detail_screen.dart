import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/session_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/module_localization.dart';
import '../../../../core/widgets/refreshable_content.dart';
import '../../../../widgets/shared_widgets.dart';
import '../../data/installment_api_service.dart';
import '../../domain/models/installment_plan_model.dart';
import '../providers/installment_provider.dart';

class InstallmentPlanDetailScreen extends StatelessWidget {
  const InstallmentPlanDetailScreen({super.key, required this.planId});

  final int planId;

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionController>();
    return ChangeNotifierProvider(
      create: (_) => InstallmentProvider(
        apiService: InstallmentApiService(api: session.api),
        role: session.currentRole,
      ),
      child: _InstallmentPlanDetailBody(planId: planId),
    );
  }
}

class _InstallmentPlanDetailBody extends StatefulWidget {
  const _InstallmentPlanDetailBody({required this.planId});

  final int planId;

  @override
  State<_InstallmentPlanDetailBody> createState() =>
      _InstallmentPlanDetailBodyState();
}

class _InstallmentPlanDetailBodyState
    extends State<_InstallmentPlanDetailBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InstallmentProvider>().loadInstallmentPlan(widget.planId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 72,
          title: Text(
            isArabic ? 'تفاصيل خطة الأقساط' : 'Installment Plan Detail',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: Consumer<InstallmentProvider>(
          builder: (context, provider, _) {
            Future<void> reload() =>
                provider.loadInstallmentPlan(widget.planId);
            if (provider.isLoading) {
              return RefreshablePage(
                onRefresh: reload,
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            if (provider.error != null) {
              return RefreshablePage(
                onRefresh: reload,
                child: _ErrorState(
                  message: provider.error!,
                  onRetry: reload,
                ),
              );
            }
            final plan = provider.selectedPlan;
            if (plan == null) {
              return RefreshablePage(
                onRefresh: reload,
                child: NoDataWidget(
                  icon: Icons.account_balance_wallet_outlined,
                  title: isArabic
                      ? 'لم يتم العثور على خطة الأقساط'
                      : 'Installment plan not found',
                  message: t(context, 'noDataMessage'),
                  onRefresh: reload,
                ),
              );
            }
            return _PlanDetailContent(
              plan: plan,
              onRefresh: reload,
            );
          },
        ),
      ),
    );
  }
}

class _PlanDetailContent extends StatelessWidget {
  const _PlanDetailContent({required this.plan, required this.onRefresh});

  final InstallmentPlan plan;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = displayValue(plan.title, languageCode: languageCode);
    final grade = displayValue(plan.grade, languageCode: languageCode);
    final classroom = displayValue(plan.classroom, languageCode: languageCode);
    final fee = displayValue(plan.fee, languageCode: languageCode);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (!plan.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.muted.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Text(
                          isArabic ? 'غير نشط' : 'Inactive',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppTheme.muted,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                  ],
                ),
                if (plan.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    displayValue(plan.description, languageCode: languageCode),
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _DetailRow(
                  label: isArabic ? 'المبلغ الإجمالي' : 'Total amount',
                  value: _formatCurrency(plan.totalAmount),
                  icon: Icons.payments_rounded,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: isArabic ? 'السنة الدراسية' : 'Academic year',
                  value: plan.academicYear,
                  icon: Icons.calendar_today_rounded,
                ),
                if (grade.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: isArabic ? 'المرحلة' : 'Grade',
                    value: grade,
                    icon: Icons.school_rounded,
                  ),
                ],
                if (classroom.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: isArabic ? 'الفصل' : 'Classroom',
                    value: classroom,
                    icon: Icons.meeting_room_rounded,
                  ),
                ],
                if (fee.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: isArabic ? 'الرسوم' : 'Fee',
                    value: fee,
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                ],
                const SizedBox(height: 12),
                _DetailRow(
                  label: isArabic ? 'تاريخ البداية' : 'Start date',
                  value: plan.startDate,
                  icon: Icons.date_range_rounded,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: isArabic ? 'تاريخ النهاية' : 'End date',
                  value: plan.endDate,
                  icon: Icons.date_range_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isArabic ? 'الأقساط' : 'Installments',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          if (plan.installments.isEmpty)
            NoDataWidget(
              compact: true,
              icon: Icons.receipt_long_outlined,
              title: isArabic ? 'لا توجد أقساط' : 'No installments',
              onRefresh: onRefresh,
            )
          else
            for (final installment in plan.installments) ...[
              _InstallmentItemCard(
                installment: installment,
                isArabic: isArabic,
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }
}

class _InstallmentItemCard extends StatelessWidget {
  const _InstallmentItemCard({
    required this.installment,
    required this.isArabic,
  });

  final PlanInstallment installment;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.softPanel(radius: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '${installment.sortOrder ?? ''}',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  installment.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isArabic ? 'تاريخ الاستحقاق' : 'Due date'}: ${installment.dueDate}',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 13,
                  ),
                ),
                if (installment.description != null &&
                    installment.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    installment.description!,
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
            _formatCurrency(installment.amount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

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
                style: const TextStyle(
                  color: AppTheme.ink,
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
