import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_state.dart';
import '../../../../core/state/session_controller.dart';
import '../../../../core/localization/module_localization.dart';
import '../../../../core/widgets/refreshable_content.dart';
import '../../../../widgets/shared_widgets.dart';
import '../../data/installment_api_service.dart';
import '../../domain/models/my_installment_model.dart';
import '../providers/installment_provider.dart';

/// Palette matching the bottom-services HTML mockup (Tailwind colors).
class _Palette {
  static const orange = Color(0xfff97316);

  static const blue600 = Color(0xff2563eb);
  static const blue700 = Color(0xff1d4ed8);
  static const indigo800 = Color(0xff3730a3);
  static const blue50 = Color(0xffeff6ff);
  static const blue100 = Color(0xffdbeafe);
  static const blue900 = Color(0xff1e3a8a);

  static const emerald500 = Color(0xff10b981);
  static const emerald600 = Color(0xff059669);
  static const emerald50 = Color(0xffecfdf5);
  static const emerald100 = Color(0xffd1fae5);

  static const amber500 = Color(0xfff59e0b);
  static const amber400 = Color(0xfffbbf24);
  static const amber100 = Color(0xfffef3c7);
  static const amber800 = Color(0xff92400e);
  static const amber900 = Color(0xff78350f);

  static const rose500 = Color(0xfff43f5e);
  static const rose50 = Color(0xfffff1f2);
  static const rose100 = Color(0xffffe4e6);
  static const rose700 = Color(0xffbe123c);
  static const rose900 = Color(0xff881337);

  static const slate100 = Color(0xfff1f5f9);
  static const slate200 = Color(0xffe2e8f0);
  static const slate400 = Color(0xff94a3b8);
  static const slate500 = Color(0xff64748b);
  static const slate600 = Color(0xff475569);
  static const slate800 = Color(0xff1e293b);
  static const slate900 = Color(0xff0f172a);

  static const sky400 = Color(0xff38bdf8);
  static const emeraldPulse = Color(0xff34d399);

  static const heroGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF1E3C72), Color(0xFF2A52BE)],
  );

  static const payGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [orange, amber500],
  );

  static const bluePillGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [blue600, indigo800],
  );

  static const amberBadgeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [amber400, amber500],
  );

  static List<BoxShadow> soft() => const [
        BoxShadow(
          color: Color(0x0d000000),
          blurRadius: 30,
          offset: Offset(0, 8),
        ),
      ];

  static List<BoxShadow> glowOrange() => const [
        BoxShadow(
          color: Color(0x66f97316),
          blurRadius: 25,
          spreadRadius: -5,
          offset: Offset(0, 10),
        ),
      ];

  static List<BoxShadow> glowBlue() => const [
        BoxShadow(
          color: Color(0x4d1E3C72),
          blurRadius: 25,
          spreadRadius: -5,
          offset: Offset(0, 10),
        ),
      ];
}

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
  int? _lastSelectedChildId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final selected = context.watch<AppState>().selectedChildId;
    if (_initialized && selected == _lastSelectedChildId) return;
    _initialized = true;
    _lastSelectedChildId = selected;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<InstallmentProvider>().setSelectedStudent(selected);
    });
  }

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
      installment =
          provider.myInstallments.where((i) => i.id == id).firstOrNull;
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
          color: _Palette.blue600,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).padding.bottom + 28,
            ),
            itemCount: _itemCount(provider),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _HeroBanner(provider: provider);
              }
              if (index == 1) {
                return _SummaryCard(summary: provider.summary);
              }
              if (index == 2) {
                return _FilterChips(
                  selected: provider.filter,
                  onSelected: provider.setFilter,
                  summary: provider.summary,
                );
              }
              if (index == _itemCount(provider) - 1) {
                return const _PaymentSupportStrip();
              }
              if (provider.isParent) {
                final groupIndex = index - 3;
                if (provider.parentGroups.isEmpty) {
                  return _EmptySyncCard(
                    isArabic: isArabic,
                    onRefresh: provider.loadMyInstallments,
                  );
                }
                final group = provider.parentGroups[groupIndex];
                return _StudentInstallmentGroup(
                  group: group,
                  onTap: (installment) => _openDetail(context, installment),
                );
              }
              final installmentIndex = index - 3;
              if (provider.myInstallments.isEmpty) {
                return _EmptySyncCard(
                  isArabic: isArabic,
                  onRefresh: provider.loadMyInstallments,
                );
              }
              final installment = provider.myInstallments[installmentIndex];
              return _InstallmentCard(
                installment: installment,
                isArabic: isArabic,
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
          ? 5
          : provider.parentGroups.length + 4;
    }
    return provider.myInstallments.isEmpty
        ? 5
        : provider.myInstallments.length + 4;
  }

  void _openDetail(BuildContext context, MyInstallment installment) {
    context.push('/installment-detail', extra: installment);
  }
}

/* ─────────────────────────────── Hero Banner ─────────────────────────────── */

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.provider});

  final InstallmentProvider provider;

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    final total = provider.allInstallments.fold<double>(
      0,
      (sum, i) => sum + i.amount,
    );
    final remaining = provider.allInstallments.fold<double>(
      0,
      (sum, i) => sum + i.remainingAmount,
    );
    final isParent = provider.isParent;

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 16),
      decoration: BoxDecoration(
        gradient: _Palette.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _Palette.glowBlue(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative ambient circles
            Positioned(
              top: -40,
              left: -40,
              child: _GlowCircle(
                size: 144,
                color: _Palette.sky400,
                alpha: .18,
              ),
            ),
            Positioned(
              bottom: -32,
              right: -32,
              child: _GlowCircle(
                size: 128,
                color: _Palette.indigo800,
                alpha: .30,
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
                            // Status badge
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
                                    isArabic
                                        ? 'العام الدراسي ${_academicYear()}'
                                        : 'Academic Year ${_academicYear()}',
                                    style: const TextStyle(
                                      color: Color(0xfff0f9ff),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isParent
                                  ? (isArabic
                                      ? 'أقساط الأبناء'
                                      : 'Children Installments')
                                  : (isArabic
                                      ? 'أقساطي المدرسية'
                                      : 'My School Installments'),
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
                                  ? 'عرض الأقساط المستحقة والمدفوعة ومتابعة السداد'
                                  : 'View due and paid installments and track payments',
                              style: TextStyle(
                                color: const Color(0xffdbeafe)
                                    .withValues(alpha: .9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Wallet icon badge
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: _Palette.amberBadgeGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x4dfbbf24),
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
                  Container(height: 1, color: Colors.white.withValues(alpha: .15)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic
                                  ? 'إجمالي الرسوم الدراسية'
                                  : 'Total Tuition Fees',
                              style: const TextStyle(
                                color: Color(0xffbfdbfe),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  _formatThousands(total),
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
                                    color: Color(0xffbae6fd),
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
                              isArabic
                                  ? 'المبلغ المتبقي سداده'
                                  : 'Remaining Balance',
                              style: const TextStyle(
                                color: Color(0xfffde68a),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  _formatThousands(remaining),
                                  style: const TextStyle(
                                    color: Color(0xfffcd34d),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'ر.س',
                                  style: TextStyle(
                                    color: Color(0xfffde68a),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
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

  String _academicYear() {
    final now = DateTime.now();
    final year = now.year;
    return now.month >= 9 ? '$year - ${year + 1}' : '${year - 1} - $year';
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
          color: _Palette.emeraldPulse,
        ),
      ),
    );
  }
}

/* ─────────────────────────────── Summary KPI ─────────────────────────────── */

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final InstallmentSummary summary;

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    final pills = [
      _KpiPillData(
        label: isArabic ? 'الكل' : 'All',
        value: summary.totalInstallments,
        icon: Icons.wallet_rounded,
        color: _Palette.blue600,
        bg: _Palette.blue50,
        border: _Palette.blue100,
        text: _Palette.blue900,
      ),
      _KpiPillData(
        label: isArabic ? 'مدفوع' : 'Paid',
        value: summary.paidCount,
        icon: Icons.check_circle_rounded,
        color: _Palette.emerald500,
        bg: _Palette.emerald50,
        border: _Palette.emerald100,
        text: _Palette.emerald600,
      ),
      _KpiPillData(
        label: isArabic ? 'مستحق' : 'Due',
        value: summary.pendingCount + summary.partialCount,
        icon: Icons.pending_rounded,
        color: _Palette.amber500,
        bg: const Color(0xfffffbeb),
        border: _Palette.amber100,
        text: _Palette.amber900,
      ),
      _KpiPillData(
        label: isArabic ? 'متأخر' : 'Overdue',
        value: summary.overdueCount,
        icon: Icons.warning_rounded,
        color: _Palette.rose500,
        bg: _Palette.rose50,
        border: _Palette.rose100,
        text: _Palette.rose900,
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                  color: _Palette.orange,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'ملخص الأقساط' : 'Installment Summary',
                style: const TextStyle(
                  color: _Palette.slate800,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                isArabic ? 'سنة كاملة (4 دفعات)' : 'Full year (4 installments)',
                style: const TextStyle(
                  color: _Palette.slate400,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var row = 0; row < 2; row++) ...[
            if (row > 0) const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _KpiPill(data: pills[row * 2])),
                const SizedBox(width: 10),
                Expanded(child: _KpiPill(data: pills[row * 2 + 1])),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _KpiPillData {
  const _KpiPillData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
    required this.text,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;
  final Color text;
}

class _KpiPill extends StatelessWidget {
  const _KpiPill({required this.data});

  final _KpiPillData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: data.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: data.border),
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
            '${data.value}',
            style: TextStyle(
              color: data.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/* ─────────────────────────────── Filter Chips ────────────────────────────── */

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.onSelected,
    required this.summary,
  });

  final InstallmentFilter selected;
  final ValueChanged<InstallmentFilter> onSelected;
  final InstallmentSummary summary;

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);

    final chips = [
      (
        filter: InstallmentFilter.all,
        label: isArabic ? 'الكل' : 'All',
        count: summary.totalInstallments,
      ),
      (
        filter: InstallmentFilter.pending,
        label: isArabic ? 'مستحق' : 'Due',
        count: summary.pendingCount + summary.partialCount,
      ),
      (
        filter: InstallmentFilter.paid,
        label: isArabic ? 'مدفوع' : 'Paid',
        count: summary.paidCount,
      ),
      (
        filter: InstallmentFilter.overdue,
        label: isArabic ? 'متأخر' : 'Overdue',
        count: summary.overdueCount,
      ),
      (
        filter: InstallmentFilter.urgent,
        label: isArabic ? 'عاجل' : 'Urgent',
        count: summary.urgentCount,
      ),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isSelected = selected == chip.filter;
          return _FilterPill(
            label: chip.label,
            count: chip.count,
            selected: isSelected,
            onTap: () => onSelected(chip.filter),
          );
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        constraints: const BoxConstraints(minWidth: 72),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? _Palette.bluePillGradient : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? _Palette.blue600
                : _Palette.slate200.withValues(alpha: .8),
          ),
          boxShadow: selected ? _Palette.glowBlue() : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            Text(
              '$label ($count)',
              style: TextStyle(
                color: selected ? Colors.white : _Palette.slate600,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ─────────────────────────── Installment Cards ───────────────────────────── */

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
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _Palette.blue50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.child_care_rounded,
                  color: _Palette.blue600,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                group.studentName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _Palette.slate800,
                ),
              ),
            ],
          ),
        ),
        for (final installment in group.installments) ...[
          _InstallmentCard(
            installment: installment,
            isArabic: appIsArabic(context),
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
    required this.isArabic,
    required this.onTap,
  });

  final MyInstallment installment;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final planTitle =
        displayValue(installment.planTitle, languageCode: languageCode);
    final accent = _accentColor(installment);
    final isPaid = installment.isPaid;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _Palette.slate100),
        boxShadow: _Palette.soft(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Accent right edge line
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _StatusBadge(
                                      installment: installment,
                                      isArabic: isArabic,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      planTitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _Palette.slate800,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        height: 1.25,
                                      ),
                                    ),
                                    if (installment.installmentTitle.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          installment.installmentTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: _Palette.slate400,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.event_rounded,
                                          size: 14,
                                          color: _Palette.slate400,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${isPaid ? (isArabic ? 'تاريخ السداد' : 'Payment date') : (isArabic ? 'تاريخ الاستحقاق' : 'Due date')}: ${_dueDateLabel()}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: _Palette.slate500,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Price tag
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatThousands(installment.amount),
                                    style: TextStyle(
                                      color: isPaid
                                          ? _Palette.emerald600
                                          : _Palette.slate900,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                    ),
                                  ),
                                  Text(
                                    isArabic ? 'ريال سعودي' : 'SAR',
                                    style: const TextStyle(
                                      color: _Palette.slate400,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 1,
                            color: _Palette.slate100,
                          ),
                          const SizedBox(height: 12),
                          if (isPaid)
                            _PaidActions(installment: installment, isArabic: isArabic)
                          else
                            _DueActions(isArabic: isArabic),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _accentColor(MyInstallment i) {
    if (i.isPaid) return _Palette.emerald500;
    if (i.isOverdue) return _Palette.rose500;
    if (i.urgency == 'urgent') return _Palette.rose500;
    if (i.urgency == 'upcoming') return _Palette.amber500;
    return _Palette.blue600;
  }

  String _dueDateLabel() {
    if (installment.isPaid && installment.receipts.isNotEmpty) {
      return installment.receipts.first.date;
    }
    return installment.dueDate;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.installment, required this.isArabic});

  final MyInstallment installment;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    if (installment.isPaid) {
      return _badge(
        bg: _Palette.emerald100,
        color: _Palette.emerald600,
        icon: Icons.check_rounded,
        label: isArabic ? 'تم الدفع بنجاح' : 'Paid',
      );
    }
    if (installment.isOverdue) {
      return _badge(
        bg: _Palette.rose100,
        color: _Palette.rose700,
        icon: Icons.error_rounded,
        label: isArabic ? 'متأخر' : 'Overdue',
      );
    }
    if (installment.urgency == 'urgent') {
      return _badge(
        bg: _Palette.rose50,
        color: _Palette.rose700,
        icon: Icons.priority_high_rounded,
        label: isArabic ? 'عاجل' : 'Urgent',
      );
    }
    if (installment.status.toLowerCase() == 'partial') {
      return _badge(
        bg: _Palette.amber100,
        color: _Palette.amber800,
        icon: Icons.payments_rounded,
        label: isArabic ? 'جزئي السداد' : 'Partially Paid',
      );
    }
    return _badge(
      bg: _Palette.amber100,
      color: _Palette.amber800,
      icon: Icons.schedule_rounded,
      label: isArabic ? 'مستحق السداد' : 'Due',
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

class _DueActions extends StatelessWidget {
  const _DueActions({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                gradient: _Palette.payGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _Palette.glowOrange(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.payments_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isArabic ? 'سداد الآن' : 'Pay Now',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isArabic ? 'التفاصيل' : 'Details',
          style: const TextStyle(
            color: _Palette.slate600,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PaidActions extends StatelessWidget {
  const _PaidActions({required this.installment, required this.isArabic});

  final MyInstallment installment;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final receiptNo =
        installment.receipts.isNotEmpty ? installment.receipts.first.id : null;
    return Row(
      children: [
        Expanded(
          child: Text(
            receiptNo != null
                ? '${isArabic ? 'رقم الإيصال' : 'Receipt No'}: #REC-$receiptNo'
                : (isArabic ? 'مدفوع بالكامل' : 'Fully paid'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _Palette.slate400,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: [
            const Icon(
              Icons.download_rounded,
              size: 14,
              color: _Palette.blue600,
            ),
            const SizedBox(width: 4),
            Text(
              isArabic ? 'تحميل الإيصال PDF' : 'Download PDF',
              style: const TextStyle(
                color: _Palette.blue600,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/* ─────────────────────────────── Empty State ─────────────────────────────── */

class _EmptySyncCard extends StatelessWidget {
  const _EmptySyncCard({required this.isArabic, required this.onRefresh});

  final bool isArabic;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xfffafafa)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _Palette.slate200,
        ),
        boxShadow: _Palette.soft(),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _Palette.blue50,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: _Palette.blue600,
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isArabic ? 'لا توجد أقساط إضافية معلقة' : 'No pending installments',
            style: const TextStyle(
              color: _Palette.slate800,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isArabic
                ? 'تم تسجيل وتحديث جميع دفعاتك المالية بانتظام مع الإدارة المالية.'
                : 'All your financial payments are up to date with the finance office.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _Palette.slate400,
              fontSize: 12,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRefresh,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: _Palette.bluePillGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _Palette.glowBlue(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isArabic ? 'تحديث البيانات المالية' : 'Refresh financial data',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ─────────────────────────── Payment Methods Strip ───────────────────────── */

class _PaymentSupportStrip extends StatelessWidget {
  const _PaymentSupportStrip();

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.slate100),
        boxShadow: _Palette.soft(),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _Palette.slate100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              size: 16,
              color: _Palette.slate600,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'طرق السداد المعتمدة' : 'Accepted payment methods',
                  style: const TextStyle(
                    color: _Palette.slate800,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'مدى، فيزا، Apple Pay، سداد',
                  style: const TextStyle(
                    color: _Palette.slate400,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isArabic ? 'المزيد' : 'More',
            style: const TextStyle(
              color: _Palette.blue600,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/* ─────────────────────────────── Error State ─────────────────────────────── */

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
              backgroundColor: _Palette.blue600,
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

/* ─────────────────────────────── Helpers ─────────────────────────────────── */

String _formatThousands(double value) {
  final text = value.truncateToDouble() == value
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  final parts = text.split('.');
  final buffer = StringBuffer();
  for (var i = 0; i < parts[0].length; i++) {
    if (i > 0 && (parts[0].length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(parts[0][i]);
  }
  return parts.length > 1 ? '$buffer.${parts[1]}' : buffer.toString();
}