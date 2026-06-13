import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/api_client.dart';
import '../app/design_system.dart';
import '../widgets/shared_widgets.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, required this.api});

  final SchoolApiClient api;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late Future<List<dynamic>> _future = widget.api.list('/students');
  final Map<int, String> _statuses = {};
  bool _saving = false;
  String? _error;

  void _reload() {
    setState(() => _future = widget.api.list('/students'));
  }

  Future<void> _save() async {
    if (_statuses.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.bulkAttendance({
        'student_id': _statuses.keys.toList(),
        'attendance_status': _statuses.values.toList(),
        'attendance_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t(context, 'save'))));
      }
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: t(context, 'attendance'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SoftCard(
            child: Row(
              children: [
                const Icon(Icons.today_rounded, color: SchoolColors.secondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${t(context, 'attendanceToday')} ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: SchoolColors.danger)),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return EmptyState(
                    icon: Icons.wifi_off_rounded,
                    message: '${snapshot.error}',
                    onRetry: _reload,
                  );
                }
                final students = snapshot.data ?? const [];
                if (students.isEmpty) {
                  return EmptyState(
                    icon: Icons.school_rounded,
                    message: t(context, 'noData'),
                    onRetry: _reload,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    itemCount: students.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final student = students[index] as Map;
                      final id = student['id'];
                      final name = displayValue(
                        student['name'] ?? student['Name'],
                        languageCode: Localizations.localeOf(
                          context,
                        ).languageCode,
                      );
                      return SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  child: Icon(Icons.person_rounded),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                                StatusPill(
                                  label: _statuses[id] == 'absent'
                                      ? t(context, 'absent')
                                      : t(context, 'present'),
                                  positive: _statuses[id] != 'absent',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SegmentedButton<String>(
                              segments: [
                                ButtonSegment(
                                  value: 'presence',
                                  label: Text(t(context, 'present')),
                                  icon: const Icon(Icons.check_circle_rounded),
                                ),
                                ButtonSegment(
                                  value: 'absent',
                                  label: Text(t(context, 'absent')),
                                  icon: const Icon(Icons.cancel_rounded),
                                ),
                              ],
                              selected: {_statuses[id] ?? 'presence'},
                              onSelectionChanged: (value) =>
                                  setState(() => _statuses[id] = value.first),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: t(context, 'markAttendance'),
            icon: Icons.fact_check_rounded,
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
