import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/data/school_modules.dart';
import '../../core/localization/module_localization.dart';
import '../../core/models/app_models.dart';
import '../../core/network/api_service.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/living_icons.dart';
import '../../core/widgets/refreshable_content.dart';

/// Shared shell that fetches a role dashboard endpoint and renders the
/// role-specific [builder] once data arrives. Mirrors `ScheduleScreen`:
/// loading/error states use [RefreshablePage] and the data uses
/// pull-to-refresh via [onRefresh].
class RoleDashboard extends StatefulWidget {
  const RoleDashboard({
    super.key,
    required this.endpoint,
    required this.builder,
  });

  final String endpoint;
  final Widget Function(
    BuildContext context,
    Map<String, dynamic> data,
    Future<void> Function() onRefresh,
  )
  builder;

  @override
  State<RoleDashboard> createState() => _RoleDashboardState();
}

class _RoleDashboardState extends State<RoleDashboard> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final api = context.read<SessionController>().api;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final body = await api.get(widget.endpoint);
      final data = body['data'];
      if (!mounted) return;
      setState(() {
        _data = data is Map ? Map<String, dynamic>.from(data) : const {};
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

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    if (_loading) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return SizedBox(
        height: 320,
        child: Center(
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
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widget.builder(context, _data ?? const {}, _load);
  }
}

/// Student dashboard: today's schedule, attendance, grades, upcoming exams.
Widget studentDashboardBuilder(
  BuildContext context,
  Map<String, dynamic> data,
  Future<void> Function() onRefresh,
) {
  final isArabic = appIsArabic(context);
  final student = _map(data['student']);
  final today = _map(data['today']);
  final attendance = _map(data['attendance']);
  final grades = _map(data['grades']);
  final exams = _list(data['upcoming_exams']);
  final evaluations = _list(data['recent_evaluations']);
  final notifications = _map(data['notifications']);
  final schedule = _list(today['schedule']);
  final weekSchedule = _list(data['week_schedule']);
  final materials = _list(data['learning_materials']);
  final subjects = _list(grades['subjects']);

  final studentName = _str(student['name']);
  final sectionName = _str(student['section_name']);
  final gradeName = _str(student['grade_name']);
  final classroomName = _str(student['classroom_name']);
  final todayDay = _num(today['day_of_week']).toInt();
  final stageInfo = [
    if (gradeName.isNotEmpty) gradeName,
    if (classroomName.isNotEmpty) classroomName,
    if (sectionName.isNotEmpty) sectionName,
  ].join(' · ');

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _StudentHero(
        isArabic: isArabic,
        studentName: studentName,
        stageInfo: stageInfo,
      ),
      const SizedBox(height: 16),
      _AttendanceGrid(
        presentRate: _num(attendance['present_rate']).toInt(),
        present: _num(attendance['present']).toInt(),
        absent: _num(attendance['absent']).toInt(),
        totalDays: _num(attendance['total_days']).toInt(),
        isArabic: isArabic,
      ),
      const SizedBox(height: 16),
      _TitledCard(
        icon: Icons.watch_later_rounded,
        title: isArabic
            ? 'حصص اليوم (${_str(today['day_name'])})'
            : "Today's lessons (${_str(today['day_name'])})",
        child: schedule.isEmpty
            ? _TodayEmptyState(isWeekend: todayDay >= 5, isArabic: isArabic)
            : Column(
                children: [
                  for (var i = 0; i < schedule.length; i++) ...[
                    _PeriodTile(
                      startTime: _mapItem(schedule[i], 'start_time'),
                      endTime: _mapItem(schedule[i], 'end_time'),
                      title: _mapItem(schedule[i], 'subject_name'),
                      metas: [
                        if (_mapItem(schedule[i], 'teacher_name').isNotEmpty)
                          _Meta(
                            icon: Icons.person_rounded,
                            label: _mapItem(schedule[i], 'teacher_name'),
                          ),
                      ],
                    ),
                    if (i != schedule.length - 1)
                      const Divider(height: 1, indent: 2, endIndent: 2),
                  ],
                ],
              ),
      ),
      const SizedBox(height: 12),
      _WeeklyProgramCard(
        sessions: weekSchedule,
        todayDay: todayDay,
        isArabic: isArabic,
      ),
      const SizedBox(height: 12),
      _TitledCard(
        icon: Icons.grade_rounded,
        title: isArabic ? 'درجاتي' : 'My grades',
        trailing: subjects.isEmpty
            ? null
            : Text(
                '${_num(grades['overall_percentage']).toInt()}%',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
        child: subjects.isEmpty
            ? NoDataWidget(
                compact: true,
                icon: Icons.assessment_rounded,
                title: isArabic ? 'لا توجد درجات بعد' : 'No grades yet',
              )
            : Column(
                children: [
                  for (final subject in subjects)
                    _ProgressRow(
                      label: _mapItem(subject, 'subject_name'),
                      value: _num(subject['percentage']).toDouble() / 100,
                      trailing:
                          '${_num(subject['avg_score']).toStringAsFixed(0)}/${_num(subject['max_score']).toStringAsFixed(0)}',
                    ),
                ],
              ),
      ),
      if (exams.isNotEmpty) ...[
        const SizedBox(height: 12),
        _TitledCard(
          icon: Icons.assignment_rounded,
          title: isArabic ? 'الاختبارات القادمة' : 'Upcoming exams',
          child: Column(
            children: [
              for (var i = 0; i < exams.length; i++) ...[
                _LineItem(
                  icon: Icons.event_rounded,
                  title: _mapItem(exams[i], 'title'),
                  subtitle: [
                    if (_mapItem(exams[i], 'subject_name').isNotEmpty)
                      _mapItem(exams[i], 'subject_name'),
                    if (_mapItem(exams[i], 'exam_date').isNotEmpty)
                      _mapItem(exams[i], 'exam_date'),
                  ].join('  ·  '),
                ),
                if (i != exams.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
      if (evaluations.isNotEmpty) ...[
        const SizedBox(height: 12),
        _TitledCard(
          icon: Icons.star_rounded,
          title: isArabic ? 'آخر التقييمات' : 'Recent evaluations',
          child: Column(
            children: [
              for (final evaluation in evaluations)
                _LineItem(
                  icon: Icons.person_outline_rounded,
                  title: _mapItem(evaluation, 'subject'),
                  subtitle:
                      '${_mapItem(evaluation, 'level')} · ${_monthLabel(_num(evaluation['month']).toInt(), _num(evaluation['year']).toInt(), isArabic)}',
                ),
            ],
          ),
        ),
      ],
      if (materials.isNotEmpty) ...[
        const SizedBox(height: 12),
        _TitledCard(
          icon: Icons.menu_book_rounded,
          title: isArabic ? 'المواد التعليمية' : 'Learning materials',
          child: Column(
            children: [
              for (var i = 0; i < materials.length; i++) ...[
                _LineItem(
                  icon: Icons.description_rounded,
                  title: _mapItem(materials[i], 'title'),
                  subtitle: [
                    if (_mapItem(materials[i], 'file_name').isNotEmpty)
                      _mapItem(materials[i], 'file_name'),
                    if (_mapItem(materials[i], 'teacher_name').isNotEmpty)
                      _mapItem(materials[i], 'teacher_name'),
                  ].join('  ·  '),
                ),
                if (i != materials.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
      _NotificationsCard(
        notifications: _list(notifications['recent']),
        isArabic: isArabic,
      ),
    ],
  );
}

class _StudentHero extends StatelessWidget {
  const _StudentHero({
    required this.isArabic,
    required this.studentName,
    required this.stageInfo,
  });

  final bool isArabic;
  final String studentName;
  final String stageInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff6CB8FF),
            Color(0xff2E86FF),
            Color(0xff6A5AE0),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff2E86FF).withValues(alpha: .3),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: _HeroBlob(
              size: 130,
              color: Colors.white.withValues(alpha: .08),
            ),
          ),
          Positioned(
            left: -18,
            bottom: -42,
            child: _HeroBlob(
              size: 120,
              color: Colors.white.withValues(alpha: .06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _AcademicYearChip(isArabic: isArabic),
                  const Spacer(),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                isArabic
                    ? 'مرحباً بعودتك${studentName.isNotEmpty ? '، $studentName' : ''}'
                    : 'Welcome back${studentName.isNotEmpty ? ', $studentName' : ''}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
              if (stageInfo.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  stageInfo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .88),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBlob extends StatelessWidget {
  const _HeroBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _AcademicYearChip extends StatelessWidget {
  const _AcademicYearChip({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: .3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulsingDot(color: Colors.white, size: 7),
          const SizedBox(width: 8),
          Text(
            isArabic
                ? 'العام الدراسي ${_schoolYearLabel()}'
                : 'Academic year ${_schoolYearLabel()}',
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({this.color = Colors.white, this.size = 8});

  final Color color;
  final double size;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.7, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size * 2,
          height: widget.size * 2,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: .25),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Transform.scale(
              scale: _scale.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AttendanceGrid extends StatelessWidget {
  const _AttendanceGrid({
    required this.presentRate,
    required this.present,
    required this.absent,
    required this.totalDays,
    required this.isArabic,
  });

  final int presentRate;
  final int present;
  final int absent;
  final int totalDays;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AttendanceTile(
                icon: Icons.fact_check_rounded,
                value: '$presentRate%',
                label: isArabic ? 'نسبة الحضور' : 'Attendance rate',
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AttendanceTile(
                icon: Icons.check_circle_rounded,
                value: '$present',
                label: isArabic ? 'حضور' : 'Present',
                color: AppTheme.mint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AttendanceTile(
                icon: Icons.cancel_rounded,
                value: '$absent',
                label: isArabic ? 'غياب' : 'Absent',
                color: AppTheme.coral,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AttendanceTile(
                icon: Icons.calendar_today_rounded,
                value: '$totalDays',
                label: isArabic ? 'أيام إجمالاً' : 'Total days',
                color: AppTheme.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowTint.withValues(alpha: .06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TodayEmptyState extends StatelessWidget {
  const _TodayEmptyState({required this.isWeekend, required this.isArabic});

  final bool isWeekend;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: isWeekend ? AppTheme.cloud : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            isWeekend
                ? Icons.beach_access_rounded
                : Icons.event_busy_rounded,
            size: 40,
            color: isWeekend ? AppTheme.primaryLight : AppTheme.muted,
          ),
          const SizedBox(height: 8),
          Text(
            isWeekend
                ? (isArabic ? 'يوم عطلة نهاية الأسبوع' : 'Weekend day')
                : (isArabic ? 'لا توجد حصص اليوم' : 'No lessons today'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          if (isWeekend) ...[
            const SizedBox(height: 4),
            Text(
              isArabic
                  ? 'استريح وقم بتجهيز نفسك للأسبوع القادم'
                  : 'Rest and get ready for the coming week',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyProgramCard extends StatefulWidget {
  const _WeeklyProgramCard({
    required this.sessions,
    required this.todayDay,
    required this.isArabic,
  });

  final List<dynamic> sessions;
  final int todayDay;
  final bool isArabic;

  @override
  State<_WeeklyProgramCard> createState() => _WeeklyProgramCardState();
}

class _WeeklyProgramCardState extends State<_WeeklyProgramCard> {
  static const _workdays = <int>[0, 1, 2, 3, 4];

  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _workdays.contains(widget.todayDay)
        ? widget.todayDay
        : _workdays.first;
  }

  Map<int, List<dynamic>> get _byDay {
    final map = <int, List<dynamic>>{};
    for (final session in widget.sessions) {
      final day = _num(session['day_of_week']).toInt();
      map.putIfAbsent(day, () => []).add(session);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _byDay[_selectedDay] ?? const [];
    return _TitledCard(
      icon: Icons.calendar_month_rounded,
      title: widget.isArabic ? 'برنامجي الأسبوعي' : 'My weekly schedule',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _workdays.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final day = _workdays[index];
                final selected = day == _selectedDay;
                return _DayPill(
                  label: _dayLabel(widget.isArabic, day),
                  selected: selected,
                  onTap: () => setState(() => _selectedDay = day),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (sessions.isEmpty)
            NoDataWidget(
              compact: true,
              icon: Icons.event_busy_rounded,
              title: widget.isArabic
                  ? 'لا توجد حصص في هذا اليوم'
                  : 'No lessons on this day',
            )
          else
            for (var i = 0; i < sessions.length; i++) ...[
              _ScheduleTile(session: sessions[i], isArabic: widget.isArabic),
              if (i != sessions.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.borderColor,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: .24),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.ink,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.session, required this.isArabic});

  final dynamic session;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final subject = _mapItem(session, 'subject_name');
    final teacher = _mapItem(session, 'teacher_name');
    final location = _mapItem(session, 'location');
    final start = _mapItem(session, 'start_time');
    final end = _mapItem(session, 'end_time');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: .5)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.ctaGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.isEmpty ? '—' : subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    if (teacher.isNotEmpty)
                      _ScheduleMeta(
                        icon: Icons.person_rounded,
                        label: teacher,
                      ),
                    if (location.isNotEmpty)
                      _ScheduleMeta(
                        icon: Icons.meeting_room_rounded,
                        label: isArabic ? 'قاعة $location' : 'Room $location',
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                start,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
              ),
              Text(
                end,
                style: const TextStyle(color: AppTheme.muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleMeta extends StatelessWidget {
  const _ScheduleMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.muted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
      ],
    );
  }
}

String _schoolYearLabel() {
  final now = DateTime.now();
  final start = now.month >= 9 ? now.year : now.year - 1;
  return '$start/${start + 1}';
}

String _dayLabel(bool isArabic, int day) {
  const ar = <String>[
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];
  const en = <String>[
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  if (day < 0 || day > 6) return '';
  return isArabic ? ar[day] : en[day];
}

/// Teacher dashboard: hero welcome, workload stats, today's classes,
/// weekly availability, sections, evaluations and notifications.
Widget teacherDashboardBuilder(
  BuildContext context,
  Map<String, dynamic> data,
  Future<void> Function() onRefresh,
) {
  final isArabic = appIsArabic(context);
  final teacher = _map(data['teacher']);
  final today = _map(data['today']);
  final workload = _map(data['workload']);
  final attendance = _map(data['attendance_30d']);
  final sections = _list(data['sections']);
  final evaluations = _list(data['recent_evaluations']);
  final notifications = _map(data['notifications']);
  final classes = _list(today['classes']);
  final availability = _list(data['availability'])
      .where((slot) => _map(slot)['is_available'] != false)
      .toList();
  final preference = _map(data['preference']);
  final hasPrefWindow =
      _str(preference['preferred_start_time']).isNotEmpty ||
          _str(preference['preferred_end_time']).isNotEmpty;

  final sectionGroups = <MapEntry<String, List<Map<String, dynamic>>>>[];
  final sectionGroupIndex = <String, int>{};
  for (final section in sections) {
    final name = _map(section);
    final key =
        '${_str(name['grade_name'])}\u0001${_str(name['classroom_name'])}';
    final index = sectionGroupIndex[key];
    if (index == null) {
      sectionGroupIndex[key] = sectionGroups.length;
      sectionGroups.add(MapEntry(key, [name]));
    } else {
      sectionGroups[index].value.add(name);
    }
  }

  final teacherName = _str(teacher['name']);
  final specialization = _str(teacher['specialization']);
  final present = _num(attendance['present']).toInt();
  final absent = _num(attendance['absent']).toInt();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _TeacherHero(
        isArabic: isArabic,
        teacherName: teacherName,
        specialization: specialization,
      ),
      const SizedBox(height: 16),
      _TeacherStatsGrid(
        studentsCount: _num(data['students_count']).toInt(),
        totalPeriods: _num(workload['total_periods']).toInt(),
        present: present,
        absent: absent,
        isArabic: isArabic,
      ),
      const SizedBox(height: 16),
      _TitledCard(
        icon: Icons.watch_later_rounded,
        title: isArabic
            ? 'حصص اليوم (${_str(today['day_name'])})'
            : "Today's classes (${_str(today['day_name'])})",
        child: classes.isEmpty
            ? _TodayEmptyState(
                isWeekend: _num(today['day_of_week']).toInt() >= 5,
                isArabic: isArabic,
              )
            : Column(
                children: [
                  for (var i = 0; i < classes.length; i++) ...[
                    _PeriodTile(
                      startTime: _mapItem(classes[i], 'start_time'),
                      endTime: _mapItem(classes[i], 'end_time'),
                      title: _mapItem(classes[i], 'subject_name'),
                      metas: [
                        if (_mapItem(classes[i], 'grade_name').isNotEmpty)
                          _Meta(
                            icon: Icons.school_rounded,
                            label: _mapItem(classes[i], 'grade_name'),
                          ),
                        if (_mapItem(classes[i], 'section_name').isNotEmpty)
                          _Meta(
                            icon: Icons.groups_rounded,
                            label: _mapItem(classes[i], 'section_name'),
                          ),
                        if (_mapItem(classes[i], 'classroom_name').isNotEmpty)
                          _Meta(
                            icon: Icons.meeting_room_rounded,
                            label: _mapItem(classes[i], 'classroom_name'),
                          ),
                        if (_mapItem(classes[i], 'location').isNotEmpty)
                          _Meta(
                            icon: Icons.place_outlined,
                            label: _mapItem(classes[i], 'location'),
                          ),
                      ],
                    ),
                    if (i != classes.length - 1)
                      const Divider(height: 1, indent: 2, endIndent: 2),
                  ],
                ],
              ),
      ),
      if (availability.isNotEmpty || hasPrefWindow) ...[
        const SizedBox(height: 12),
        _TeacherAvailabilityCard(
          availability: availability,
          preference: preference,
          todayDay: _num(today['day_of_week']).toInt(),
          isArabic: isArabic,
        ),
      ],
      if (sectionGroups.isNotEmpty) ...[
        const SizedBox(height: 12),
        _TitledCard(
          icon: Icons.groups_rounded,
          title: isArabic ? 'أقسامك' : 'Your sections',
          child: Column(
            children: [
              for (var i = 0; i < sectionGroups.length; i++) ...[
                _LineItem(
                  icon: Icons.meeting_room_rounded,
                  title: sectionGroups[i].key
                      .split('\u0001')
                      .where((part) => part.isNotEmpty && part != '—')
                      .join(' · '),
                  subtitle:
                      '${isArabic ? 'أقسام: ' : 'Sections: '}${sectionGroups[i].value.map((s) => _str(s['name'])).where((n) => n.isNotEmpty).join(' · ')}',
                  trailing:
                      '${sectionGroups[i].value.fold<int>(0, (sum, s) => sum + _num(s['students_count']).toInt())} ${isArabic ? 'طالب' : 'students'}',
                ),
                if (i != sectionGroups.length - 1)
                  const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
      if (evaluations.isNotEmpty) ...[
        const SizedBox(height: 12),
        _TitledCard(
          icon: Icons.star_rounded,
          title: isArabic ? 'آخر التقييمات' : 'Recent evaluations',
          child: Column(
            children: [
              for (final evaluation in evaluations)
                _LineItem(
                  icon: Icons.person_outline_rounded,
                  title: _mapItem(evaluation, 'student'),
                  subtitle:
                      '${_mapItem(evaluation, 'subject')} · ${_mapItem(evaluation, 'level')} · ${_monthLabel(_num(evaluation['month']).toInt(), _num(evaluation['year']).toInt(), isArabic)}',
                ),
            ],
          ),
        ),
      ],
      _NotificationsCard(
        notifications: _list(notifications['recent']),
        isArabic: isArabic,
      ),
    ],
  );
}

class _TeacherHero extends StatelessWidget {
  const _TeacherHero({
    required this.isArabic,
    required this.teacherName,
    required this.specialization,
  });

  final bool isArabic;
  final String teacherName;
  final String specialization;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
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
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: _HeroBlob(
              size: 130,
              color: Colors.white.withValues(alpha: .08),
            ),
          ),
          Positioned(
            left: -18,
            bottom: -42,
            child: _HeroBlob(
              size: 120,
              color: Colors.white.withValues(alpha: .06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _AcademicYearChip(isArabic: isArabic),
                  const Spacer(),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.badge_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                isArabic
                    ? 'مرحباً أيها المعلم${teacherName.isNotEmpty ? '، $teacherName' : ''}'
                    : 'Welcome${teacherName.isNotEmpty ? ', $teacherName' : ''}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
              if (specialization.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  specialization,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .88),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TeacherStatsGrid extends StatelessWidget {
  const _TeacherStatsGrid({
    required this.studentsCount,
    required this.totalPeriods,
    required this.present,
    required this.absent,
    required this.isArabic,
  });

  final int studentsCount;
  final int totalPeriods;
  final int present;
  final int absent;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AttendanceTile(
                icon: Icons.school_rounded,
                value: '$studentsCount',
                label: isArabic ? 'طلابك' : 'Your students',
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AttendanceTile(
                icon: Icons.timeline_rounded,
                value: '$totalPeriods',
                label: isArabic ? 'حصص أسبوعياً' : 'Weekly periods',
                color: AppTheme.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AttendanceTile(
                icon: Icons.fact_check_rounded,
                value: '$present',
                label: isArabic ? 'حضور (30 يوم)' : 'Present (30d)',
                color: AppTheme.mint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AttendanceTile(
                icon: Icons.cancel_rounded,
                value: '$absent',
                label: isArabic ? 'غياب (30 يوم)' : 'Absent (30d)',
                color: AppTheme.coral,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TeacherAvailabilityCard extends StatefulWidget {
  const _TeacherAvailabilityCard({
    required this.availability,
    required this.preference,
    required this.todayDay,
    required this.isArabic,
  });

  final List<dynamic> availability;
  final Map<String, dynamic> preference;
  final int todayDay;
  final bool isArabic;

  @override
  State<_TeacherAvailabilityCard> createState() =>
      _TeacherAvailabilityCardState();
}

class _TeacherAvailabilityCardState extends State<_TeacherAvailabilityCard> {
  static const _workdays = <int>[0, 1, 2, 3, 4];

  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _workdays.contains(widget.todayDay)
        ? widget.todayDay
        : _workdays.first;
  }

  Map<int, List<dynamic>> get _byDay {
    final map = <int, List<dynamic>>{};
    for (final slot in widget.availability) {
      final day = _num(_map(slot)['day_of_week']).toInt();
      map.putIfAbsent(day, () => []).add(slot);
    }
    return map;
  }

  String get _preferredWindow {
    final start = _str(widget.preference['preferred_start_time']);
    final end = _str(widget.preference['preferred_end_time']);
    if (start.isEmpty && end.isEmpty) return '';
    return '${start.isEmpty ? '—' : start}  →  ${end.isEmpty ? '—' : end}';
  }

  @override
  Widget build(BuildContext context) {
    final slots = _byDay[_selectedDay] ?? const [];
    return _TitledCard(
      icon: Icons.schedule_rounded,
      title: widget.isArabic
          ? 'أوقات توفري الأسبوعية'
          : 'My weekly availability',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_preferredWindow.isNotEmpty) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cloud,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available_rounded,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isArabic ? 'الفترة المفضلة' : 'Preferred window',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _preferredWindow,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppTheme.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _workdays.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final day = _workdays[index];
                return _DayPill(
                  label: _dayLabel(widget.isArabic, day),
                  selected: day == _selectedDay,
                  onTap: () => setState(() => _selectedDay = day),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (slots.isEmpty)
            NoDataWidget(
              compact: true,
              icon: Icons.event_busy_rounded,
              title: widget.isArabic
                  ? 'لا توجد أوقات متاحة في هذا اليوم'
                  : 'No availability on this day',
            )
          else
            for (var i = 0; i < slots.length; i++) ...[
              _AvailabilityTile(slot: slots[i], isArabic: widget.isArabic),
              if (i != slots.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _AvailabilityTile extends StatelessWidget {
  const _AvailabilityTile({required this.slot, required this.isArabic});

  final dynamic slot;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final data = _map(slot);
    final start = _str(data['start_time']);
    final end = _str(data['end_time']);
    final preferred = data['is_preferred'] == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: .5)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppTheme.ctaGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'وقت متاح' : 'Available slot',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (preferred) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppTheme.honey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isArabic ? 'وقت مفضل' : 'Preferred',
                        style: const TextStyle(
                          color: AppTheme.honey,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                start.isEmpty ? '—' : start,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
              ),
              Text(
                end.isEmpty ? '' : end,
                style: const TextStyle(color: AppTheme.muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Parent dashboard: child selector at the top, drawer nav items as a 3-column
/// action grid directly below it.
Widget parentDashboardBuilder(
  BuildContext context,
  Map<String, dynamic> data,
  Future<void> Function() onRefresh,
) {
  final isArabic = appIsArabic(context);
  final children = _list(data['children']);

  return _ParentDashboardBody(isArabic: isArabic, children: children);
}

class _ParentDashboardBody extends StatefulWidget {
  const _ParentDashboardBody({
    required this.isArabic,
    required this.children,
  });

  final bool isArabic;
  final List<dynamic> children;

  @override
  State<_ParentDashboardBody> createState() => _ParentDashboardBodyState();
}

class _ParentDashboardBodyState extends State<_ParentDashboardBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appState = context.read<AppState>();
      if (appState.selectedChildId == null && widget.children.isNotEmpty) {
        final firstChild = _map(widget.children.first);
        final firstId = _num(firstChild['id']).toInt();
        if (firstId != 0) {
          appState.setSelectedChild(firstId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final items = _parentActionItems(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.isArabic ? 'من تود متابعة أخباره؟' : 'Who do you want to follow?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        _ChildSelector(
          children: widget.children,
          isArabic: widget.isArabic,
          selectedChildId: appState.selectedChildId,
          onSelect: (id) => context.read<AppState>().setSelectedChild(id),
        ),
        const SizedBox(height: 28),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.88,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) => _ActionTile(
            item: items[index],
            onTap: () => context.go(items[index].route),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  List<NavItem> _parentActionItems(BuildContext context) {
    const dashboardRoute = '/parent/dashboard';
    const profileRoute = '/parent/profile';
    final groups = navGroupsForRole(UserRole.parent);
    return groups
        .expand((group) => group.items)
        .where(
          (item) =>
              item.route != dashboardRoute && item.route != profileRoute,
        )
        .toList();
  }
}

class _ChildSelector extends StatelessWidget {
  const _ChildSelector({
    required this.children,
    required this.isArabic,
    required this.selectedChildId,
    required this.onSelect,
  });

  final List<dynamic> children;
  final bool isArabic;
  final int? selectedChildId;
  final ValueChanged<int?> onSelect;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return NoDataWidget(
        compact: true,
        icon: Icons.child_care_rounded,
        title: isArabic ? 'لا يوجد أبناء مرتبطون' : 'No linked children',
      );
    }

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemBuilder: (context, index) {
          final child = _map(children[index]);
          final id = _num(child['id']).toInt();
          final name = _str(child['name']);
          final photoUrl = _str(child['photo_url'] ?? child['image']);
          final selected = selectedChildId == null
              ? index == 0
              : selectedChildId == id;

          return GestureDetector(
            onTap: () => onSelect(selected ? null : id),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppTheme.primary : AppTheme.borderColor,
                      width: selected ? 3 : 2,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: .25),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipOval(
                    child: photoUrl.isNotEmpty
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _ChildAvatarFallback(name: name),
                          )
                        : _ChildAvatarFallback(name: name),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name.isEmpty ? '—' : name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? AppTheme.primary : AppTheme.ink,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChildAvatarFallback extends StatelessWidget {
  const _ChildAvatarFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 34,
      backgroundColor: AppTheme.primaryPale,
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.primary,
          fontWeight: FontWeight.w900,
          fontSize: 24,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.item, required this.onTap});

  final NavItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final selected = item.route == currentPath;

    return Material(
      color: selected ? AppTheme.cloud : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppTheme.primary.withValues(alpha: .4)
                  : AppTheme.borderColor.withValues(alpha: .5),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowTint.withValues(alpha: .05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LivingNavIcon(
                icon: item.icon,
                selected: selected,
                size: 52,
              ),
              const SizedBox(height: 10),
              Text(
                localizedNavLabel(context, item),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: selected ? AppTheme.primary : AppTheme.ink,
                  height: 1.2,
                ),
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

class _Meta {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _PeriodTile extends StatelessWidget {
  const _PeriodTile({
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.metas,
  });

  final String startTime;
  final String endTime;
  final String title;
  final List<_Meta> metas;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 58,
            child: Column(
              children: [
                Text(
                  startTime,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                  ),
                ),
                Text(
                  endTime,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 3,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppTheme.ctaGradient,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? '—' : title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                for (final meta in metas)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(meta.icon, size: 14, color: AppTheme.muted),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            meta.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
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

class _LineItem extends StatelessWidget {
  const _LineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _SoftIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? '—' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (trailing case final value?)
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard({
    required this.notifications,
    required this.isArabic,
  });

  final List<dynamic> notifications;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _TitledCard(
        icon: Icons.notifications_rounded,
        title: isArabic ? 'آخر الإشعارات' : 'Recent notifications',
        child: Column(
          children: [
            for (var i = 0; i < notifications.length; i++) ...[
              _LineItem(
                icon: Icons.markunread_mailbox_rounded,
                title: _mapItem(notifications[i], 'title'),
                subtitle: _mapItem(notifications[i], 'body'),
              ),
              if (i != notifications.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

const _monthNamesAr = <String>[
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];
const _monthNamesEn = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _monthLabel(int month, int year, bool isArabic) {
  if (month < 1 || month > 12) return '$year';
  return '${isArabic ? _monthNamesAr[month - 1] : _monthNamesEn[month - 1]} $year';
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
