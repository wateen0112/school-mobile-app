import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/state/session_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/refreshable_content.dart';
import '../../../../widgets/shared_widgets.dart';

const _apiDayNamesAr = <String>[
  'الأحد',
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
];
const _apiDayNamesEn = <String>[
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];
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
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Weekly timetable screen shown for the `schedule` specialView across the
/// teacher, student, and parent roles. Fetches `GET /my-schedule` which the
/// backend groups by section.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  late int _selectedDay;
  String _languageCode = 'ar';

  int get _todayIndex => DateTime.now().weekday % 7;

  @override
  void initState() {
    super.initState();
    _selectedDay = _todayIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final api = context.read<SessionController>().api;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final body = await api.get('/my-schedule');
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
    _languageCode = Localizations.localeOf(context).languageCode;
    final isArabic = _languageCode == 'ar';

    if (_loading) {
      return RefreshablePage(
        onRefresh: _load,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return RefreshablePage(
        onRefresh: _load,
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

    final sections = _sections(_data ?? const {});
    final activeLessons = sections
        .map(
          (section) => (
            section: section,
            lessons: section.lessons
                .where((lesson) => lesson.isActive)
                .where((lesson) => lesson.dayOfWeek == _selectedDay)
                .toList(),
          ),
        )
        .toList();
    final dayLessonsCount = activeLessons.fold<int>(
      0,
      (sum, entry) => sum + entry.lessons.length,
    );
    final role = '${_data?['user_role'] ?? ''}';

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      backgroundColor: Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 100,
        ),
        children: [
          _HeaderCard(
            isArabic: isArabic,
            role: role,
            dayLessonsCount: dayLessonsCount,
          ),
          const SizedBox(height: 14),
          _WeekStrip(
            selectedDay: _selectedDay,
            todayIndex: _todayIndex,
            onSelected: (index) => setState(() => _selectedDay = index),
            isArabic: isArabic,
          ),
          const SizedBox(height: 18),
          _DayHeading(
            isArabic: isArabic,
            selectedDay: _selectedDay,
            isToday: _selectedDay == _todayIndex,
          ),
          if (activeLessons.isEmpty)
            NoDataWidget(
              compact: true,
              icon: Icons.event_available_rounded,
              title: isArabic
                  ? 'لا توجد حصص في هذا اليوم'
                  : 'No lessons on this day',
              message: isArabic
                  ? 'اختر يوماً آخر من شريط أيام الأسبوع.'
                  : 'Pick another day from the week strip.',
              onRefresh: _load,
            )
          else
            for (final entry in activeLessons) ...[
              _SectionCard(
                section: entry.section,
                lessons: entry.lessons,
                selectedDay: _selectedDay,
                isToday: _selectedDay == _todayIndex,
                isArabic: isArabic,
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  List<_SectionSchedule> _sections(Map<String, dynamic> data) {
    final rawSections = data['sections'];
    if (rawSections is! List) return const [];
    return rawSections
        .whereType<Map>()
        .map(
          (raw) => _SectionSchedule.fromJson(
            Map<String, dynamic>.from(raw),
            _languageCode,
          ),
        )
        .toList();
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.isArabic,
    required this.role,
    required this.dayLessonsCount,
  });

  final bool isArabic;
  final String role;
  final int dayLessonsCount;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final apiDayIndex = now.weekday % 7;
    final dayName = isArabic
        ? _apiDayNamesAr[apiDayIndex]
        : _apiDayNamesEn[apiDayIndex];
    final monthName = isArabic
        ? _monthNamesAr[now.month - 1]
        : _monthNamesEn[now.month - 1];
    final date = isArabic
        ? '$dayName، ${now.day} $monthName ${now.year}'
        : '$dayName, $monthName ${now.day}, ${now.year}';
    final isParent = role == 'parent';
    final title = isArabic
        ? 'الجدول الأسبوعي'
        : (isParent ? 'Weekly Schedule' : 'My Schedule');
    final subtitle = isArabic
        ? (isParent
            ? 'جدول حصص أبنائك حسب الأقسام'
            : 'جدول حصصك حسب الأقسام')
        : (isParent
            ? "Your children's weekly timetable by section"
            : 'Your weekly timetable by section');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A52BE)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .92),
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
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    date,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  isArabic
                      ? '$dayLessonsCount حصة'
                      : '$dayLessonsCount lessons',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.selectedDay,
    required this.todayIndex,
    required this.onSelected,
    required this.isArabic,
  });

  final int selectedDay;
  final int todayIndex;
  final ValueChanged<int> onSelected;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday % 7));

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: 7,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = weekStart.add(Duration(days: index));
          final selected = index == selectedDay;
          final isToday = index == todayIndex;
          return _DayCell(
            name: isArabic
                ? _apiDayNamesAr[index]
                : _apiDayNamesEn[index],
            dayNumber: day.day,
            selected: selected,
            isToday: isToday,
            isArabic: isArabic,
            onTap: () => onSelected(index),
          );
        },
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.name,
    required this.dayNumber,
    required this.selected,
    required this.isToday,
    required this.isArabic,
    required this.onTap,
  });

  final String name;
  final int dayNumber;
  final bool selected;
  final bool isToday;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = selected ? Colors.white : AppTheme.ink;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 82,
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.heroGradient : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : isToday
                ? AppTheme.primary
                : AppTheme.borderColor,
            width: isToday ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: .3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: TextStyle(
                color: ink,
                fontSize: isArabic ? 15 : 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$dayNumber',
              style: TextStyle(
                color: isArabic
                    ? ink.withValues(alpha: .8)
                    : selected
                    ? Colors.white70
                    : AppTheme.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayHeading extends StatelessWidget {
  const _DayHeading({
    required this.isArabic,
    required this.selectedDay,
    required this.isToday,
  });

  final bool isArabic;
  final int selectedDay;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final name = isArabic
        ? _apiDayNamesAr[selectedDay]
        : _apiDayNamesEn[selectedDay];
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Row(
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          if (isToday) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.mint.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                isArabic ? 'اليوم' : 'Today',
                style: const TextStyle(
                  color: Color(0xff1F9D45),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.lessons,
    required this.selectedDay,
    required this.isToday,
    required this.isArabic,
  });

  final _SectionSchedule section;
  final List<_Lesson> lessons;
  final int selectedDay;
  final bool isToday;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (section.classroomName.isNotEmpty) section.classroomName,
      if (section.gradeName.isNotEmpty) section.gradeName,
    ].join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: AppTheme.ctaGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.sectionName.isEmpty
                            ? (isArabic ? 'قسم' : 'Section')
                            : section.sectionName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                if (lessons.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPale,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text(
                      isArabic ? '${lessons.length} حصص' : '${lessons.length}',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            if (lessons.isEmpty) ...[
              const SizedBox(height: 14),
              Text(
                isArabic ? 'لا توجد حصص في هذا اليوم' : 'No lessons this day',
                style: const TextStyle(color: AppTheme.muted, fontSize: 13),
              ),
            ] else ...[
              const SizedBox(height: 10),
              for (var index = 0; index < lessons.length; index++) ...[
                _LessonTile(
                  lesson: lessons[index],
                  showNow: isToday &&
                      _nowWithin(
                        lessons[index].startMinutes,
                        lessons[index].endMinutes,
                      ),
                  isArabic: isArabic,
                ),
                if (index != lessons.length - 1)
                  const Divider(height: 1, indent: 2, endIndent: 2),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.showNow,
    required this.isArabic,
  });

  final _Lesson lesson;
  final bool showNow;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final trailing = <_LessonMeta>[
      if (lesson.teacher.isNotEmpty)
        _LessonMeta(icon: Icons.person_rounded, label: lesson.teacher),
      if (lesson.location.isNotEmpty)
        _LessonMeta(icon: Icons.place_outlined, label: lesson.location),
    ];

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
                  lesson.startTime,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                  ),
                ),
                Text(
                  lesson.endTime,
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
            height: 46,
            decoration: BoxDecoration(
              gradient: showNow
                  ? AppTheme.ctaGradient
                  : const LinearGradient(
                      colors: [AppTheme.primaryLight, AppTheme.primary],
                    ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lesson.subject.isEmpty
                            ? (isArabic ? 'مادة' : 'Subject')
                            : lesson.subject,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (showNow)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.coral.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Text(
                          'الآن',
                          style: TextStyle(
                            color: AppTheme.coralDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                if (trailing.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  for (final meta in trailing)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            meta.icon,
                            size: 14,
                            color: AppTheme.muted,
                          ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonMeta {
  const _LessonMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _SectionSchedule {
  _SectionSchedule({
    required this.sectionId,
    required this.sectionName,
    required this.classroomName,
    required this.gradeName,
    required this.lessons,
  });

  factory _SectionSchedule.fromJson(Map<String, dynamic> json, String lang) {
    final rawPrograms = json['programs'];
    final lessons = rawPrograms is List
        ? rawPrograms
              .whereType<Map>()
              .map(
                (program) => _Lesson.fromJson(
                  Map<String, dynamic>.from(program),
                  lang,
                ),
              )
              .toList()
        : <_Lesson>[];
    lessons.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return _SectionSchedule(
      sectionId: _int(json['section_id']),
      sectionName: _string(json['section_name'], lang),
      classroomName: _string(json['classroom_name'], lang),
      gradeName: _string(json['grade_name'], lang),
      lessons: lessons,
    );
  }

  final int sectionId;
  final String sectionName;
  final String classroomName;
  final String gradeName;
  final List<_Lesson> lessons;
}

class _Lesson {
  _Lesson({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.startMinutes,
    required this.endMinutes,
    required this.subject,
    required this.teacher,
    required this.location,
    required this.notes,
    required this.isActive,
  });

  factory _Lesson.fromJson(Map<String, dynamic> json, String lang) {
    final start = _raw(json['start_time']);
    final end = _raw(json['end_time']);
    return _Lesson(
      id: _int(json['id']),
      dayOfWeek: _int(json['day_of_week']),
      startTime: _clockTime(start),
      endTime: _clockTime(end),
      startMinutes: _minutes(start),
      endMinutes: _minutes(end),
      subject: _string(json['subject'], lang),
      teacher: _string(json['teacher'], lang),
      location: _raw(json['location']),
      notes: _raw(json['notes']),
      isActive: json['is_active'] != false,
    );
  }

  final int id;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final int startMinutes;
  final int endMinutes;
  final String subject;
  final String teacher;
  final String location;
  final String notes;
  final bool isActive;
}

String _raw(dynamic value) => value == null ? '' : '$value';

String _string(dynamic value, String lang) {
  final resolved = displayValue(value, languageCode: lang).trim();
  if (resolved.isNotEmpty) return resolved;
  return displayValue(value, languageCode: lang == 'ar' ? 'en' : 'ar').trim();
}

int _int(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value == null ? '' : '$value') ?? 0;
}

String _clockTime(String time) => time.length >= 5 ? time.substring(0, 5) : time;

int _minutes(String time) {
  final parts = time.split(':');
  if (parts.length < 2) return 0;
  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts[1]) ?? 0;
  return hours * 60 + minutes;
}

bool _nowWithin(int startMinutes, int endMinutes) {
  final now = DateTime.now();
  final current = now.hour * 60 + now.minute;
  return current >= startMinutes && current < endMinutes;
}