import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/module_localization.dart';
import '../../../../core/state/session_controller.dart';
import '../../../../core/widgets/refreshable_content.dart';
import '../../data/salary_api_service.dart';
import '../../domain/models/teacher_salary_model.dart';
import '../providers/salary_provider.dart';

class _Palette {
  static const heroGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF004D40), Color(0xFF00695C)],
  );

  static const violet = Color(0xff6d28d9);
  static const violetLight = Color(0xffede9fe);
  static const violetDark = Color(0xff4c1d95);

  static const emerald500 = Color(0xff10b981);
  static const emerald600 = Color(0xff059669);
  static const emerald50 = Color(0xffecfdf5);
  static const emerald100 = Color(0xffd1fae5);

  static const amber500 = Color(0xfff59e0b);
  static const amber900 = Color(0xff92400e);
  static const amber100 = Color(0xfffef3c7);

  static const rose500 = Color(0xfff43f5e);
  static const rose50 = Color(0xfffff1f2);
  static const rose700 = Color(0xffbe123c);

  static const slate100 = Color(0xfff1f5f9);
  static const slate400 = Color(0xff94a3b8);
  static const slate500 = Color(0xff64748b);
  static const slate800 = Color(0xff1e293b);
  static const slate900 = Color(0xff0f172a);

  static const sky400 = Color(0xff38bdf8);

  static List<BoxShadow> soft() => const [
        BoxShadow(
          color: Color(0x0d000000),
          blurRadius: 30,
          offset: Offset(0, 8),
        ),
      ];

  static List<BoxShadow> glow() => const [
        BoxShadow(
          color: Color(0x3300695C),
          blurRadius: 25,
          spreadRadius: -5,
          offset: Offset(0, 10),
        ),
      ];
}

class MySalaryScreen extends StatelessWidget {
  const MySalaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionController>();
    return ChangeNotifierProvider(
      create: (_) => SalaryProvider(
        apiService: SalaryApiService(api: session.api),
      ),
      child: const _MySalaryBody(),
    );
  }
}

class _MySalaryBody extends StatefulWidget {
  const _MySalaryBody();

  @override
  State<_MySalaryBody> createState() => _MySalaryBodyState();
}

class _MySalaryBodyState extends State<_MySalaryBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalaryProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    return Consumer<SalaryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return RefreshablePage(
            onRefresh: provider.load,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (provider.error != null) {
          return RefreshablePage(
            onRefresh: provider.load,
            child: _ErrorState(
              message: provider.error!,
              onRetry: provider.load,
            ),
          );
        }
        final data = provider.data;
        if (data == null) {
          return _EmptyState(isArabic: isArabic, onRefresh: provider.load);
        }
        return RefreshIndicator(
          onRefresh: provider.load,
          color: _Palette.violet,
          backgroundColor: Colors.white,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).padding.bottom + 28,
            ),
            children: [
              _HeroBanner(
                provider: provider,
                isArabic: isArabic,
              ),
              if (data.salaryType != 'monthly') ...[
                const SizedBox(height: 16),
                _ContractCard(data: data, isArabic: isArabic),
              ],
              const SizedBox(height: 16),
              _SummaryCard(provider: provider, isArabic: isArabic),
              const SizedBox(height: 20),
              _SectionTitle(
                isArabic
                    ? 'سجل دفعات الرواتب'
                    : 'Salary Payment History',
              ),
              const SizedBox(height: 8),
              if (data.history.isEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _Palette.slate100),
                    boxShadow: _Palette.soft(),
                  ),
                  child: Center(
                    child: Text(
                      isArabic
                          ? 'لا توجد دفعات رواتب مسجلة حتى الآن.'
                          : 'No salary payments recorded yet.',
                      style: const TextStyle(
                        color: _Palette.slate400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                for (final item in data.history) ...[
                  _HistoryCard(item: item, isArabic: isArabic),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.provider, required this.isArabic});

  final SalaryProvider provider;
  final bool isArabic;

  static const monthsAr = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  static const monthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final base = provider.data?.baseSalary;
    final nextDue = provider.data?.nextDue;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        gradient: _Palette.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _Palette.glow(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              left: -40,
              child: _GlowCircle(
                size: 144,
                color: _Palette.sky400,
                alpha: .14,
              ),
            ),
            Positioned(
              bottom: -32,
              right: -32,
              child: _GlowCircle(
                size: 128,
                color: _Palette.violetLight,
                alpha: .16,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .10),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const _PulseDot(),
                                  const SizedBox(width: 6),
                                  Text(
                                    _salaryTypeLabel(
                                      provider.data?.salaryType ?? 'monthly',
                                      isArabic,
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xffe0f2f1),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isArabic ? 'رواتبي' : 'My Salary',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isArabic
                                  ? 'تتبع راتبك الأساسي ودفعات الرواتب المستحقة والمدفوعة'
                                  : 'Track your base salary and due/paid salary payments',
                              style: TextStyle(
                                color: const Color(0xffb2dfdb)
                                    .withValues(alpha: .9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xff34d399),
                              Color(0xff059669),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x4d10b981),
                              blurRadius: 18,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: .15),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.data?.salaryType == 'hourly'
                                  ? (isArabic ? 'سعر الساعة' : 'Hour Rate')
                                  : provider.data?.salaryType == 'custom'
                                      ? (isArabic ? 'قيمة العقد' : 'Contract Value')
                                      : (isArabic ? 'الراتب الأساسي' : 'Base Salary'),
                              style: const TextStyle(
                                color: Color(0xff80cbc4),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  (provider.data?.salaryType == 'hourly'
                                          ? provider.data?.hourRate
                                          : provider.data?.salaryType == 'custom'
                                              ? provider.data?.customSalaryAmount
                                              : base) !=
                                      null
                                      ? _formatThousands(
                                          provider.data?.salaryType == 'hourly'
                                              ? provider.data!.hourRate!
                                              : provider.data?.salaryType == 'custom'
                                                  ? provider.data!.customSalaryAmount!
                                                  : base!,
                                        )
                                      : '--',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'ر.س',
                                  style: TextStyle(
                                    color: Color(0xffb2dfdb),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextDue != null
                                  ? (isArabic ? 'الدفعة القادمة' : 'Next Due')
                                  : (isArabic ? 'حالة الدفعات' : 'Pay Status'),
                              style: TextStyle(
                                color:
                                    nextDue != null && nextDue.isOverdue
                                        ? const Color(0xfffecaca)
                                        : const Color(0xffa5d6a7),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (nextDue != null)
                              Text(
                                _monthLabel(nextDue.periodMonth, nextDue.periodYear),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            else
                              Text(
                                isArabic ? 'لا دفعات معلقة' : 'All settled',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthLabel(int month, int year) {
    final list = isArabic ? monthsAr : monthsEn;
    final name = month >= 1 && month <= 12 ? list[month - 1] : '?';
    return '$name $year';
  }
}

/// Shows the teacher's salary contract details for hourly & custom types:
/// hour rate, contract value, and (for custom) the installment schedule.
class _ContractCard extends StatelessWidget {
  const _ContractCard({required this.data, required this.isArabic});

  final TeacherSalaryData data;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _Palette.slate100),
        boxShadow: _Palette.soft(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: _Palette.amber500,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'تفاصيل العقد' : 'Contract Details',
                style: const TextStyle(
                  color: _Palette.slate800,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _Palette.amber100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _salaryTypeLabel(data.salaryType, isArabic),
                  style: const TextStyle(
                    color: _Palette.amber900,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (data.salaryType == 'hourly' && data.hourRate != null)
            _contractRow(
              icon: Icons.schedule_rounded,
              label: isArabic ? 'سعر الساعة' : 'Hour rate',
              value:
                  '${_formatThousands(data.hourRate!)} ${isArabic ? 'ر.س' : 'SAR'}',
              hint: isArabic
                  ? 'يُحسب الراتب = الساعات المسجلة × سعر الساعة'
                  : 'Salary = logged hours × hour rate',
            ),
          if (data.salaryType == 'custom') ...[
            if (data.customSalaryAmount != null)
              _contractRow(
                icon: Icons.request_quote_rounded,
                label: isArabic ? 'المبلغ الإجمالي' : 'Total amount',
                value:
                    '${_formatThousands(data.customSalaryAmount!)} ${isArabic ? 'ر.س' : 'SAR'}',
              ),
            if (data.customInstallments != null &&
                data.customInstallments!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                isArabic ? 'جدول الأقساط' : 'Installment schedule',
                style: const TextStyle(
                  color: _Palette.slate500,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final inst in data.customInstallments!) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _Palette.slate100.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        inst.isPaid
                            ? Icons.check_circle_rounded
                            : Icons.pending_rounded,
                        size: 16,
                        color: inst.isPaid
                            ? _Palette.emerald500
                            : _Palette.amber500,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          inst.title ??
                              (isArabic
                                  ? 'قسط ${inst.dueDate}'
                                  : 'Installment ${inst.dueDate}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _Palette.slate800,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${_formatThousands(inst.amount)} ${isArabic ? 'ر.س' : 'SAR'}',
                        style: const TextStyle(
                          color: _Palette.slate800,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Widget _contractRow({
    required IconData icon,
    required String label,
    required String value,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: _Palette.slate400),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _Palette.slate500,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: _Palette.slate800,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint,
            style: const TextStyle(
              color: _Palette.slate400,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}

String _salaryTypeLabel(String type, bool isArabic) {
  switch (type) {
    case 'hourly':
      return isArabic ? 'راتب بالساعات' : 'Hourly Salary';
    case 'custom':
      return isArabic ? 'راتب مقسّط' : 'Installment Salary';
    default:
      return isArabic ? 'الراتب الشهري' : 'Monthly Salary';
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.color,
    required this.alpha,
  });

  final double size;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: alpha), Colors.transparent],
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: .5, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xff34d399),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.provider, required this.isArabic});

  final SalaryProvider provider;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final pills = [
      (
        icon: Icons.payments_rounded,
        color: _Palette.violet,
        bg: _Palette.violetLight,
        text: _Palette.violetDark,
        label: isArabic ? 'إجمالي المدفوع' : 'Total Paid',
        value: _formatThousands(provider.totalPaid),
      ),
      (
        icon: Icons.check_circle_rounded,
        color: _Palette.emerald500,
        bg: _Palette.emerald50,
        text: _Palette.emerald600,
        label: isArabic ? 'دفعات مدفوعة' : 'Paid',
        value: '${provider.paidCount}',
      ),
      (
        icon: Icons.pending_rounded,
        color: _Palette.amber500,
        bg: _Palette.amber100,
        text: _Palette.amber900,
        label: isArabic ? 'دفعات معلقة' : 'Pending',
        value: '${provider.pendingCount}',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _Palette.slate100),
        boxShadow: _Palette.soft(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: _Palette.violet,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'ملخص الرواتب' : 'Salary Summary',
                style: const TextStyle(
                  color: _Palette.slate800,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _KpiPill(data: pills[0])),
              const SizedBox(width: 10),
              Expanded(child: _KpiPill(data: pills[1])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _KpiPill(data: pills[2])),
              const SizedBox(width: 10),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiPill extends StatelessWidget {
  const _KpiPill({required this.data});

  final ({
    IconData icon,
    Color color,
    Color bg,
    Color text,
    String label,
    String value,
  }) data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: data.bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: data.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: data.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            data.value,
            style: TextStyle(
              color: data.text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: _Palette.violet,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _Palette.slate800,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, required this.isArabic});

  final SalaryHistoryItem item;
  final bool isArabic;

  static const monthsAr = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  static const monthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final accent = item.isPaid
        ? _Palette.emerald500
        : item.isOverdue
            ? _Palette.rose500
            : _Palette.violet;
    final monthName = (item.periodMonth >= 1 && item.periodMonth <= 12)
        ? (isArabic ? monthsAr : monthsEn)[item.periodMonth - 1]
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _Palette.slate100),
        boxShadow: _Palette.soft(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(24),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _StatusBadge(item: item, isArabic: isArabic),
                                const SizedBox(height: 8),
                                Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '$monthName ${item.periodYear}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _Palette.slate800,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  if (item.source != 'monthly') ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.source == 'hours'
                                            ? _Palette.amber100
                                            : _Palette.violetLight,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        item.source == 'hours'
                                            ? (isArabic ? 'ساعات' : 'Hours')
                                            : (isArabic ? 'قسط' : 'Installment'),
                                        style: TextStyle(
                                          color: item.source == 'hours'
                                              ? _Palette.amber900
                                              : _Palette.violet,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatThousands(item.amount),
                                style: TextStyle(
                                  color: item.isPaid
                                      ? _Palette.emerald600
                                      : _Palette.slate900,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Text(
                                'ر.س',
                                style: TextStyle(
                                  color: _Palette.slate400,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(height: 1, color: _Palette.slate100),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            item.isPaid
                                ? Icons.event_available_rounded
                                : Icons.event_rounded,
                            size: 14,
                            color: _Palette.slate400,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.isPaid
                                  ? '${isArabic ? 'تاريخ الدفع' : 'Paid on'}: ${item.paidAt ?? item.dueDate}'
                                  : '${isArabic ? 'تاريخ الاستحقاق' : 'Due date'}: ${item.dueDate}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _Palette.slate500,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (item.paymentMethod != null &&
                              item.paymentMethod!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              _methodLabel(item.paymentMethod!),
                              style: const TextStyle(
                                color: _Palette.slate400,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'bank_transfer':
        return isArabic ? 'تحويل بنكي' : 'Transfer';
      case 'check':
        return isArabic ? 'شيك' : 'Check';
      default:
        return isArabic ? 'نقدي' : 'Cash';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.item, required this.isArabic});

  final SalaryHistoryItem item;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    if (item.isPaid) {
      return _badge(
        bg: _Palette.emerald100,
        color: _Palette.emerald600,
        icon: Icons.check_rounded,
        label: isArabic ? 'مدفوع' : 'Paid',
      );
    }
    if (item.status == 'cancelled') {
      return _badge(
        bg: _Palette.slate100,
        color: _Palette.slate500,
        icon: Icons.block_rounded,
        label: isArabic ? 'ملغي' : 'Cancelled',
      );
    }
    if (item.isOverdue) {
      return _badge(
        bg: _Palette.rose50,
        color: _Palette.rose700,
        icon: Icons.error_rounded,
        label: isArabic ? 'متأخر' : 'Overdue',
      );
    }
    return _badge(
      bg: _Palette.violetLight,
      color: _Palette.violet,
      icon: Icons.schedule_rounded,
      label: isArabic ? 'مستحق' : 'Due',
    );
  }

  Widget _badge({
    required Color bg,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isArabic, required this.onRefresh});

  final bool isArabic;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _Palette.violetLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: _Palette.violet,
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isArabic ? 'لا توجد بيانات رواتب' : 'No salary data',
            style: const TextStyle(
              color: _Palette.slate800,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isArabic
                ? 'لم يتم تسجيل راتب بعد لهذا المعلم.'
                : 'No salary has been recorded for this teacher yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _Palette.slate400,
              fontSize: 12,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRefresh,
            style: FilledButton.styleFrom(
              backgroundColor: _Palette.violet,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(isArabic ? 'تحديث' : 'Refresh'),
          ),
        ],
      ),
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _Palette.rose50,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: _Palette.rose500,
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _Palette.slate500, fontSize: 13),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: _Palette.rose500,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
          ),
        ],
      ),
    );
  }
}

String _formatThousands(num value) {
  final whole =
      (value is double && value == value.roundToDouble() && value.abs() < 1e12)
          ? value.toInt()
          : value;
  final s = whole.toString();
  final buffer = StringBuffer();
  final digits = s.replaceAll('-', '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return s.startsWith('-') ? '-$buffer' : buffer.toString();
}