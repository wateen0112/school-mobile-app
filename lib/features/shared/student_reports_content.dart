import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/module_localization.dart';
import '../../core/models/app_models.dart';
import '../../core/network/api_service.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/refreshable_content.dart';

/// Role-aware entry point for the monthly student reports module.
/// Students see their own report history, parents see every linked child
/// with the latest monthly report and can drill into full history/detail.
class StudentReportsContent extends StatelessWidget {
  const StudentReportsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final userId = session.user?.id;
    return switch (session.currentRole) {
      UserRole.parent => const _ParentReportsView(),
      UserRole.student when userId != null => StudentReportsScreen(
        studentId: userId,
        showAppBar: false,
      ),
      _ => NoDataWidget(
        icon: Icons.assessment_rounded,
        title: appIsArabic(context)
            ? 'لا يوجد حساب مرتبط'
            : 'No linked account',
      ),
    };
  }
}

/// Parent view: fetch `/student-reports/parent` which returns the list of
/// children with their latest report. Tapping a child opens their history.
class _ParentReportsView extends StatefulWidget {
  const _ParentReportsView();

  @override
  State<_ParentReportsView> createState() => _ParentReportsViewState();
}

class _ParentReportsViewState extends State<_ParentReportsView> {
  bool _loading = true;
  String? _error;
  List<dynamic> _children = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final session = context.read<SessionController>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final body = await session.api.get('/student-reports/parent');
      final data = body['data'];
      if (!mounted) return;
      setState(() {
        _children = data is List ? data : const [];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.failureFrom(error).message;
        _loading = false;
      });
    }
  }

  void _openChild(BuildContext context, Map<String, dynamic> child) {
    final id = _num(child['id']).toInt();
    if (id <= 0) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudentReportsScreen(
          studentId: id,
          studentName: _str(child['name']),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    if (_loading) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return SizedBox(
        height: 320,
        child: _ErrorCard(message: _error!, onRetry: _load),
      );
    }
    if (_children.isEmpty) {
      return SizedBox(
        height: 320,
        child: Center(
          child: NoDataWidget(
            icon: Icons.child_care_rounded,
            title: isArabic ? 'لا يوجد أبناء مرتبطون' : 'No linked children',
            message: isArabic
                ? 'عند ربط الأبناء ستظهر تقاريرهم الشهرية هنا.'
                : 'Linked children monthly reports will appear here.',
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderPanel(
          icon: Icons.assessment_rounded,
          title: isArabic ? 'تقارير أبنائي' : 'My children reports',
          subtitle: isArabic
              ? 'اضغط على أحد الأبناء لعرض سجل تقاريره'
              : 'Tap a child to open their report history',
          action: IconButton(
            onPressed: _load,
            tooltip: isArabic ? 'تحديث' : 'Refresh',
            icon: Icon(
              Icons.refresh_rounded,
              color: Colors.white.withValues(alpha: .9),
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final child in _children) ...[
          _ChildReportCard(
            child: _map(child),
            isArabic: isArabic,
            onTap: () => _openChild(context, _map(child)),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// History screen for a single student (used by the student self-view and
/// parent drill-down). When [showAppBar] is true it renders its own scaffold
/// because it was pushed as a route.
class StudentReportsScreen extends StatefulWidget {
  const StudentReportsScreen({
    super.key,
    required this.studentId,
    this.studentName,
    this.showAppBar = true,
  });

  final int studentId;
  final String? studentName;
  final bool showAppBar;

  @override
  State<StudentReportsScreen> createState() => _StudentReportsScreenState();
}

class _StudentReportsScreenState extends State<StudentReportsScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = const {};
  List<dynamic> _reports = const [];
  int _filterIndex = 0;

  String get _studentName {
    final fromField = widget.studentName?.trim().isNotEmpty == true
        ? widget.studentName!.trim()
        : '';
    if (fromField.isNotEmpty) return fromField;
    return _str(_map(_data['student'])['name']);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final session = context.read<SessionController>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final body = await session.api.get(
        '/student-reports/${widget.studentId}',
      );
      final data = body['data'];
      if (!mounted) return;
      setState(() {
        _data = data is Map ? Map<String, dynamic>.from(data) : const {};
        _reports = _list(_data['reports']);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.failureFrom(error).message;
        _loading = false;
      });
    }
  }

  void _openDetail(BuildContext context, Map<String, dynamic> report) {
    final month = _num(report['month']).toInt();
    final year = _num(report['year']).toInt();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MonthlyReportDetailScreen(
          studentId: widget.studentId,
          month: month,
          year: year,
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final isArabic = appIsArabic(context);
    if (_loading) {
      if (widget.showAppBar) {
        return RefreshablePage(
          onRefresh: _load,
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      if (widget.showAppBar) {
        return RefreshablePage(
          onRefresh: _load,
          child: _ErrorCard(message: _error!, onRetry: _load),
        );
      }
      return SizedBox(
        height: 320,
        child: _ErrorCard(message: _error!, onRetry: _load),
      );
    }
    if (_reports.isEmpty) {
      if (widget.showAppBar) {
        return RefreshablePage(
          onRefresh: _load,
          child: NoDataWidget(
            icon: Icons.assessment_rounded,
            title: isArabic ? 'لا توجد تقارير بعد' : 'No reports yet',
            message: isArabic
                ? 'تُنشأ التقارير الشهرية تلقائياً عند اكتمال بيانات الشهر.'
                : 'Monthly reports are generated automatically once the month data is ready.',
          ),
        );
      }
      return SizedBox(
        height: 320,
        child: Center(
          child: NoDataWidget(
            icon: Icons.assessment_rounded,
            title: isArabic ? 'لا توجد تقارير بعد' : 'No reports yet',
            message: isArabic
                ? 'تُنشأ التقارير الشهرية تلقائياً عند اكتمال بيانات الشهر.'
                : 'Monthly reports are generated automatically once the month data is ready.',
          ),
        ),
      );
    }

    final student = _map(_data['student']);
    final gradeLine = [
      _str(student['grade_name']),
      _str(student['classroom_name']),
      _str(student['section_name']),
    ].where((part) => part.isNotEmpty).join(' · ');

    final filterCounts = _reportFilterCounts(_reports);
    final visible = _filteredReports(_reports, _filterIndex);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReportsHero(
          studentName: _studentName,
          gradeLine: gradeLine,
          isArabic: isArabic,
        ),
        const SizedBox(height: 14),
        _ReportsSummaryGrid(reports: _reports, isArabic: isArabic),
        const SizedBox(height: 14),
        _ReportsFilterTabs(
          counts: filterCounts,
          selected: _filterIndex,
          isArabic: isArabic,
          onSelect: (index) => setState(() => _filterIndex = index),
        ),
        const SizedBox(height: 6),
        for (final report in visible) ...[
          _ReportCard(
            report: _map(report),
            isArabic: isArabic,
            onTap: () => _openDetail(context, _map(report)),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
    return widget.showAppBar
        ? RefreshablePage(onRefresh: _load, child: content)
        : content;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAppBar) return _content(context);
    final isArabic = appIsArabic(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _studentName.isEmpty
              ? (isArabic ? 'التقارير الشهرية' : 'Monthly Reports')
              : _studentName,
        ),
      ),
      body: _content(context),
    );
  }
}

/// Full monthly report detail pushed as its own route.
class MonthlyReportDetailScreen extends StatefulWidget {
  const MonthlyReportDetailScreen({
    super.key,
    required this.studentId,
    required this.month,
    required this.year,
    this.studentName,
  });

  final int studentId;
  final int month;
  final int year;
  final String? studentName;

  @override
  State<MonthlyReportDetailScreen> createState() =>
      _MonthlyReportDetailScreenState();
}

class _MonthlyReportDetailScreenState extends State<MonthlyReportDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _report = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final session = context.read<SessionController>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final body = await session.api.get(
        '/student-reports/${widget.studentId}/${widget.month}/${widget.year}',
      );
      final data = body['data'];
      if (!mounted) return;
      setState(() {
        _report = data is Map ? Map<String, dynamic>.from(data) : const {};
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.failureFrom(error).message;
        _loading = false;
      });
    }
  }

  Widget _body(BuildContext context) {
    final isArabic = appIsArabic(context);
    final report = _report;
    final monthName = _str(report['month_name']);
    final score = _num(report['progress_score']).toDouble();
    final trend = _str(report['trend']);
    final previous = report['previous_month_score'];
    final student = _map(report['student']);
    final studentName = widget.studentName?.trim().isNotEmpty == true
        ? widget.studentName!.trim()
        : _str(student['name']);
    final gradeLine = [
      _str(student['grade_name']),
      _str(student['classroom_name']),
      _str(student['section_name']),
    ].where((part) => part.isNotEmpty).join(' · ');

    final attendance = _map(report['attendance']);
    final total = _num(attendance['total_days']).toInt();
    final present = _num(attendance['present']).toInt();
    final absent = _num(attendance['absent']).toInt();
    final rate = _num(attendance['rate']).toDouble();

    final evaluations = _map(report['evaluations']);
    final evalTotal = _num(evaluations['total']).toInt();
    final evalAvg = _num(evaluations['average_level']).toDouble();
    final breakdown = _map(evaluations['breakdown']);
    final counts = _map(breakdown['counts']);
    final percentages = _map(breakdown['percentages']);

    final exams = _map(report['exams']);
    final examOverall = _num(exams['overall_percentage']).toDouble();
    final subjects = _list(exams['subjects']);

    final quizzes = _map(report['quizzes']);
    final quizTotal = _num(quizzes['total']).toInt();
    final quizAvg = _num(quizzes['average_percentage']).toDouble();

    final notes = _list(report['teacher_notes']);

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      backgroundColor: Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _DetailHeader(
            monthName: monthName,
            year: _num(report['year']).toInt(),
            studentName: studentName,
            gradeLine: gradeLine,
            score: score,
            trend: trend,
            previousScore: previous == null ? null : _num(previous).toDouble(),
            isArabic: isArabic,
          ),
          const SizedBox(height: 14),
          if (total > 0) ...[
            _TitledCard(
              icon: Icons.fact_check_rounded,
              title: isArabic ? 'المواظبة والحضور' : 'Attendance',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoRow(
                    label: isArabic ? 'أيام دوام' : 'School days',
                    value: '$total',
                  ),
                  _InfoRow(
                    label: isArabic ? 'أيام حضور' : 'Present days',
                    value: '$present',
                  ),
                  _InfoRow(
                    label: isArabic ? 'أيام غياب' : 'Absent days',
                    value: '$absent',
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (rate / 100).clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: AppTheme.borderColor.withValues(
                        alpha: .5,
                      ),
                      color: rate >= 85 ? AppTheme.mint : AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${isArabic ? 'نسبة الحضور' : 'Attendance rate'}: ${rate.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (evalTotal > 0) ...[
            _TitledCard(
              icon: Icons.star_rounded,
              title: isArabic ? 'تقييمات المعلمين' : 'Teacher evaluations',
              trailing: Text(
                '${evalAvg.toStringAsFixed(2)} / 4',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              child: Column(
                children: [
                  for (final level in _evaluationLevels)
                    _BreakdownBar(
                      label: isArabic ? level[1] : level[2],
                      color: _levelColor(level[0]),
                      value: _num(percentages[level[0]]).toDouble() / 100,
                      trailing:
                          '${_num(counts[level[0]]).toInt()} · ${_num(percentages[level[0]]).toStringAsFixed(0)}%',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (subjects.isNotEmpty) ...[
            _TitledCard(
              icon: Icons.assignment_rounded,
              title: isArabic ? 'الاختبارات الورقية' : 'Paper exams',
              trailing: Text(
                '${examOverall.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              child: Column(
                children: [
                  for (final subject in subjects)
                    _ProgressRow(
                      label: _mapItem(subject, 'subject_name'),
                      value: _num(subject['percentage']).toDouble() / 100,
                      trailing:
                          '${_num(subject['avg_score']).toStringAsFixed(1)}/${_num(subject['max_score']).toStringAsFixed(0)}',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (quizTotal > 0) ...[
            _TitledCard(
              icon: Icons.quiz_rounded,
              title: isArabic ? 'الاختبارات القصيرة' : 'Quizzes',
              trailing: Text(
                '${quizAvg.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    label: isArabic ? 'عدد الاختبارات' : 'Quizzes taken',
                    value: '$quizTotal',
                  ),
                  _InfoRow(
                    label: isArabic ? 'متوسط النتيجة' : 'Average score',
                    value: '${quizAvg.toStringAsFixed(1)}%',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (notes.isNotEmpty) ...[
            _TitledCard(
              icon: Icons.edit_note_rounded,
              title: isArabic ? 'ملاحظات المعلمين' : 'Teacher notes',
              child: Column(
                children: [
                  for (final note in notes)
                    _NoteTile(
                      subject: _mapItem(note, 'subject'),
                      level: _mapItem(note, 'level'),
                      text: _mapItem(note, 'notes'),
                      isArabic: isArabic,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    final monthName = _str(_report['month_name']);
    final title = monthName.isNotEmpty
        ? monthName
        : (isArabic ? 'التقرير الشهري' : 'Monthly report');
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? RefreshablePage(
              onRefresh: _load,
              child: _ErrorCard(message: _error!, onRetry: _load),
            )
          : _body(context),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.monthName,
    required this.year,
    required this.studentName,
    required this.gradeLine,
    required this.score,
    required this.trend,
    required this.previousScore,
    required this.isArabic,
  });

  final String monthName;
  final int year;
  final String studentName;
  final String gradeLine;
  final double score;
  final String trend;
  final double? previousScore;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.softPanel(
        gradient: AppTheme.heroGradient,
        radius: 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$monthName $year',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_trendIcon(trend), size: 15, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      _trendLabel(trend, isArabic),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .75),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    score.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
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
                      studentName.isEmpty ? '—' : studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (gradeLine.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        gradeLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .78),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      previousScore == null
                          ? (isArabic
                                ? 'النتيجة الكلية للتقدم'
                                : 'Overall progress score')
                          : '${isArabic ? 'الشهر السابق' : 'Previous month'}: ${previousScore!.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .85),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 44,
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
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildReportCard extends StatelessWidget {
  const _ChildReportCard({
    required this.child,
    required this.isArabic,
    required this.onTap,
  });

  final Map<String, dynamic> child;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = [
      _str(child['grade_name']),
      _str(child['classroom_name']),
      _str(child['section_name']),
    ].where((part) => part.isNotEmpty).join(' · ');
    final latest = _map(child['latest_report']);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0xFF1E3C72), Color(0xFF2A52BE)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _str(child['name']).isEmpty ? '—' : _str(child['name']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (info.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        info,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (latest.isEmpty)
                      Text(
                        isArabic ? 'لا توجد تقارير بعد' : 'No reports yet',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _MiniChip(
                            icon: Icons.calendar_month_rounded,
                            text: _str(latest['month_name']),
                          ),
                          _MiniChip(
                            icon: Icons.speed_rounded,
                            text:
                                '${_num(latest['progress_score']).toStringAsFixed(0)}%',
                          ),
                          _MiniChip(
                            icon: _trendIcon(_str(latest['trend'])),
                            text: _trendLabel(_str(latest['trend']), isArabic),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsHero extends StatelessWidget {
  const _ReportsHero({
    required this.studentName,
    required this.gradeLine,
    required this.isArabic,
  });

  final String studentName;
  final String gradeLine;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.softPanel(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A52BE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        radius: 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: AppTheme.honey,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'التقارير الشهرية' : 'Monthly Reports',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isArabic
                          ? 'متابعة أداء الطالب شهراً بشهر'
                          : 'Track the student performance month by month',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .82),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName.isEmpty ? '—' : studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (gradeLine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        gradeLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .78),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportsSummaryGrid extends StatelessWidget {
  const _ReportsSummaryGrid({required this.reports, required this.isArabic});

  final List<dynamic> reports;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    var total = 0;
    var improved = 0;
    var declined = 0;
    var sumProgress = 0.0;
    var best = 0.0;
    var attCount = 0;
    var sumAttendance = 0.0;
    var examCount = 0;
    var sumExams = 0.0;
    var quizCount = 0;
    var sumQuizzes = 0.0;

    for (final raw in reports) {
      final report = _map(raw);
      total++;
      final progress = _num(report['progress_score']).toDouble();
      sumProgress += progress;
      if (progress > best) best = progress;
      switch (_str(report['trend'])) {
        case 'improved':
          improved++;
        case 'declined':
          declined++;
      }
      final attendance = _map(report['attendance']);
      if (_num(attendance['total_days']).toInt() > 0) {
        attCount++;
        sumAttendance += _num(attendance['rate']).toDouble();
      }
      final exams = _map(report['exams']);
      final examOverall = _num(exams['overall_percentage']).toDouble();
      if (examOverall > 0) {
        examCount++;
        sumExams += examOverall;
      }
      final quizzes = _map(report['quizzes']);
      final quizTotal = _num(quizzes['total']).toInt();
      if (quizTotal > 0) {
        quizCount++;
        sumQuizzes += _num(quizzes['average_percentage']).toDouble();
      }
    }

    final avg = total > 0 ? sumProgress / total : 0.0;

    final tiles = <_SummaryData>[
      _SummaryData(
        Icons.calendar_month_rounded,
        const Color(0xFF00897B),
        '$total',
        isArabic ? 'التقارير' : 'Reports',
      ),
      _SummaryData(
        Icons.speed_rounded,
        const Color(0xFF43A047),
        '${avg.round()}',
        isArabic ? 'المتوسط' : 'Average',
      ),
      _SummaryData(
        Icons.star_rounded,
        const Color(0xFF1E88E5),
        '${best.round()}',
        isArabic ? 'الأعلى' : 'Best',
      ),
      _SummaryData(
        Icons.fact_check_rounded,
        const Color(0xFF1E3C72),
        '${attCount > 0 ? sumAttendance / attCount : 0}'.split('.')[0],
        isArabic ? 'الحضور' : 'Attendance',
      ),
      _SummaryData(
        Icons.assignment_rounded,
        const Color(0xFFF4511E),
        '${examCount > 0 ? sumExams / examCount : 0}'.split('.')[0],
        isArabic ? 'الاختبارات' : 'Exams',
      ),
      _SummaryData(
        Icons.quiz_rounded,
        const Color(0xFFFFB300),
        '${quizCount > 0 ? sumQuizzes / quizCount : 0}'.split('.')[0],
        isArabic ? 'الكويزات' : 'Quizzes',
      ),
      _SummaryData(
        Icons.trending_up_rounded,
        const Color(0xFF43A047),
        '$improved',
        isArabic ? 'تحسّن' : 'Improved',
      ),
      _SummaryData(
        Icons.trending_down_rounded,
        const Color(0xFFE53935),
        '$declined',
        isArabic ? 'تراجع' : 'Declined',
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        for (final tile in tiles) _SummaryTile(data: tile),
      ],
    );
  }
}

class _SummaryData {
  const _SummaryData(this.icon, this.color, this.value, this.label);

  final IconData icon;
  final Color color;
  final String value;
  final String label;
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.data});

  final _SummaryData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, color: data.color, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              data.value,
              style: const TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.muted, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsFilterTabs extends StatelessWidget {
  const _ReportsFilterTabs({
    required this.counts,
    required this.selected,
    required this.isArabic,
    required this.onSelect,
  });

  final List<int> counts;
  final int selected;
  final bool isArabic;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final labels = isArabic
        ? const <String>['الكل', 'تحسّن', 'تراجع', 'مستقر']
        : const <String>['All', 'Improved', 'Declined', 'Stable'];

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected == i ? AppTheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          labels[i],
                          style: TextStyle(
                            color: selected == i ? Colors.white : AppTheme.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${counts[i]}',
                          style: TextStyle(
                            color: selected == i
                                ? Colors.white.withValues(alpha: .8)
                                : AppTheme.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.isArabic,
    required this.onTap,
  });

  final Map<String, dynamic> report;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final monthName = _str(report['month_name']);
    final year = _num(report['year']).toInt();
    final score = _num(report['progress_score']).toDouble();
    final trend = _str(report['trend']);
    final attendance = _map(report['attendance']);
    final exams = _map(report['exams']);
    final quizzes = _map(report['quizzes']);
    final total = _num(attendance['total_days']).toInt();
    final rate = _num(attendance['rate']).toDouble();
    final examOverall = _num(exams['overall_percentage']).toDouble();
    final quizTotal = _num(quizzes['total']).toInt();
    final quizAvg = _num(quizzes['average_percentage']).toDouble();

    final parts = <String>[
      if (total > 0)
        '${isArabic ? 'حضور' : 'Attendance'} ${rate.toStringAsFixed(0)}%',
      if (examOverall > 0)
        '${isArabic ? 'اختبارات' : 'Exams'} ${examOverall.toStringAsFixed(0)}%',
      if (quizTotal > 0)
        '${isArabic ? 'كويزات' : 'Quizzes'} ${quizAvg.toStringAsFixed(0)}%',
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthName.isEmpty ? '$year' : '$monthName $year',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _TrendPill(
                          trend: trend,
                          isArabic: isArabic,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${score.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: AppTheme.honey,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isArabic ? 'نسبة التقدم' : 'Progress',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: parts.isEmpty
                        ? Text(
                            isArabic
                                ? 'لا توجد بيانات هذا الشهر'
                                : 'No data this month',
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 12,
                            ),
                          )
                        : Text(
                            parts.join('  ·  '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: BorderSide(
                        color: AppTheme.primary.withValues(alpha: .4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 36),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.visibility_rounded, size: 16),
                    label: Text(
                      isArabic ? 'عرض التقرير' : 'View',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
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

class _TitledCard extends StatelessWidget {
  const _TitledCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SoftIcon(icon: icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF1E3C72), Color(0xFF2A52BE)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3C72).withValues(alpha: .3),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: AppTheme.honey,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: .86)),
                ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppTheme.primary, size: 22),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({
    required this.trend,
    required this.isArabic,
    this.compact = false,
  });

  final String trend;
  final bool isArabic;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = _trendColor(trend);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_trendIcon(trend), size: compact ? 13 : 16, color: color),
          SizedBox(width: compact ? 3 : 5),
          Text(
            _trendLabel(trend, isArabic),
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _BreakdownBar extends StatelessWidget {
  const _BreakdownBar({
    required this.label,
    required this.value,
    required this.trailing,
    required this.color,
  });

  final String label;
  final double value;
  final String trailing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                trailing,
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              minHeight: 6,
              backgroundColor: AppTheme.borderColor.withValues(alpha: .5),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.trailing,
  });

  final String label;
  final double value;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: value.clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: AppTheme.borderColor.withValues(alpha: .5),
                    color: AppTheme.mint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            trailing,
            style: const TextStyle(
              color: AppTheme.muted,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({
    required this.subject,
    required this.level,
    required this.text,
    required this.isArabic,
  });

  final String subject;
  final String level;
  final String text;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColor(level);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject.isEmpty ? '—' : subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Text(
                  _levelLabel(level, isArabic),
                  style: TextStyle(
                    color: levelColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

const _evaluationLevels = <List<String>>[
  ['bad', 'ضعيف', 'Bad'],
  ['good', 'جيد', 'Good'],
  ['very_good', 'جيد جداً', 'Very good'],
  ['excellent', 'ممتاز', 'Excellent'],
];

String _levelLabel(String key, bool isArabic) {
  return switch (key) {
    'excellent' => isArabic ? 'ممتاز' : 'Excellent',
    'very_good' => isArabic ? 'جيد جداً' : 'Very good',
    'good' => isArabic ? 'جيد' : 'Good',
    _ => isArabic ? 'ضعيف' : 'Bad',
  };
}

Color _levelColor(String key) {
  return switch (key) {
    'excellent' => AppTheme.mint,
    'very_good' => AppTheme.primary,
    'good' => AppTheme.purple,
    _ => AppTheme.coral,
  };
}

String _trendLabel(String trend, bool isArabic) {
  return switch (trend) {
    'improved' => isArabic ? 'تحسّن' : 'Improved',
    'declined' => isArabic ? 'تراجع' : 'Declined',
    'stable' => isArabic ? 'مستقر' : 'Stable',
    'new' => isArabic ? 'جديد' : 'New',
    _ => trend,
  };
}

IconData _trendIcon(String trend) {
  return switch (trend) {
    'improved' => Icons.trending_up_rounded,
    'declined' => Icons.trending_down_rounded,
    'stable' => Icons.trending_flat_rounded,
    'new' => Icons.fiber_new_rounded,
    _ => Icons.timelapse_rounded,
  };
}

Color _trendColor(String trend) {
  return switch (trend) {
    'improved' => AppTheme.mint,
    'declined' => AppTheme.coral,
    'stable' => AppTheme.primary,
    'new' => AppTheme.purple,
    _ => AppTheme.muted,
  };
}

List<int> _reportFilterCounts(List<dynamic> reports) {
  var total = 0;
  var improved = 0;
  var declined = 0;
  var stable = 0;
  for (final raw in reports) {
    total++;
    switch (_str(_map(raw)['trend'])) {
      case 'improved':
        improved++;
      case 'declined':
        declined++;
      case 'stable':
        stable++;
    }
  }
  return [total, improved, declined, stable];
}

List<dynamic> _filteredReports(List<dynamic> reports, int index) {
  if (index <= 0) return reports;
  final key = switch (index) {
    1 => 'improved',
    2 => 'declined',
    3 => 'stable',
    _ => '',
  };
  return reports
      .where((raw) => _str(_map(raw)['trend']) == key)
      .toList();
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

List<dynamic> _list(dynamic value) => value is List ? value : const [];

num _num(dynamic value) {
  if (value is num) return value;
  final parsed = num.tryParse(value == null ? '' : '$value');
  return parsed ?? 0;
}

String _str(dynamic value) => value == null ? '' : '$value';

String _mapItem(dynamic item, String key) {
  if (item is! Map) return '';
  return _str(item[key]);
}
