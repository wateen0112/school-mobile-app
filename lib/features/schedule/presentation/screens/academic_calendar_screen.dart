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
const _apiDayNamesEn = <String>['S', 'M', 'T', 'W', 'T', 'F', 'S'];
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
const _typeLabelsAr = <String, String>{
  'holiday': 'إجازة',
  'exam': 'امتحانات',
  'closure': 'إغلاق',
  'special': 'مناسبة',
};
const _typeLabelsEn = <String, String>{
  'holiday': 'Holiday',
  'exam': 'Exams',
  'closure': 'Closure',
  'special': 'Special day',
};
const _statusLabelsAr = <String, String>{
  'active': 'نشطة',
  'draft': 'مسودة',
  'archived': 'مؤرشفة',
};

/// Annual academic calendar screen shown for the `academicCalendar`
/// specialView across the teacher, student, and parent roles. Fetches the
/// school's academic years and renders the yearly calendar with teaching
/// weeks, holidays, daily periods, and stats.
class AcademicCalendarScreen extends StatefulWidget {
  const AcademicCalendarScreen({super.key});

  @override
  State<AcademicCalendarScreen> createState() => _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState extends State<AcademicCalendarScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _years = const [];
  Map<String, dynamic>? _calendar;
  int? _selectedYearId;
  String _languageCode = 'ar';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  bool get _isArabic => _languageCode == 'ar';

  Future<void> _load() async {
    final api = context.read<SessionController>().api;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final body = await api.get('/scheduling/academic-years');
      final data = body['data'];
      final years = data is List
          ? data
                .whereType<Map>()
                .map((raw) => Map<String, dynamic>.from(raw))
                .toList()
          : <Map<String, dynamic>>[];

      if (years.isEmpty) {
        if (!mounted) return;
        setState(() {
          _years = const [];
          _calendar = null;
          _selectedYearId = null;
          _loading = false;
        });
        return;
      }

      // Prefer the active year, otherwise the first one.
      final fallbackId = _int(years.first['id']);
      final activeId = years.any((y) => '${y['status']}' == 'active')
          ? years.firstWhere((y) => '${y['status']}' == 'active')['id']
          : null;

      setState(() {
        _years = years;
        _selectedYearId = activeId == null ? fallbackId : _int(activeId);
        _calendar = null;
      });
      await _loadCalendar(_selectedYearId!);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.failureFrom(error).message;
        _loading = false;
      });
    }
  }

  Future<void> _selectYear(int? yearId) async {
    if (yearId == null || yearId == _selectedYearId) return;
    setState(() {
      _selectedYearId = yearId;
      _calendar = null;
      _loading = true;
      _error = null;
    });
    await _loadCalendar(yearId);
  }

  Future<void> _loadCalendar(int yearId) async {
    final api = context.read<SessionController>().api;
    try {
      final body = await api.get('/scheduling/academic-years/$yearId/calendar');
      if (!mounted) return;
      setState(() {
        _calendar = _map(body['data']);
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
                    label: Text(_isArabic ? 'إعادة المحاولة' : 'Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final calendar = _calendar;
    if (_years.isEmpty || calendar == null) {
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
                    Icons.event_busy_rounded,
                    size: 44,
                    color: AppTheme.muted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isArabic
                        ? 'لا توجد سنة دراسية بعد'
                        : 'No academic year yet',
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
          _YearHeader(isArabic: _isArabic),
          if (_years.length > 1) ...[
            _YearPicker(
              years: _years,
              selectedYearId: _selectedYearId,
              onChanged: _selectYear,
            ),
            const SizedBox(height: 12),
          ],
          _HeroCard(
            isArabic: _isArabic,
            year: _selectedYear(),
            stats: _map(calendar['stats']) ?? const {},
          ),
          const SizedBox(height: 14),
          _HolidaysSection(
            holidays: _holidays(calendar),
            isArabic: _isArabic,
          ),
          const SizedBox(height: 14),
          _PeriodsSection(
            periods: _periodList(calendar),
            isArabic: _isArabic,
          ),
          const SizedBox(height: 18),
          Text(
            _isArabic ? 'التقويم السنوي' : 'Annual calendar',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _MonthCalendar(
            days: _allDays(calendar),
            isArabic: _isArabic,
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _selectedYear() {
    if (_selectedYearId == null) return const {};
    for (final year in _years) {
      if (_int(year['id']) == _selectedYearId) return year;
    }
    return const {};
  }

  List<Map<String, dynamic>> _holidays(Map<String, dynamic> calendar) {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final day in _allDays(calendar)) {
      final holiday = day['holiday'];
      if (holiday is! Map) continue;
      final date = '${day['date']}';
      final key = '$date-${holiday['id']}';
      if (!seen.add(key)) continue;
      result.add({
        'date': date,
        'type': '${holiday['type'] ?? 'holiday'}',
        'name': holiday['name'],
      });
    }
    result.sort((a, b) => '${a['date']}'.compareTo('${b['date']}'));
    return result;
  }

  List<Map<String, dynamic>> _allDays(Map<String, dynamic> calendar) {
    final weeks = calendar['weeks'];
    if (weeks is! List) return const [];
    return [
      for (final week in weeks.whereType<Map>())
        for (final day in (week['days'] is List
            ? week['days']
            : const <dynamic>[]).whereType<Map>())
          Map<String, dynamic>.from(day),
    ];
  }

  List<Map<String, dynamic>> _periodList(Map<String, dynamic> calendar) {
    final periods = calendar['periods'];
    if (periods is! List) return const [];
    return periods
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .toList();
  }
}

class _YearHeader extends StatelessWidget {
  const _YearHeader({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        isArabic ? 'التقويم السنوي' : 'Annual Calendar',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: AppTheme.ink,
        ),
      ),
    );
  }
}

class _YearPicker extends StatelessWidget {
  const _YearPicker({
    required this.years,
    required this.selectedYearId,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> years;
  final int? selectedYearId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: selectedYearId,
            isExpanded: true,
            borderRadius: BorderRadius.circular(14),
            items: [
              for (final year in years)
                DropdownMenuItem(
                  value: _int(year['id']),
                  child: Text(
                    '${displayValue(year['name'], languageCode: Localizations.localeOf(context).languageCode)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.isArabic,
    required this.year,
    required this.stats,
  });

  final bool isArabic;
  final Map<String, dynamic> year;
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final status = '${year['status'] ?? 'draft'}';
    final start = _string(year['start_date']);
    final end = _string(year['end_date']);

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
                  Icons.event_note_rounded,
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
                      displayValue(
                        year['name'],
                        languageCode: Localizations.localeOf(
                          context,
                        ).languageCode,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      start.isNotEmpty && end.isNotEmpty
                          ? '$start ← $end'
                          : (isArabic ? 'السنة الدراسية' : 'Academic year'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .9),
                        fontSize: 13,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Text(
                  _statusLabel(status, isArabic),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Stat(
                isArabic: isArabic,
                icon: Icons.repeat_rounded,
                value: '${_string(stats['weeks'], '—')}',
                label: isArabic ? 'أسبوع' : 'weeks',
              ),
              const SizedBox(width: 10),
              _Stat(
                isArabic: isArabic,
                icon: Icons.school_rounded,
                value: '${_string(stats['teaching_days'], '—')}',
                label: isArabic ? 'يوم دراسة' : 'study days',
              ),
              const SizedBox(width: 10),
              _Stat(
                isArabic: isArabic,
                icon: Icons.celebration_rounded,
                value: '${_string(stats['holiday_days'], '—')}',
                label: isArabic ? 'إجازة' : 'holidays',
              ),
              const SizedBox(width: 10),
              _Stat(
                isArabic: isArabic,
                icon: Icons.schedule_rounded,
                value: '${_string(stats['periods_per_day'], '—')}',
                label: isArabic ? 'حصة/يوم' : 'periods/day',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status, bool isArabic) {
    if (isArabic) return _statusLabelsAr[status] ?? status;
    return status[0].toUpperCase() + status.substring(1);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.isArabic,
    required this.icon,
    required this.value,
    required this.label,
  });

  final bool isArabic;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: .9), size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HolidaysSection extends StatelessWidget {
  const _HolidaysSection({required this.holidays, required this.isArabic});

  final List<Map<String, dynamic>> holidays;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.celebration_rounded,
                  color: AppTheme.coral,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'الأعياد والإجازات' : 'Holidays & closures',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (holidays.isEmpty)
              Text(
                isArabic
                    ? 'لا توجد أعياد أو إجازات مسجلة.'
                    : 'No holidays recorded.',
                style: const TextStyle(color: AppTheme.muted, fontSize: 13),
              )
            else
              for (final holiday in holidays) ...[
                _HolidayTile(holiday: holiday, isArabic: isArabic),
                const Divider(height: 1),
              ],
          ],
        ),
      ),
    );
  }
}

class _HolidayTile extends StatelessWidget {
  const _HolidayTile({required this.holiday, required this.isArabic});

  final Map<String, dynamic> holiday;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final type = '${holiday['type'] ?? 'holiday'}';
    final name = displayValue(
      holiday['name'],
      languageCode: Localizations.localeOf(context).languageCode,
    );
    final typeLabel = isArabic
        ? _typeLabelsAr[type] ?? type
        : _typeLabelsEn[type] ?? type;
    final date = '${holiday['date']}';
    final dateLabel = _formatDate(date, isArabic);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.coral.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_busy_rounded, color: AppTheme.coralDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty
                      ? (isArabic ? 'إجازة' : 'Holiday')
                      : name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  dateLabel,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryPale,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Text(
              typeLabel,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodsSection extends StatelessWidget {
  const _PeriodsSection({required this.periods, required this.isArabic});

  final List<Map<String, dynamic>> periods;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final lessons = periods.where((p) => '${p['type']}' == 'lesson').toList();
    final breaks = periods.where((p) => '${p['type']}' == 'break').toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isArabic
                      ? 'الفترات الدراسية اليومية'
                      : 'Daily periods',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (periods.isEmpty)
              Text(
                isArabic ? 'لا توجد فترات محددة.' : 'No periods defined.',
                style: const TextStyle(color: AppTheme.muted, fontSize: 13),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final period in periods) ...[
                    _PeriodChip(period: period, isArabic: isArabic),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            if (breaks.isNotEmpty && lessons.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.cloud,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.free_breakfast_rounded,
                      size: 16,
                      color: AppTheme.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isArabic
                          ? 'إجمالي الحصص اليومية: '
                          : 'Total daily lessons: ',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${lessons.length}',
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.period, required this.isArabic});

  final Map<String, dynamic> period;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final isBreak = '${period['type']}' == 'break';
    final start = _clock('${period['start_time'] ?? ''}');
    final end = _clock('${period['end_time'] ?? ''}');
    final note = '${period['note'] ?? ''}';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isBreak
              ? AppTheme.coral.withValues(alpha: .12)
              : AppTheme.cloud,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isBreak
                ? AppTheme.coral.withValues(alpha: .4)
                : AppTheme.primary.withValues(alpha: .2),
          ),
        ),
        child: Column(
          children: [
            Text(
              isBreak
                  ? (isArabic ? 'راحة' : 'Break')
                  : '${period['period_number'] ?? ''}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isBreak ? AppTheme.coralDark : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              start.isNotEmpty && end.isNotEmpty ? '$start-$end' : '',
              style: const TextStyle(fontSize: 10, color: AppTheme.muted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
            ),
            if (isBreak && note.isNotEmpty)
              Text(
                note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, color: AppTheme.muted),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({required this.days, required this.isArabic});

  final List<Map<String, dynamic>> days;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final months = <String, List<Map<String, dynamic>>>{};
    for (final day in days) {
      final date = '${day['date'] ?? ''}';
      if (date.length < 7) continue;
      final monthKey = date.substring(0, 7);
      months.putIfAbsent(monthKey, () => []).add(day);
    }

    final monthKeys = months.keys.toList()..sort();

    if (monthKeys.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            isArabic ? 'لا توجد بيانات تقويم.' : 'No calendar data.',
            style: const TextStyle(color: AppTheme.muted),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final monthKey in monthKeys) ...[
          _MonthCard(
            monthKey: monthKey,
            days: months[monthKey]!,
            isArabic: isArabic,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.monthKey,
    required this.days,
    required this.isArabic,
  });

  final String monthKey;
  final List<Map<String, dynamic>> days;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final parts = monthKey.split('-');
    final monthIndex = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;
    final monthName = isArabic
        ? _monthNamesAr[monthIndex - 1]
        : _monthNamesEn[monthIndex - 1];
    final year = parts.isNotEmpty ? parts[0] : '';

    final monthDays = <Map<String, dynamic>>[];
    for (final day in days) {
      final date = '${day['date'] ?? ''}';
      if (date.startsWith('$monthKey-')) monthDays.add(day);
    }
    monthDays.sort(
      (a, b) => '${a['date']}'.compareTo('${b['date']}'),
    );

    final firstDayOfWeek = monthDays.isNotEmpty
        ? _int(monthDays.first['day_of_week'])
        : 0;

    // Build calendar-week rows of 7 columns, padded with blanks.
    final cells = <Widget>[
      for (var i = 0; i < firstDayOfWeek; i++) const _BlankCell(),
      for (final day in monthDays) _DayCell(day: day, isArabic: isArabic),
    ];
    while (cells.length % 7 != 0) {
      cells.add(const _BlankCell());
    }
    final weeks = <List<Widget>>[
      for (var i = 0; i < cells.length; i += 7) cells.sublist(i, i + 7),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$monthName $year',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: Text(
                        isArabic ? _apiDayNamesAr[i] : _apiDayNamesEn[i],
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            for (final week in weeks)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    for (final cell in week) Expanded(child: cell),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BlankCell extends StatelessWidget {
  const _BlankCell();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(1.5),
      child: SizedBox(height: 44),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.isArabic});

  final Map<String, dynamic> day;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final date = '${day['date'] ?? ''}';
    final dayNumber = date.length >= 10
        ? int.tryParse(date.substring(8, 10)) ?? 0
        : 0;
    final holiday = day['holiday'];
    final isHoliday = holiday is Map || day['is_holiday'] == true;
    final isWorking = day['is_working'] == true;

    Color background;
    IconData icon;
    if (isHoliday) {
      background = AppTheme.coral.withValues(alpha: .16);
      icon = Icons.event_busy_rounded;
    } else if (isWorking) {
      background = AppTheme.mint.withValues(alpha: .14);
      icon = Icons.school_rounded;
    } else {
      background = Colors.black.withValues(alpha: .04);
      icon = Icons.block_rounded;
    }

    final holidayName = holiday is Map
        ? displayValue(
            holiday['name'],
            languageCode: Localizations.localeOf(context).languageCode,
          )
        : '';

    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: Tooltip(
        message: holidayName.isNotEmpty
            ? holidayName
            : (isWorking
                ? (isArabic ? 'يوم دراسة' : 'Study day')
                : isHoliday
                ? (isArabic ? 'إجازة' : 'Holiday')
                : (isArabic ? 'إجازة أسبوعية' : 'Non-working day')),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$dayNumber',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isHoliday
                      ? AppTheme.coralDark
                      : isWorking
                      ? const Color(0xff1F9D45)
                      : AppTheme.muted,
                ),
              ),
              Icon(icon, size: 11, color: AppTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}

String _string(dynamic value, [String fallback = '']) =>
    value == null || '$value'.trim().isEmpty || '$value' == 'null'
    ? fallback
    : '$value';

int _int(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value == null ? '' : '$value') ?? 0;
}

String _clock(String time) => time.length >= 5 ? time.substring(0, 5) : time;

String _formatDate(String date, bool isArabic) {
  final parts = date.split('-');
  if (parts.length < 3) return date;
  final day = int.tryParse(parts[2]) ?? 0;
  final month = int.tryParse(parts[1]) ?? 1;
  final year = parts[0];
  final monthName = isArabic
      ? _monthNamesAr[month - 1]
      : _monthNamesEn[month - 1];
  return isArabic ? '$day $monthName $year' : '$monthName $day, $year';
}

Map<String, dynamic>? _map(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}