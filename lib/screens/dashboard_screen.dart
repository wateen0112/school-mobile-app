import 'package:flutter/material.dart';

import '../app/api_client.dart';
import '../app/app_state.dart';
import '../app/design_system.dart';
import '../app/resource_registry.dart';
import '../core/widgets/animated_container.dart' as ui;
import '../widgets/shared_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.appState,
    required this.api,
    required this.openResource,
  });

  final AppState appState;
  final SchoolApiClient api;
  final ValueChanged<ResourceDefinition> openResource;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

const _mainBackground = Color(0xffF6F8FC);
const _accentColors = [
  Color(0xfff97316),
  Color(0xff3b82f6),
  Color(0xff10b981),
  Color(0xff8b5cf6),
  Color(0xfff43f5e),
  Color(0xff0ea5e9),
  Color(0xfff59e0b),
];
const _workdayAr = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'];
const _workdayEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu'];

String _s(BuildContext context, String ar, String en) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

List<dynamic> _list(dynamic value) => value is List ? value : const [];

String _num(dynamic value) {
  if (value == null) return '-';
  final text = '$value';
  final n = double.tryParse(text);
  if (n == null) return text;
  return n == n.roundToDouble() ? '${n.toInt()}' : '$n';
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _future = _load();
  int _selectedDay = 0;

  bool get isStudent =>
      (widget.appState.userType ?? '').toLowerCase() == 'student';

  Future<Map<String, dynamic>> _load() => isStudent
      ? widget.api.getStudentDashboard()
      : widget.api.getDashboard();

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: t(context, 'dashboard'),
      actions: [
        IconButton(
          tooltip: t(context, 'language'),
          onPressed: () => widget.appState.setLocale(
            widget.appState.isArabic ? const Locale('en') : const Locale('ar'),
          ),
          icon: const Icon(Icons.language_rounded),
        ),
        IconButton(
          tooltip: t(context, 'logout'),
          onPressed: widget.api.logout,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: isStudent ? _buildStudent(context) : _buildAdmin(context),
      ),
    );
  }

  Widget _buildStudent(BuildContext context) {
    return Container(
      color: _mainBackground,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 420,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError || snapshot.data == null) {
                return _StudentErrorCard(
                  error: snapshot.error,
                  onRetry: () => setState(() => _future = _load()),
                );
              }
              final data = snapshot.data!['data'];
              if (data is! Map) {
                return _StudentErrorCard(
                  error: null,
                  onRetry: () => setState(() => _future = _load()),
                );
              }
              final payload = _map(data);
              final weekSchedule = _list(payload['week_schedule']);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WelcomeBanner(student: _map(payload['student'])),
                  const SizedBox(height: 16),
                  _AttendanceStatsGrid(
                    attendance: _map(payload['attendance']),
                  ),
                  const SizedBox(height: 16),
                  _TodayClassesCard(today: _map(payload['today'])),
                  const SizedBox(height: 16),
                  _WeeklyScheduleCard(
                    weekSchedule: weekSchedule,
                    selectedDay: _selectedDay,
                    onDaySelected: (day) => setState(() => _selectedDay = day),
                    onViewAll: () => widget.openResource(
                      studentResourceDefinitions.firstWhere(
                        (definition) => definition.key == 'mySchedule',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdmin(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ui.AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          animationType: ui.AnimationType.fadeUp,
          child: _Header(appState: widget.appState),
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            final stats =
                snapshot.data?['stats'] as Map<String, dynamic>? ?? const {};
            return Row(
              children: [
                Expanded(
                  child: ui.AnimatedContainer(
                    delay: 100,
                    duration: const Duration(milliseconds: 500),
                    animationType: ui.AnimationType.fadeScale,
                    child: _StatCard(
                      label: t(context, 'statsStudents'),
                      value: '${stats['students_count'] ?? '-'}',
                      icon: Icons.school_rounded,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ui.AnimatedContainer(
                    delay: 200,
                    duration: const Duration(milliseconds: 500),
                    animationType: ui.AnimationType.fadeScale,
                    child: _StatCard(
                      label: t(context, 'statsTeachers'),
                      value: '${stats['teachers_count'] ?? '-'}',
                      icon: Icons.badge_rounded,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ui.AnimatedContainer(
                    delay: 300,
                    duration: const Duration(milliseconds: 500),
                    animationType: ui.AnimationType.fadeScale,
                    child: _StatCard(
                      label: t(context, 'statsClasses'),
                      value: '${stats['classrooms_count'] ?? '-'}',
                      icon: Icons.meeting_room_rounded,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        Text(
          t(context, 'recentWorkflows'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: resourceDefinitions.length + 1,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.18,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final definition = index == 8
                ? const ResourceDefinition(
                    key: 'attendance',
                    titleKey: 'attendance',
                    endpoint: '/attendance',
                    icon: Icons.fact_check_rounded,
                    fields: [],
                  )
                : resourceDefinitions[index > 8 ? index - 1 : index];
            return ui.AnimatedContainer(
              delay: (index * 50).toInt(),
              duration: const Duration(milliseconds: 400),
              animationType: ui.AnimationType.fadeUp,
              child: SoftCard(
                onTap: () => widget.openResource(definition),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: SchoolColors.primary.withValues(
                        alpha: .1,
                      ),
                      foregroundColor: SchoolColors.primary,
                      child: Icon(definition.icon),
                    ),
                    const Spacer(),
                    Text(
                      t(context, definition.titleKey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      definition.endpoint,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: SchoolColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _StudentErrorCard extends StatelessWidget {
  const _StudentErrorCard({this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 52, color: Color(0xff94a3b8)),
          const SizedBox(height: 14),
          Text(
            _s(context, 'تعذر تحميل لوحة الطالب', 'Could not load student dashboard'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xff64748b), fontSize: 13),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(t(context, 'retry')),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.student});

  final Map<String, dynamic> student;

  @override
  Widget build(BuildContext context) {
    final name = '${student['name'] ?? student['Name'] ?? ''}';
    final grade = '${student['grade_name'] ?? ''}';
    final classroom = '${student['classroom_name'] ?? ''}';
    final section = '${student['section_name'] ?? ''}';

    final infoParts = <String>[
      if (grade.isNotEmpty) grade,
      if (classroom.isNotEmpty && section.isNotEmpty) '$classroom - $section',
      if (classroom.isNotEmpty && section.isEmpty) classroom,
    ];

    final now = DateTime.now();
    final startYear = now.month >= 9 ? now.year : now.year - 1;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff2563eb), Color(0xff0ea5e9), Color(0xff4f46e5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff2563eb).withValues(alpha: .22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -48,
            left: -48,
            child: Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -32,
            right: -32,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: const Color(0xff7dd3fc).withValues(alpha: .18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _PulsingDot(),
                          const SizedBox(width: 6),
                          Text(
                            _s(
                              context,
                              'العام الدراسي $startYear - ${startYear + 1}',
                              'Academic year $startYear - ${startYear + 1}',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _s(context, 'مرحباً بعودتك، $name', 'Welcome back, $name'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    if (infoParts.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.school_rounded,
                            size: 14,
                            color: Color(0xffbfdbfe),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              infoParts.join(' • '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xffdbeafe),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const _AcademicEmblem(),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcademicEmblem extends StatelessWidget {
  const _AcademicEmblem();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xfff59e0b), Color(0xfff97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();
  late final Animation<double> _opacity = Tween<double>(
    begin: .35,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xff34d399),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _AttendanceStatsGrid extends StatelessWidget {
  const _AttendanceStatsGrid({required this.attendance});

  final Map<String, dynamic> attendance;

  @override
  Widget build(BuildContext context) {
    final rate = attendance['present_rate'];
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AttendanceTile(
                label: _s(context, 'نسبة الحضور', 'Attendance rate'),
                value: rate == null ? '-' : '${_num(rate)}%',
                icon: Icons.check_circle_rounded,
                color: const Color(0xff10b981),
                backgroundColor: const Color(0xffd1fae5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AttendanceTile(
                label: t(context, 'present'),
                value: _num(attendance['present']),
                icon: Icons.fact_check_rounded,
                color: const Color(0xff2563eb),
                backgroundColor: const Color(0xffdbeafe),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AttendanceTile(
                label: t(context, 'absent'),
                value: _num(attendance['absent']),
                icon: Icons.cancel_rounded,
                color: const Color(0xfff59e0b),
                backgroundColor: const Color(0xfffef3c7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AttendanceTile(
                label: _s(context, 'أيام إجمالاً', 'Total days'),
                value: _num(attendance['total_days']),
                icon: Icons.calendar_month_rounded,
                color: const Color(0xff9333ea),
                backgroundColor: const Color(0xffede9fe),
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
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe2e8f0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0d000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xff94a3b8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xff1e293b),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ],
      ),
    );
  }
}

class _TodayClassesCard extends StatelessWidget {
  const _TodayClassesCard({required this.today});

  final Map<String, dynamic> today;

  @override
  Widget build(BuildContext context) {
    final dayOfWeek = today['day_of_week'];
    final dayName = '${today['day_name'] ?? ''}';
    final isWeekend = dayOfWeek is int && dayOfWeek >= 5;
    final schedule = _list(today['schedule']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xfff1f5f9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0a000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xffeff6ff),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: Color(0xff2563eb),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dayName.isEmpty
                      ? _s(context, 'حصص اليوم', "Today's classes")
                      : _s(context, 'حصص اليوم ($dayName)', "Today's classes ($dayName)"),
                  style: const TextStyle(
                    color: Color(0xff1e293b),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isWeekend)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xfff1f5f9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _s(context, 'عطلة نهاية الأسبوع', 'Weekend'),
                    style: const TextStyle(
                      color: Color(0xff94a3b8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (isWeekend || schedule.isEmpty)
            const _TodayEmptyState()
          else
            ...List.generate(schedule.length, (index) {
              final item = _map(schedule[index]);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ScheduleTile(
                  item: item,
                  accent: _accentColors[index % _accentColors.length],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _TodayEmptyState extends StatelessWidget {
  const _TodayEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 28,
              color: Color(0xff94a3b8),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _s(context, 'لا توجد حصص اليوم', 'No classes today'),
            style: const TextStyle(
              color: Color(0xff334155),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _s(
              context,
              'استمتع بعطلتك، لا توجد بيانات لعرضها هنا بعد.',
              'Enjoy your break, there is nothing to show yet.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff94a3b8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyScheduleCard extends StatelessWidget {
  const _WeeklyScheduleCard({
    required this.weekSchedule,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onViewAll,
  });

  final List<dynamic> weekSchedule;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final dayClasses = weekSchedule
        .where((entry) => _map(entry)['day_of_week'] == selectedDay)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xfff1f5f9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0a000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xfff0f9ff),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: Color(0xff0284c7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _s(context, 'برنامجي الأسبوعي', 'My weekly schedule'),
                  style: const TextStyle(
                    color: Color(0xff1e293b),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xff2563eb),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(_s(context, 'عرض الكل', 'View all')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _workdayAr.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) => _DayPill(
                label: isAr ? _workdayAr[index] : _workdayEn[index],
                selected: index == selectedDay,
                onTap: () => onDaySelected(index),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (dayClasses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                _s(context, 'لا توجد حصص في هذا اليوم', 'No classes on this day'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff94a3b8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ...List.generate(dayClasses.length, (index) {
              final item = _map(dayClasses[index]);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ScheduleTile(
                  item: item,
                  accent: _accentColors[index % _accentColors.length],
                ),
              );
            }),
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
    return Material(
      color: selected ? const Color(0xffeff6ff) : const Color(0xfff1f5f9),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: selected
                ? Border.all(color: const Color(0xffbfdbfe).withValues(alpha: .8))
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? const Color(0xff2563eb)
                  : const Color(0xff64748b),
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.item, required this.accent});

  final Map<String, dynamic> item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final subject = '${item['subject_name'] ?? ''}';
    final teacher = '${item['teacher_name'] ?? ''}';
    final location = '${item['location'] ?? ''}';
    final start = '${item['start_time'] ?? ''}';
    final end = '${item['end_time'] ?? ''}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xfff1f5f9)),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 6,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadiusDirectional.only(
                  topEnd: Radius.circular(99),
                  bottomEnd: Radius.circular(99),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xff1e293b),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (teacher.isNotEmpty)
                        _ScheduleMeta(
                          icon: Icons.person_rounded,
                          text: teacher,
                        ),
                      if (teacher.isNotEmpty && location.isNotEmpty)
                        const SizedBox(height: 2),
                      if (location.isNotEmpty)
                        _ScheduleMeta(
                          icon: Icons.location_on_rounded,
                          text: location,
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      start,
                      style: const TextStyle(
                        color: Color(0xff1e293b),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      end,
                      style: const TextStyle(
                        color: Color(0xff94a3b8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleMeta extends StatelessWidget {
  const _ScheduleMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xff94a3b8)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff64748b),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: SchoolGradients.promo,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: SchoolColors.primary.withValues(alpha: .18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(context, 'appName'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${appState.userName ?? ''}  ${appState.userType ?? ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: .84),
                  ),
                ),
              ],
            ),
          ),
          const SchoolBagIllustration(size: 92),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: SchoolColors.secondary),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: SchoolColors.muted),
          ),
        ],
      ),
    );
  }
}