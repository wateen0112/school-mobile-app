import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/state/session_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/refreshable_content.dart';

const _dayNamesAr = <String>[
  'الأحد',
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
];
const _dayNamesEn = <String>[
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

/// Teacher self-service screen for preferred working days, times, and
/// scheduling preferences. Shown for the `myAvailability` specialView.
class MyAvailabilityScreen extends StatefulWidget {
  const MyAvailabilityScreen({super.key});

  @override
  State<MyAvailabilityScreen> createState() => _MyAvailabilityScreenState();
}

class _MyAvailabilityScreenState extends State<MyAvailabilityScreen> {
  bool _loading = true;
  bool _savingTimes = false;
  bool _savingPrefs = false;
  String? _error;
  String _languageCode = 'ar';

  late List<_DaySlot> _days;
  Map<String, dynamic>? _pref;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _days = _emptyDays();
    _notesController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _isArabic => _languageCode == 'ar';

  List<_DaySlot> _emptyDays() => [
        for (var d = 0; d < 7; d++)
          _DaySlot(d, _isArabic ? _dayNamesAr[d] : _dayNamesEn[d]),
      ];

  String _dayName(int index) =>
      _isArabic ? _dayNamesAr[index] : _dayNamesEn[index];

  Future<void> _load() async {
    final api = context.read<SessionController>().api;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final body = await api.get('/teacher/my-availability');
      final data = _map(body['data']);
      if (!mounted) return;

      setState(() {
        if (data != null) _apply(data);
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

  void _apply(Map<String, dynamic> data) {
    _days = _emptyDays();

    final availability = data['availability'];
    if (availability is List) {
      for (final raw in availability.whereType<Map>()) {
        final day = Map<String, dynamic>.from(raw);
        final index = _int(day['day_of_week']);
        if (index < 0 || index > 6) continue;
        _days[index]
          ..isAvailable = day['is_available'] == true
          ..isPreferred = day['is_preferred'] == true
          ..start = _toTimeOfDay('${day['start_time'] ?? ''}')
          ..end = _toTimeOfDay('${day['end_time'] ?? ''}');
      }
    }

    final pref = _map(data['preference']);
    _pref = pref ?? {};
    _notesController.text =
        '${(_pref ?? {})['notes'] ?? ''}';
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
                    onPressed: _savingTimes ? null : _load,
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

    // Keep day names in sync with the active locale.
    for (var i = 0; i < _days.length; i++) {
      _days[i].name = _dayName(i);
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
          Text(
            _isArabic ? 'أوقات التوفر والتفضيلات' : 'Availability & preferences',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isArabic
                ? 'حدد الأيام والساعات التي تفضلها لتدريسك.'
                : 'Choose the days and hours you prefer for teaching.',
            style: const TextStyle(color: AppTheme.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _SectionTitle(
            icon: Icons.schedule_rounded,
            title: _isArabic ? 'الأيام والساعات' : 'Weekly days & times',
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < _days.length; i++)
                  _DaySlotTile(
                    slot: _days[i],
                    isArabic: _isArabic,
                    onToggleAvailable: (v) =>
                        setState(() => _days[i].isAvailable = v),
                    onTogglePreferred: (v) =>
                        setState(() => _days[i].isPreferred = v),
                    onPickStart: () => _pickTime(i, isStart: true),
                    onPickEnd: () => _pickTime(i, isStart: false),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _savingTimes ? null : _saveTimes,
            icon: _savingTimes
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(
              _isArabic ? 'حفظ الأوقات' : 'Save times',
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            icon: Icons.tune_rounded,
            title: _isArabic ? 'تفضيلات الجدولة' : 'Scheduling preferences',
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PreferenceHeader(
                    label: _isArabic ? 'الفترة المفضلة' : 'Preferred window',
                    onPickStart: () => _pickPrefTime(isStart: true),
                    onPickEnd: () => _pickPrefTime(isStart: false),
                    fromLabel: _isArabic ? 'من' : 'From',
                    toLabel: _isArabic ? 'إلى' : 'To',
                    leadingText: _prefText(_pref?['preferred_start_time']),
                    trailingText: _prefText(_pref?['preferred_end_time']),
                  ),
                  const SizedBox(height: 16),
                  _StepperRow(
                    label: _isArabic ? 'الحصص المتتالية المفضلة' : 'Preferred consecutive',
                    value: _intNullable(_pref?['preferred_consecutive']),
                    onChanged: (v) => setState(() => _pref?['preferred_consecutive'] = v),
                  ),
                  const SizedBox(height: 10),
                  _StepperRow(
                    label: _isArabic ? 'الحد الأقصى المتتالي' : 'Max consecutive',
                    value: _intNullable(_pref?['max_consecutive']),
                    onChanged: (v) => setState(() => _pref?['max_consecutive'] = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isArabic ? 'أيام التوقف' : 'Avoid days',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var d = 0; d < 7; d++)
                        ChoiceChip(
                          label: Text(_dayName(d)),
                          selected: (_avoidDays).contains(d),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _avoidDays.add(d);
                            } else {
                              _avoidDays.remove(d);
                            }
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: _isArabic ? 'ملاحظات' : 'Notes',
              hintText: _isArabic ? 'أي ملاحظات إضافية...' : 'Any extra notes...',
              filled: true,
              fillColor: AppTheme.cloud,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _savingPrefs ? null : _savePreferences,
            icon: _savingPrefs
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(_isArabic ? 'حفظ التفضيلات' : 'Save preferences'),
          ),
        ],
      ),
    );
  }

  Set<int> get _avoidDays {
    final raw = _pref?['avoid_days'];
    if (raw is! List) return const {};
    return raw
        .whereType<num>()
        .map((e) => e.toInt())
        .toSet();
  }

  String _prefText(dynamic value) {
    final t = _toTimeOfDay('${value ?? ''}');
    return t == null ? (_isArabic ? 'غير محدد' : 'Not set') : _formatTime(t);
  }

  Future<void> _pickTime(int dayIndex, {required bool isStart}) async {
    final slot = _days[dayIndex];
    final initial = isStart
        ? (slot.start ?? const TimeOfDay(hour: 8, minute: 0))
        : (slot.end ?? slot.start ?? const TimeOfDay(hour: 8, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _days[dayIndex].start = picked;
      } else {
        _days[dayIndex].end = picked;
      }
      _days[dayIndex].isAvailable = true;
    });
  }

  Future<void> _pickPrefTime({required bool isStart}) async {
    final key = isStart ? 'preferred_start_time' : 'preferred_end_time';
    final current = _toTimeOfDay('${_pref?[key] ?? ''}');
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _pref?[key] = _formatTime(picked));
  }

  Future<void> _saveTimes() async {
    final payloadDays = <Map<String, dynamic>>[];
    for (final day in _days) {
      if (!day.isAvailable) {
        payloadDays.add({'day_of_week': day.index, 'is_available': false});
        continue;
      }
      if (day.start == null || day.end == null) {
        _snack(_isArabic
            ? 'حدد وقت البداية والنهاية لليوم ${day.name}'
            : 'Pick a start & end time for ${day.name}');
        return;
      }
      if (_dayMinutes(day.end!) <= _dayMinutes(day.start!)) {
        _snack(_isArabic
            ? 'وقت النهاية يجب أن يأتي بعد البداية'
            : 'End time must come after the start time');
        return;
      }
      payloadDays.add({
        'day_of_week': day.index,
        'start_time': _formatTime(day.start!),
        'end_time': _formatTime(day.end!),
        'is_available': true,
        'is_preferred': day.isPreferred,
      });
    }

    final api = context.read<SessionController>().api;
    setState(() => _savingTimes = true);
    try {
      await api.post(
        '/teacher/my-availability/schedules',
        data: {'days': payloadDays},
      );
      if (!mounted) return;
      _applyDataFromBody(api);
      _snack(_isArabic ? 'تم حفظ الأوقات بنجاح' : 'Times saved');
    } catch (error) {
      if (!mounted) return;
      _snack(ApiService.failureFrom(error).message);
    } finally {
      if (mounted) setState(() => _savingTimes = false);
    }
  }

  Future<void> _savePreferences() async {
    final api = context.read<SessionController>().api;
    setState(() => _savingPrefs = true);
    try {
      await api.post(
        '/teacher/my-availability/preferences',
        data: {
          'preferred_start_time': _pref?['preferred_start_time'],
          'preferred_end_time': _pref?['preferred_end_time'],
          'preferred_consecutive': _pref?['preferred_consecutive'],
          'max_consecutive': _pref?['max_consecutive'],
          'avoid_days': _avoidDays.toList()..sort(),
          'notes': _notesController.text.trim(),
        },
      );
      if (!mounted) return;
      _applyDataFromBody(api);
      _snack(_isArabic ? 'تم حفظ التفضيلات بنجاح' : 'Preferences saved');
    } catch (error) {
      if (!mounted) return;
      _snack(ApiService.failureFrom(error).message);
    } finally {
      if (mounted) setState(() => _savingPrefs = false);
    }
  }

  Future<void> _applyDataFromBody(ApiService api) async {
    try {
      final body = await api.get('/teacher/my-availability');
      final data = _map(body['data']);
      if (mounted && data != null) setState(() => _apply(data));
    } catch (_) {}
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _DaySlot {
  _DaySlot(this.index, this.name);

  final int index;
  String name;
  bool isAvailable = false;
  bool isPreferred = false;
  TimeOfDay? start;
  TimeOfDay? end;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _DaySlotTile extends StatelessWidget {
  const _DaySlotTile({
    required this.slot,
    required this.isArabic,
    required this.onToggleAvailable,
    required this.onTogglePreferred,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final _DaySlot slot;
  final bool isArabic;
  final ValueChanged<bool> onToggleAvailable;
  final ValueChanged<bool> onTogglePreferred;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              slot.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Switch(
            value: slot.isAvailable,
            onChanged: onToggleAvailable,
            activeTrackColor: AppTheme.mint,
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _TimeZone(
                    label: isArabic ? 'من' : 'From',
                    time: slot.start,
                    isEnabled: slot.isAvailable,
                    onTap: slot.isAvailable ? onPickStart : null,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _TimeZone(
                    label: isArabic ? 'إلى' : 'To',
                    time: slot.end,
                    isEnabled: slot.isAvailable,
                    onTap: slot.isAvailable ? onPickEnd : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: slot.isAvailable ? () => onTogglePreferred(!slot.isPreferred) : null,
            tooltip: isArabic ? 'مفضل' : 'Preferred',
            icon: Icon(
              slot.isPreferred ? Icons.star_rounded : Icons.star_border_rounded,
              color: slot.isPreferred
                  ? Colors.amber
                  : slot.isAvailable
                      ? AppTheme.muted
                      : AppTheme.muted.withValues(alpha: .4),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeZone extends StatelessWidget {
  const _TimeZone({
    required this.label,
    required this.time,
    required this.isEnabled,
    this.onTap,
  });

  final String label;
  final TimeOfDay? time;
  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isEnabled ? AppTheme.cloud : AppTheme.cloud.withValues(alpha: .4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              time == null ? '—' : _formatTime(time!),
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: isEnabled ? AppTheme.ink : AppTheme.muted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceHeader extends StatelessWidget {
  const _PreferenceHeader({
    required this.label,
    required this.onPickStart,
    required this.onPickEnd,
    required this.fromLabel,
    required this.toLabel,
    required this.leadingText,
    required this.trailingText,
  });

  final String label;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final String fromLabel;
  final String toLabel;
  final String leadingText;
  final String trailingText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cloud,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.edit_rounded, size: 16, color: AppTheme.muted),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PrefZone(
                  label: fromLabel,
                  value: leadingText,
                  onTap: onPickStart,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PrefZone(
                  label: toLabel,
                  value: trailingText,
                  onTap: onPickEnd,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrefZone extends StatelessWidget {
  const _PrefZone({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        IconButton(
          onPressed: _decay,
          icon: const Icon(Icons.remove_circle_outline_rounded),
        ),
        SizedBox(
          width: 34,
          child: Text(
            value?.toString() ?? '—',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
        IconButton(
          onPressed: _grow,
          icon: const Icon(Icons.add_circle_outline_rounded),
        ),
      ],
    );
  }

  void _grow() {
    final current = value ?? 0;
    if (current >= 8) return;
    onChanged(current + 1);
  }

  void _decay() {
    final current = value ?? 0;
    if (current <= 1) {
      onChanged(null);
      return;
    }
    onChanged(current - 1);
  }
}

TimeOfDay? _toTimeOfDay(String time) {
  final parts = time.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return TimeOfDay(hour: h, minute: m);
}

String _formatTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

int _dayMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

int _int(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value == null ? '' : '$value') ?? 0;
}

int? _intNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

Map<String, dynamic>? _map(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}