import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/data/school_repository.dart';
import '../../core/localization/module_localization.dart';
import '../../core/models/app_models.dart';
import '../../core/network/exam_service.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/refreshable_content.dart';
import '../../widgets/shared_widgets.dart';
import 'exam_controller.dart';

class ExamsListScreen extends StatelessWidget {
  const ExamsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionController>();
    final isTeacher = session.currentRole == UserRole.teacher;
    return ChangeNotifierProvider(
      create: (_) => ExamController(
        ExamService(session.api),
        isTeacher: isTeacher,
        teacherId: session.user?.id,
      ),
      child: _ExamsListView(isTeacher: isTeacher),
    );
  }
}

enum _Filter { all, completed, started, upcoming }

// =====================================================================
// Subject accent palettes (mirrors the Tailwind color system)
// =====================================================================
typedef _Palette = ({
  Color bg,
  Color fg,
  Color border,
  Color stripStart,
  Color stripEnd,
});

const _palettes = <_Palette>[
  (
    bg: Color(0xFFEFF6FF),
    fg: Color(0xFF2563EB),
    border: Color(0xFFDBEAFE),
    stripStart: Color(0xFF60A5FA),
    stripEnd: Color(0xFF818CF8),
  ),
  (
    bg: Color(0xFFF0FDFA),
    fg: Color(0xFF0D9488),
    border: Color(0xFFCCFBF1),
    stripStart: Color(0xFF2DD4BF),
    stripEnd: Color(0xFF34D399),
  ),
  (
    bg: Color(0xFFF5F3FF),
    fg: Color(0xFF7C3AED),
    border: Color(0xFFEDE9FE),
    stripStart: Color(0xFFA78BFA),
    stripEnd: Color(0xFFC084FC),
  ),
  (
    bg: Color(0xFFFDF4FF),
    fg: Color(0xFFC026D3),
    border: Color(0xFFFAE8FF),
    stripStart: Color(0xFFE879F9),
    stripEnd: Color(0xFFF0ABFC),
  ),
  (
    bg: Color(0xFFFEF3C7),
    fg: Color(0xFFD97706),
    border: Color(0xFFFDE68A),
    stripStart: Color(0xFFFBBF24),
    stripEnd: Color(0xFFF59E0B),
  ),
  (
    bg: Color(0xFFFEE2E2),
    fg: Color(0xFFDC2626),
    border: Color(0xFFFECACA),
    stripStart: Color(0xFFF87171),
    stripEnd: Color(0xFFFB923C),
  ),
  (
    bg: Color(0xFFECFEFF),
    fg: Color(0xFF0891B2),
    border: Color(0xFFCFFAFE),
    stripStart: Color(0xFF22D3EE),
    stripEnd: Color(0xFF67E8F9),
  ),
  (
    bg: Color(0xFFF0FDF4),
    fg: Color(0xFF16A34A),
    border: Color(0xFFDCFCE7),
    stripStart: Color(0xFF4ADE80),
    stripEnd: Color(0xFFA3E635),
  ),
];

const _subjectIcons = <IconData>[
  Icons.assignment_rounded,
  Icons.menu_book_rounded,
  Icons.science_rounded,
  Icons.calculate_rounded,
  Icons.translate_rounded,
  Icons.music_note_rounded,
  Icons.palette_rounded,
  Icons.sports_soccer_rounded,
  Icons.travel_explore_rounded,
  Icons.code_rounded,
  Icons.auto_stories_rounded,
  Icons.emoji_objects_rounded,
];

int _hashSeed(String input) {
  var h = 0;
  for (final code in input.codeUnits) {
    h = (h * 31 + code) & 0x7fffffff;
  }
  return h;
}

class _ExamsListView extends StatefulWidget {
  const _ExamsListView({this.isTeacher = false});

  final bool isTeacher;

  @override
  State<_ExamsListView> createState() => _ExamsListViewState();
}

class _ExamsListViewState extends State<_ExamsListView> {
  _Filter _selected = _Filter.all;
  String? _subjectFilter;
  String? _sectionFilter;
  List<String> _subjectOptions = const [];
  List<String> _sectionOptions = const [];

  @override
  void initState() {
    super.initState();
    if (widget.isTeacher) _loadFilterOptions();
  }

  /// Filter options scoped to the logged-in teacher: only his subjects and
  /// the sections he has students in.
  Future<void> _loadFilterOptions() async {
    final session = context.read<SessionController>();
    final repo = SchoolRepository(session.api);
    try {
      final options = await repo.teacherModalOptions(
        languageCode: session.locale.languageCode,
      );
      if (!mounted) return;
      setState(() {
        _subjectOptions = [
          for (final option in options['subjects'] ?? const <FormOption>[])
            option.label,
        ];
        _sectionOptions = [
          for (final option in options['sections'] ?? const <FormOption>[])
            option.label,
        ];
      });
    } catch (_) {
      // Options are best-effort; the list itself still loads.
    }
  }

  List<dynamic> _applyFilter(List<dynamic> exams) {
    var filtered = exams;
    switch (_selected) {
      case _Filter.all:
        break;
      case _Filter.completed:
        filtered = filtered.where((e) => e.isFinished).toList();
      case _Filter.started:
        filtered = filtered.where((e) => e.isStarted && !e.isFinished).toList();
      case _Filter.upcoming:
        filtered = filtered.where((e) => e.isNotStarted).toList();
    }
    if (_subjectFilter != null) {
      filtered = filtered.where((e) => e.subject == _subjectFilter).toList();
    }
    if (_sectionFilter != null) {
      filtered = filtered.where((e) => e.section == _sectionFilter).toList();
    }
    return filtered;
  }

  Widget _teacherScopeChips(bool isAr) {
    if (!widget.isTeacher) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScopeChipsRow(
          title: isAr ? 'المادة' : 'Subject',
          options: _subjectOptions,
          selected: _subjectFilter,
          isAr: isAr,
          onChanged: (value) => setState(() => _subjectFilter = value),
        ),
        const SizedBox(height: 10),
        _ScopeChipsRow(
          title: isAr ? 'الفصل' : 'Section',
          options: _sectionOptions,
          selected: _sectionFilter,
          isAr: isAr,
          onChanged: (value) => setState(() => _sectionFilter = value),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = appIsArabic(context);
    final controller = context.watch<ExamController>();

    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'الاختبارات' : 'Exams')),
      body: Container(
        color: const Color(0xFFF8FAFC),
        child: SafeArea(
          child: _buildBody(context, controller, isAr),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ExamController controller,
    bool isAr,
  ) {
    if (controller.loading && controller.exams.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null && controller.exams.isEmpty) {
      return Center(
        child: NoDataWidget(
          icon: Icons.error_outline_rounded,
          title: controller.error!,
          onRefresh: controller.loadExams,
        ),
      );
    }

    if (controller.exams.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.loadExams,
        color: AppTheme.primary,
        backgroundColor: Colors.white,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            SizedBox(
              height: 360,
              child: NoDataWidget(
                icon: Icons.assignment_rounded,
                title: isAr ? 'لا توجد اختبارات متاحة' : 'No exams available',
                message: t(context, 'noDataMessage'),
                onRefresh: controller.loadExams,
              ),
            ),
          ],
        ),
      );
    }

    final filtered = _applyFilter(controller.exams);

    return RefreshIndicator(
      onRefresh: controller.loadExams,
      color: AppTheme.primary,
      backgroundColor: Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _FilterChipsRow(
            selected: _selected,
            onChanged: (f) => setState(() => _selected = f),
            counts: (
              all: controller.exams.length,
              completed: controller.exams.where((e) => e.isFinished).length,
              started: controller.exams
                  .where((e) => e.isStarted && !e.isFinished)
                  .length,
              upcoming:
                  controller.exams.where((e) => e.isNotStarted).length,
            ),
            isAr: isAr,
          ),
          const SizedBox(height: 20),
          _teacherScopeChips(isAr),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            NoDataWidget(
              compact: true,
              icon: Icons.filter_alt_off_rounded,
              title: isAr
                  ? 'لا توجد اختبارات في هذه الفئة'
                  : 'No exams in this category',
            )
          else
            ...filtered.map(
              (exam) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ExamCard(
                  exam: exam,
                  isAr: isAr,
                  onTap: widget.isTeacher
                      ? () {}
                      : () {
                          if (exam.isFinished) {
                            context.push('/student/exams/${exam.id}/result');
                          } else {
                            context.push('/student/exams/${exam.id}/start');
                          }
                        },
                ),
              ),
            ),
          const SizedBox(height: 8),
          const _TipsBanner(),
        ],
      ),
    );
  }
}

// =====================================================================
// Filter chips
// =====================================================================
class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.selected,
    required this.onChanged,
    required this.counts,
    required this.isAr,
  });

  final _Filter selected;
  final ValueChanged<_Filter> onChanged;
  final ({int all, int completed, int started, int upcoming}) counts;
  final bool isAr;

  String _label(_Filter f) {
    switch (f) {
      case _Filter.all:
        return isAr ? 'الكل (${counts.all})' : 'All (${counts.all})';
      case _Filter.completed:
        return isAr ? 'تم الأداء' : 'Completed';
      case _Filter.started:
        return isAr ? 'مستمر الآن' : 'In progress';
      case _Filter.upcoming:
        return isAr ? 'القادمة' : 'Upcoming';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in _Filter.values) ...[
            _FilterChip(
              label: _label(f),
              active: selected == f,
              onTap: () => onChanged(f),
            ),
            if (f != _Filter.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFFFF8A00);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? activeColor : const Color(0xFFE2E8F0),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: .25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Teacher-scoped subject / section filter chips
// =====================================================================
class _ScopeChipsRow extends StatelessWidget {
  const _ScopeChipsRow({
    required this.title,
    required this.options,
    required this.selected,
    required this.isAr,
    required this.onChanged,
  });

  final String title;
  final List<String> options;
  final String? selected;
  final bool isAr;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: isAr ? 'الكل' : 'All',
                active: selected == null,
                onTap: () => onChanged(null),
              ),
              const SizedBox(width: 8),
              for (final option in options) ...[
                _FilterChip(
                  label: option,
                  active: selected == option,
                  onTap: () => onChanged(option),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Tips banner
// =====================================================================
class _TipsBanner extends StatelessWidget {
  const _TipsBanner();

  @override
  Widget build(BuildContext context) {
    final isAr = appIsArabic(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xCCBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: .3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.info_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'تنبيه هام' : 'Important notice',
                  style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isAr
                      ? 'تأكد من تسليم إجابات الاختبارات قبل انتهاء الوقت المحدد لكل مادة للحصول على التقييم المباشر.'
                      : 'Make sure to submit your exam answers before the time limit to get instant evaluation.',
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontSize: 11,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Exam card
// =====================================================================
class _ExamCard extends StatelessWidget {
  const _ExamCard({
    required this.exam,
    required this.isAr,
    required this.onTap,
  });

  final dynamic exam;
  final bool isAr;
  final VoidCallback onTap;

  _Palette get palette {
    final seed = '${exam.subject ?? ''}${exam.name ?? ''}'.trim();
    final idx = (seed.isEmpty ? exam.id ?? 0 : _hashSeed(seed)) %
        _palettes.length;
    return _palettes[idx];
  }

  String get _statusText {
    if (exam.isFinished) return isAr ? 'تم الأداء' : 'Completed';
    if (exam.isStarted) return isAr ? 'مستمر الآن' : 'In progress';
    return isAr ? 'متاح' : 'Available';
  }

  String get _scoreText {
    final s = exam.score;
    if (s == null) return '';
    return s == s.roundToDouble() ? s.toInt().toString() : s.toStringAsFixed(1);
  }

  String get _questionsText {
    final q = exam.questionsCount ?? 0;
    if (!isAr) return q == 1 ? '1 question' : '$q questions';
    return q == 1 ? '$q سؤال' : '$q أسئلة';
  }

  String get _timeText {
    final m = exam.timeLimit ?? 0;
    return isAr ? '$m دقيقة' : '$m min';
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = exam.isFinished;
    final isStarted = exam.isStarted && !isFinished;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isStarted ? const Color(0xE6FFEDD5) : const Color(0xFFF1F5F9),
          width: isStarted ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // Ambient glow behind ongoing exam
              if (isStarted)
                Positioned(
                  top: -34,
                  left: -34,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x26FFB020),
                    ),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isStarted) ...[
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: isStarted
                              ? const [Color(0xFFF59E0B), Color(0xFFFBBF24), Colors.transparent]
                              : [
                                  palette.stripStart,
                                  palette.stripEnd,
                                  Colors.transparent,
                                ],
                          stops: const [0, .55, 1],
                        ),
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SubjectIcon(
                              bg: isStarted
                                  ? const Color(0xFFFFF7ED)
                                  : palette.bg,
                              fg: isStarted ? const Color(0xFFF59E0B) : palette.fg,
                              border: isStarted
                                  ? const Color(0xFFFDE68A)
                                  : palette.border,
                              icon: isStarted
                                  ? Icons.science_rounded
                                  : _subjectIcons[
                                      (_hashSeed('${exam.id ?? 0}') +
                                              _hashSeed(exam.name ?? '')) %
                                          _subjectIcons.length],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exam.name ?? '—',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF1E293B),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      height: 1.25,
                                    ),
                                  ),
                                  if (exam.subject != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      isAr
                                          ? 'مادة ${exam.subject}'
                                          : exam.subject,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusCapsule(
                              mode: isFinished
                                  ? _PillMode.completed
                                  : isStarted
                                      ? _PillMode.started
                                      : _PillMode.upcoming,
                              text: _statusText,
                            ),
                          ],
                        ),
                        Container(
                          height: 1,
                          color: const Color(0xFFF1F5F9),
                          margin: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (isFinished)
                              _MetricChip(
                                icon: Icons.help_outline_rounded,
                                iconColor: const Color(0xFF94A3B8),
                                text: _questionsText,
                                bg: const Color(0xFFF8FAFC),
                                border: const Color(0xFFF1F5F9),
                                textColor: const Color(0xFF64748B),
                              ),
                            _MetricChip(
                              icon: Icons.timer_outlined,
                              iconColor: isStarted
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF94A3B8),
                              text: _timeText,
                              bg: isStarted
                                  ? const Color(0xCCFFF7ED)
                                  : const Color(0xFFF8FAFC),
                              border: isStarted
                                  ? const Color(0xCCFFEDD5)
                                  : const Color(0xFFF1F5F9),
                              textColor:
                                  isStarted ? const Color(0xFFEA580C) : const Color(0xFF64748B),
                            ),
                            if (isStarted)
                              _MetricChip(
                                icon: Icons.help_outline_rounded,
                                iconColor: const Color(0xFF94A3B8),
                                text: _questionsText,
                                bg: const Color(0xFFF8FAFC),
                                border: const Color(0xFFF1F5F9),
                                textColor: const Color(0xFF64748B),
                              ),
                            if (isFinished && exam.score != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFD1FAE5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.emoji_events_rounded,
                                      size: 15,
                                      color: Color(0xFF059669),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isAr
                                          ? 'الدرجة: $_scoreText'
                                          : 'Score: $_scoreText',
                                      style: const TextStyle(
                                        color: Color(0xFF059669),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (isStarted)
                              _CardCta(
                                label: isAr ? 'متابعة الحل' : 'Continue',
                                onTap: onTap,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFF8A00),
                                    Color(0xFFFBBF24),
                                  ],
                                ),
                                glow: const Color(0xFFFF8A00),
                                isAr: isAr,
                              ),
                            if (!isStarted && !isFinished)
                              _CardCta(
                                label: isAr ? 'ابدأ الاختبار' : 'Start exam',
                                onTap: onTap,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF3B82F6),
                                    Color(0xFF6366F1),
                                  ],
                                ),
                                glow: const Color(0xFF3B82F6),
                                isAr: isAr,
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
      ),
    );
  }
}

enum _PillMode { completed, started, upcoming }

class _StatusCapsule extends StatelessWidget {
  const _StatusCapsule({required this.mode, required this.text});

  final _PillMode mode;
  final String text;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color fg;
    switch (mode) {
      case _PillMode.completed:
        bg = const Color(0xFFECFDF5);
        border = const Color(0xFFD1FAE5);
        fg = const Color(0xFF059669);
      case _PillMode.started:
        bg = const Color(0xFFFFF7ED);
        border = const Color(0xFFFFEDD5);
        fg = const Color(0xFFEA580C);
      case _PillMode.upcoming:
        bg = const Color(0xFFEFF6FF);
        border = const Color(0xFFDBEAFE);
        fg = const Color(0xFF2563EB);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mode == _PillMode.completed)
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Icon(Icons.check_rounded, size: 14, color: fg),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: mode == _PillMode.started
                  ? const _PulseDot()
                  : Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: fg,
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  late final Animation<double> _anim =
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: .35).animate(_anim),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 1.2).animate(_anim),
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFFF59E0B),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _SubjectIcon extends StatelessWidget {
  const _SubjectIcon({
    required this.bg,
    required this.fg,
    required this.border,
    required this.icon,
  });

  final Color bg;
  final Color fg;
  final Color border;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Icon(icon, color: fg, size: 24),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.bg,
    required this.border,
    required this.textColor,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final Color bg;
  final Color border;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardCta extends StatelessWidget {
  const _CardCta({
    required this.label,
    required this.onTap,
    required this.gradient,
    required this.glow,
    required this.isAr,
  });

  final String label;
  final VoidCallback onTap;
  final Gradient gradient;
  final Color glow;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: .38),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}