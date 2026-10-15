import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/models/app_models.dart';
import '../../core/network/api_service.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/loading_shimmer.dart';

String _displayName(dynamic value, {String languageCode = 'en'}) {
  if (value == null) return '-';
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final direct =
        map[languageCode] ??
        map['Name'] ??
        map['name'] ??
        map['Name_en'] ??
        map['Name_ar'] ??
        map['name_en'] ??
        map['name_ar'] ??
        map.values.firstOrNull;
    if (direct != null) return _displayName(direct, languageCode: languageCode);
  }
  return '$value';
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  final parsed = double.tryParse('$value');
  return parsed ?? fallback;
}

class StudentPaperExamMarksContent extends StatefulWidget {
  const StudentPaperExamMarksContent({super.key});

  @override
  State<StudentPaperExamMarksContent> createState() =>
      _StudentPaperExamMarksContentState();
}

class _StudentPaperExamMarksContentState
    extends State<StudentPaperExamMarksContent> {
  late final ApiService _api;

  Map<String, dynamic> _marksData = {};
  bool _loading = true;
  String? _error;
  String? _selectedSubjectId;

  /// Marks grouped by subject. For parents the API groups marks by student,
  /// so we pick the marks of [AppState.selectedChildId] and re-group them by
  /// subject to match the UI.
  Map<String, dynamic> get _visibleMarksData {
    final role = context.read<SessionController>().currentRole;
    if (role != UserRole.parent) return _marksData;
    final selectedChildId = context.watch<AppState>().selectedChildId;
    if (selectedChildId == null) return const {};
    final childMarks = _marksData['$selectedChildId'];
    final list = childMarks is List ? childMarks : const [];
    final grouped = <String, List<dynamic>>{};
    for (final mark in list) {
      final map = mark is Map ? Map<String, dynamic>.from(mark) : null;
      final exam = map?['paper_exam'] is Map
          ? Map<String, dynamic>.from(map!['paper_exam'] as Map)
          : null;
      final subjectId = exam?['subject_id'];
      if (subjectId == null) continue;
      grouped.putIfAbsent('$subjectId', () => []).add(mark);
    }
    return grouped;
  }

  // Subject names from the grouped data
  List<_SubjectSummary> _buildSubjects(Map<String, dynamic> data) {
    final subjects = <_SubjectSummary>[];
    for (final entry in data.entries) {
      final marks = entry.value is List ? entry.value as List : <dynamic>[];
      if (marks.isEmpty) continue;
      final first = marks.first is Map
          ? Map<String, dynamic>.from(marks.first as Map)
          : <String, dynamic>{};
      final exam = first['paper_exam'] is Map
          ? Map<String, dynamic>.from(first['paper_exam'] as Map)
          : <String, dynamic>{};
      final subject = exam['subject'] is Map
          ? Map<String, dynamic>.from(exam['subject'] as Map)
          : <String, dynamic>{};
      subjects.add(
        _SubjectSummary(
          subjectId: int.tryParse(entry.key) ?? 0,
          subjectName: _displayName(
            subject,
            languageCode: Localizations.localeOf(context).languageCode,
          ),
          totalMarks: marks.fold<double>(
            0,
            (sum, m) => sum + _asDouble(m['marks_obtained']),
          ),
          examCount: marks.length,
        ),
      );
    }
    return subjects;
  }

  @override
  void initState() {
    super.initState();
    _api = context.read<SessionController>().api;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMarks());
  }

  Future<void> _loadMarks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final body = await _api.get('/paper-exam-marks/my');
      final data = body['data'];
      _marksData = data is Map ? Map<String, dynamic>.from(data) : {};
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isArabic = languageCode == 'ar';
    final marksData = _visibleMarksData;
    final subjects = _buildSubjects(marksData);
    final selectedSubjectId =
        subjects.any((s) => '${s.subjectId}' == _selectedSubjectId)
            ? _selectedSubjectId
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loading)
          const LoadingShimmer()
        else if (_error != null)
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.coral,
              ),
              title: Text(_error!),
              trailing: IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadMarks,
              ),
            ),
          )
        else if (subjects.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_rounded,
                      size: 48,
                      color: AppTheme.muted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isArabic
                          ? 'لا توجد علامات اختبارات ورقية بعد'
                          : 'No paper exam marks yet',
                      style: const TextStyle(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isArabic ? 'علامات الاختبارات الورقية' : 'Paper Exam Marks',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isArabic
                        ? 'اختر المادة لعرض التفاصيل'
                        : 'Select a subject to view details',
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (selectedSubjectId == null)
            // Subject list
            for (final subject in subjects) ...[
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() => _selectedSubjectId = '${subject.subjectId}');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject.subjectName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isArabic
                                    ? '${subject.examCount} اختبار'
                                    : '${subject.examCount} exam(s)',
                                style: const TextStyle(color: AppTheme.muted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${subject.totalMarks}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_left_rounded,
                          color: AppTheme.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ]
          else
            // Detailed marks for selected subject
            ..._buildSubjectDetail(
              isArabic,
              languageCode,
              marksData,
              subjects,
              selectedSubjectId,
            ),
        ],
      ],
    );
  }

  List<Widget> _buildSubjectDetail(
    bool isArabic,
    String languageCode,
    Map<String, dynamic> marksData,
    List<_SubjectSummary> subjects,
    String? selectedSubjectId,
  ) {
    final subjectMarks = marksData[selectedSubjectId] as List? ?? [];
    final subject = subjects.firstWhere(
      (s) => '${s.subjectId}' == selectedSubjectId,
      orElse: () => subjects.first,
    );

    return [
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => setState(() => _selectedSubjectId = null),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subject.subjectName,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      for (final mark in subjectMarks) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mark['paper_exam']?['title'] ?? '',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _asDouble(mark['marks_obtained']) >=
                                _asDouble(
                                  mark['paper_exam']?['max_score'],
                                  fallback: 100,
                                ) *
                                    0.5
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${mark['marks_obtained'] ?? 0} / ${mark['paper_exam']?['max_score'] ?? 100}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color:
                              _asDouble(mark['marks_obtained']) >=
                                  _asDouble(
                                    mark['paper_exam']?['max_score'],
                                    fallback: 100,
                                  ) *
                                      0.5
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${isArabic ? 'التاريخ' : 'Date'}: ${mark['paper_exam']?['exam_date'] ?? '-'}',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                ),
                if (mark['notes'] != null && '${mark['notes']}'.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${isArabic ? 'ملاحظات' : 'Notes'}: ${mark['notes']}',
                    style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }
}

class _SubjectSummary {
  final int subjectId;
  final String subjectName;
  final double totalMarks;
  final int examCount;

  const _SubjectSummary({
    required this.subjectId,
    required this.subjectName,
    required this.totalMarks,
    required this.examCount,
  });
}
