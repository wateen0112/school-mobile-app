import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/session_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/module_localization.dart';
import '../../../../core/widgets/refreshable_content.dart';
import '../../../../widgets/shared_widgets.dart';
import '../../data/installment_api_service.dart';
import '../../domain/models/installment_plan_model.dart';
import '../providers/installment_provider.dart';

class InstallmentPlansScreen extends StatelessWidget {
  const InstallmentPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionController>();
    return ChangeNotifierProvider(
      create: (_) => InstallmentProvider(
        apiService: InstallmentApiService(api: session.api),
        role: session.currentRole,
      ),
      child: const _InstallmentPlansBody(),
    );
  }
}

class _InstallmentPlansBody extends StatefulWidget {
  const _InstallmentPlansBody();

  @override
  State<_InstallmentPlansBody> createState() => _InstallmentPlansBodyState();
}

class _InstallmentPlansBodyState extends State<_InstallmentPlansBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InstallmentProvider>().loadInstallmentPlans();
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
            isArabic ? 'خطط الأقساط' : 'Installment Plans',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: Consumer<InstallmentProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return RefreshablePage(
                onRefresh: provider.loadInstallmentPlans,
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            if (provider.error != null) {
              return RefreshablePage(
                onRefresh: provider.loadInstallmentPlans,
                child: _ErrorState(
                  message: provider.error!,
                  onRetry: provider.loadInstallmentPlans,
                ),
              );
            }
            if (provider.plans.isEmpty) {
              return RefreshablePage(
                onRefresh: provider.loadInstallmentPlans,
                child: NoDataWidget(
                  icon: Icons.account_balance_wallet_outlined,
                  title: isArabic
                      ? 'لا توجد خطط أقساط مسجلة'
                      : 'No installment plans found',
                  message: t(context, 'noDataMessage'),
                  onRefresh: provider.loadInstallmentPlans,
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: provider.loadInstallmentPlans,
              color: AppTheme.primary,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: provider.plans.length,
                itemBuilder: (context, index) {
                  final plan = provider.plans[index];
                  return _PlanCard(
                    plan: plan,
                    onTap: () => context.push('/installment-plan-detail',
                        extra: plan.id),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onTap});

  final InstallmentPlan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = displayValue(plan.title, languageCode: languageCode);
    final grade = displayValue(plan.grade, languageCode: languageCode);
    final classroom = displayValue(plan.classroom, languageCode: languageCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.softPanel(radius: 20),
      child: Material(
        color: Colors.transparent,
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
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
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
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.muted,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _PlanInfoRow(
                  icon: Icons.payments_rounded,
                  label: isArabic ? 'المبلغ الإجمالي' : 'Total amount',
                  value: _formatCurrency(plan.totalAmount),
                ),
                const SizedBox(height: 8),
                _PlanInfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: isArabic ? 'السنة الدراسية' : 'Academic year',
                  value: plan.academicYear,
                ),
                if (grade.isNotEmpty || classroom.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _PlanInfoRow(
                    icon: Icons.school_rounded,
                    label: isArabic ? 'الصف' : 'Grade / Classroom',
                    value: [grade, classroom]
                        .where((s) => s.isNotEmpty)
                        .join(' / '),
                  ),
                ],
                const SizedBox(height: 8),
                _PlanInfoRow(
                  icon: Icons.format_list_numbered_rounded,
                  label: isArabic ? 'عدد الأقساط' : 'Installments',
                  value: '${plan.installmentsCount ?? plan.installments.length}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }
}

class _PlanInfoRow extends StatelessWidget {
  const _PlanInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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
          style: const TextStyle(
            color: AppTheme.ink,
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
