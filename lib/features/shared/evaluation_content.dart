import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/data/school_repository.dart';
import '../../core/models/app_models.dart';
import '../../core/network/api_service.dart';
import '../../core/localization/module_localization.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/loading_shimmer.dart';

class _StatItemData {
  const _StatItemData({required this.label, required this.value, required this.color});
  final String label;
  final dynamic value;
  final Color color;
}

class _EvaluationStrings {
  const _EvaluationStrings._();

  static String selectGrade(BuildContext context) =>
      appIsArabic(context) ? 'المرحلة الدراسية' : 'Grade';

  static String selectClassroom(BuildContext context) =>
      appIsArabic(context) ? 'الفصل الدراسي' : 'Classroom';

  static String selectSection(BuildContext context) =>
      appIsArabic(context) ? 'الشعبة' : 'Section';

  static String selectSubject(BuildContext context) =>
      appIsArabic(context) ? 'المادة الدراسية' : 'Subject';

  static String notes(BuildContext context) =>
      appIsArabic(context) ? 'ملاحظات' : 'Notes';

  static String month(BuildContext context) =>
      appIsArabic(context) ? 'الشهر' : 'Month';

  static String year(BuildContext context) =>
      appIsArabic(context) ? 'السنة' : 'Year';

  static String save(BuildContext context) =>
      appIsArabic(context) ? 'حفظ' : 'Save';

  static String savedSuccessfully(BuildContext context) =>
      appIsArabic(context) ? 'تم الحفظ بنجاح' : 'Saved successfully';

  static String noData(BuildContext context) =>
      appIsArabic(context) ? 'لا توجد بيانات' : 'No data available';

  static String retry(BuildContext context) =>
      appIsArabic(context) ? 'إعادة المحاولة' : 'Retry';

  static String levelLabel(BuildContext context, String level) {
    if (!appIsArabic(context)) {
      return level
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
    }
    return switch (level) {
      'bad' => 'ضعيف',
      'good' => 'جيد',
      'very_good' => 'جيد جداً',
      'excellent' => 'ممتاز',
      _ => level,
    };
  }

  static String monthName(BuildContext context, int month) {
    final names = appIsArabic(context)
        ? [
          'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
          'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
        ]
        : [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December',
        ];
    return names[month - 1];
  }

  static String statistics(BuildContext context) =>
      appIsArabic(context) ? 'الإحصائيات' : 'Statistics';

  static String total(BuildContext context) =>
      appIsArabic(context) ? 'الإجمالي' : 'Total';

  static String average(BuildContext context) =>
      appIsArabic(context) ? 'المتوسط' : 'Average';

  static String evaluations(BuildContext context) =>
      appIsArabic(context) ? 'التقييمات' : 'Evaluations';

  static String evaluateAll(BuildContext context) =>
      appIsArabic(context) ? 'تقييم الطلاب' : 'Evaluate Students';

  static String evaluateAllHint(BuildContext context) => appIsArabic(context)
      ? 'اختر مستوى التقييم لكل طالب، ثم اضغط حفظ.'
      : 'Choose an evaluation level for each student, then press save.';

  static String evaluated(BuildContext context) =>
      appIsArabic(context) ? 'تم التقييم' : 'Evaluated';

  static String notEvaluated(BuildContext context) =>
      appIsArabic(context) ? 'لم يتم التقييم' : 'Not evaluated';

  static String chooseFilters(BuildContext context) =>
      appIsArabic(context) ? 'اختر الفلاتر أولاً' : 'Choose filters first';

  static String selectFiltersHint(BuildContext context) => appIsArabic(context)
      ? 'اختر المرحلة الدراسية والفصل والشعبة والمادة لتقييم الطلاب.'
      : 'Select grade, classroom, section and subject to evaluate students.';

  static String apply(BuildContext context) =>
      appIsArabic(context) ? 'تطبيق' : 'Apply';

  static String filter(BuildContext context) =>
      appIsArabic(context) ? 'تصفية' : 'Filter';

  static String delete(BuildContext context) =>
      appIsArabic(context) ? 'حذف' : 'Delete';

  static String confirmDelete(BuildContext context) =>
      appIsArabic(context) ? 'تأكيد الحذف' : 'Confirm Delete';

  static String confirmDeleteMessage(BuildContext context) => appIsArabic(context)
      ? 'هل أنت متأكد من حذف هذا التقييم؟'
      : 'Are you sure you want to delete this evaluation?';

  static String cancel(BuildContext context) =>
      appIsArabic(context) ? 'إلغاء' : 'Cancel';

  static String all(BuildContext context) =>
      appIsArabic(context) ? 'الكل' : 'All';
}

String _displayName(dynamic value, {String languageCode = 'en'}) {
  if (value == null) return '-';
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final direct = map[languageCode] ??
        map['Name'] ??
        map['name'] ??
        map['Name_en'] ??
        map['Name_ar'] ??
        map['name_en'] ??
        map['name_ar'] ??
        map.values.firstOrNull;
    if (direct != null) return _displayName(direct, languageCode: languageCode);
  }
  final text = '$value';
  // Some backend columns store localized names as JSON strings.
  final decoded = _decodeJsonString(text);
  if (decoded != null) return _displayName(decoded, languageCode: languageCode);
  return text;
}

Map<String, dynamic>? _decodeJsonString(String text) {
  if (!text.trim().startsWith('{')) return null;
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return null;
}

dynamic _lookup(Map<String, dynamic> map, String key) {
  if (map.containsKey(key)) return map[key];
  final lower = key.toLowerCase();
  for (final entry in map.entries) {
    if (entry.key.toLowerCase() == lower) return entry.value;
  }
  return null;
}

class TeacherEvaluationsContent extends StatefulWidget {
  const TeacherEvaluationsContent({super.key});

  @override
  State<TeacherEvaluationsContent> createState() =>
      _TeacherEvaluationsContentState();
}

class _TeacherEvaluationsContentState extends State<TeacherEvaluationsContent> {
  late final ApiService _api;
  late final SchoolRepository _repository;
  int? _teacherId;

  List<FormOption> _grades = [];
  List<FormOption> _classrooms = [];
  List<FormOption> _sections = [];
  List<FormOption> _subjects = [];
  List<FormOption> _students = [];
  List<Map<String, dynamic>> _teacherAssignments = const [];

  String? _selectedGradeId;
  String? _selectedClassroomId;
  String? _selectedSectionId;
  String? _selectedSubjectId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  List<dynamic> _evaluations = [];
  bool _loading = true;
  bool _saving = false;
  bool _loadingFilters = false;
  String? _error;

  final Map<int, String> _studentLevels = {};
  final Map<int, TextEditingController> _studentNotes = {};

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionController>();
    _api = session.api;
    _repository = SchoolRepository(_api);
    _teacherId = session.authStorage.user?['id'] as int?;
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    await _loadFilters();
    await _loadEvaluations();
  }

  void _clearFilters() {
    setState(() {
      _selectedGradeId = null;
      _selectedClassroomId = null;
      _selectedSectionId = null;
      _selectedSubjectId = null;
      _classrooms = [];
      _sections = [];
      _students = [];
      _studentLevels.clear();
      _studentNotes.clear();
    });
    _buildFilterOptions(Localizations.localeOf(context).languageCode);
  }

  Future<void> _loadFilters() async {
    setState(() => _loadingFilters = true);
    try {
      final languageCode = Localizations.localeOf(context).languageCode;
      debugPrint('[Evaluations] loading filters...');
      _grades = await _repository.optionsFor('grades', languageCode: languageCode);
      debugPrint('[Evaluations] grades loaded: ${_grades.length}');

      // Derive every filter option from the teacher's section/subject
      // assignments so only genuinely assigned combinations are offered.
      _teacherAssignments = await _repository.teacherAssignments();
      debugPrint('[Evaluations] teacher assignments loaded: ${_teacherAssignments.length}');
      _buildFilterOptions(languageCode);

      _error = null;
    } catch (error, stackTrace) {
      debugPrint('[Evaluations] loadFilters error: $error\n$stackTrace');
      _error = ApiService.failureFrom(error).message;
      _showError(ApiService.failureFrom(error).message);
    } finally {
      if (mounted) setState(() => _loadingFilters = false);
    }
  }

  Map<String, dynamic>? _sectionOf(Map<String, dynamic> assignment) {
    final section = _lookup(assignment, 'section');
    return section is Map ? Map<String, dynamic>.from(section) : null;
  }

  void _buildFilterOptions(String languageCode) {
    final seenClassrooms = <String>{};
    final seenSections = <String>{};
    final seenSubjects = <String>{};
    _classrooms = [];
    _sections = [];
    _subjects = [];

    for (final assignment in _teacherAssignments) {
      final section = _sectionOf(assignment);
      if (section == null) continue;
      final grade = _lookup(section, 'Grades');
      final classroom = _lookup(section, 'My_classs');
      if (grade is! Map || classroom is! Map) continue;

      if (_selectedGradeId != null && '${grade['id']}' != _selectedGradeId) {
        continue;
      }

      final classroomMap = Map<String, dynamic>.from(classroom);
      final classroomId = '${classroomMap['id']}';
      if (seenClassrooms.add(classroomId)) {
        _classrooms.add(FormOption(
          value: classroomId,
          label: _optionLabel(classroomMap, languageCode),
        ));
      }

      if (_selectedClassroomId != null && classroomId != _selectedClassroomId) {
        continue;
      }

      final sectionId = '${section['id']}';
      if (seenSections.add(sectionId)) {
        _sections.add(FormOption(
          value: sectionId,
          label: _optionLabel(section, languageCode),
        ));
      }

      final subject = _lookup(assignment, 'subject');
      if (subject is! Map) continue;
      final subjectMap = Map<String, dynamic>.from(subject);
      final subjectId = '${subjectMap['id']}';
      if (seenSubjects.add(subjectId)) {
        _subjects.add(FormOption(
          value: subjectId,
          label: _optionLabel(subjectMap, languageCode),
        ));
      }
    }
  }

  Future<void> _onGradeChanged(String? value) async {
    setState(() {
      _selectedGradeId = value;
      _selectedClassroomId = null;
      _selectedSectionId = null;
      _students = [];
      _studentLevels.clear();
      _studentNotes.clear();
    });
    _buildFilterOptions(Localizations.localeOf(context).languageCode);
    if (mounted) setState(() {});
  }

  Future<void> _onClassroomChanged(String? value) async {
    setState(() {
      _selectedClassroomId = value;
      _selectedSectionId = null;
      _students = [];
      _studentLevels.clear();
      _studentNotes.clear();
    });
    _buildFilterOptions(Localizations.localeOf(context).languageCode);
    if (mounted) setState(() {});
  }

  Future<void> _onSectionChanged(String? value) async {
    setState(() {
      _selectedSectionId = value;
      _students = [];
      _studentLevels.clear();
      _studentNotes.clear();
    });
    if (value == null) return;
    await _loadStudents();
  }

  Future<void> _loadStudents() async {
    if (_selectedSectionId == null || _selectedClassroomId == null || _selectedGradeId == null) return;
    setState(() => _loading = true);
    try {
      final languageCode = Localizations.localeOf(context).languageCode;
      final records = await _repository.teacherStudents(
        gradeId: _selectedGradeId,
        classroomId: _selectedClassroomId,
        sectionId: _selectedSectionId,
        subjectId: _selectedSubjectId,
      );
      _students = records
          .map((r) => FormOption(value: '${r.id}', label: _optionLabel(r.raw, languageCode)))
          .toList();
      for (final student in _students) {
        final studentId = int.parse(student.value);
        _studentNotes[studentId] ??= TextEditingController();
      }
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _optionLabel(Map<String, dynamic> raw, String languageCode) {
    final candidates = [
      'name',
      'Name',
      'Name_Section',
      'Name_Class',
      'Name_class_en',
      'Name_class_ar',
      'name_en',
      'Name_en',
      'name_ar',
      'Name_ar',
    ];
    for (final key in candidates) {
      final value = raw[key];
      if (value != null) return _displayName(value, languageCode: languageCode);
    }
    return '${raw['id']}';
  }

  Future<void> _loadEvaluations() async {
    setState(() => _loading = true);
    try {
      final query = <String, dynamic>{
        if (_teacherId != null) 'teacher_id': _teacherId,
        if (_selectedGradeId != null && _selectedGradeId!.isNotEmpty)
          'grade_id': _selectedGradeId,
        if (_selectedClassroomId != null && _selectedClassroomId!.isNotEmpty)
          'classroom_id': _selectedClassroomId,
        if (_selectedSectionId != null && _selectedSectionId!.isNotEmpty)
          'section_id': _selectedSectionId,
        if (_selectedSubjectId != null && _selectedSubjectId!.isNotEmpty)
          'subject_id': _selectedSubjectId,
        'month': _selectedMonth,
        'year': _selectedYear,
      };
      final body = await _api.get('/evaluations', query: query);
      final data = body['data'];
      _evaluations = data is List ? data : [];

      // Pre-fill levels/notes for the currently selected subject so teachers
      // can update existing evaluations and see unevaluated students at a glance.
      if (_selectedSubjectId != null) {
        final selectedSubjectId = int.tryParse(_selectedSubjectId!);
        for (final evaluation in _evaluations) {
          final raw = evaluation is Map ? Map<String, dynamic>.from(evaluation) : <String, dynamic>{};
          final evalSubjectId = raw['subject_id'];
          if (evalSubjectId == selectedSubjectId) {
            final studentId = raw['student_id'] as int?;
            final level = raw['evaluation_level'] as String?;
            final notes = raw['notes'] as String?;
            if (studentId != null && level != null && level.isNotEmpty) {
              _studentLevels[studentId] = level;
              final controller = _studentNotes[studentId] ??= TextEditingController();
              controller.text = notes ?? '';
            }
          }
        }
      }

      _error = null;
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitBulk() async {
    if (_teacherId == null) {
      _showError(appIsArabic(context) ? 'لم يتم تحديد المعلم' : 'Teacher not identified');
      return;
    }
    if (_selectedSubjectId == null ||
        _selectedGradeId == null ||
        _selectedClassroomId == null ||
        _selectedSectionId == null) {
      _showError(_EvaluationStrings.chooseFilters(context));
      return;
    }

    final evaluations = _studentLevels.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) {
          final studentId = entry.key;
          final level = entry.value;
          return {
            'student_id': studentId,
            'teacher_id': _teacherId,
            'subject_id': int.parse(_selectedSubjectId!),
            'grade_id': int.parse(_selectedGradeId!),
            'classroom_id': int.parse(_selectedClassroomId!),
            'section_id': int.parse(_selectedSectionId!),
            'evaluation_level': level,
            'notes': _studentNotes[studentId]?.text ?? '',
            'month': _selectedMonth,
            'year': _selectedYear,
          };
        })
        .toList();

    if (evaluations.isEmpty) {
      _showError(appIsArabic(context) ? 'اختر مستوى لطالب واحد على الأقل' : 'Select a level for at least one student');
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.post('/evaluations/bulk', data: {'evaluations': evaluations});
      _studentLevels.clear();
      for (final controller in _studentNotes.values) {
        controller.clear();
      }
      await _loadEvaluations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_EvaluationStrings.savedSuccessfully(context))),
        );
      }
    } catch (error) {
      _showError(ApiService.failureFrom(error).message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteEvaluation(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_EvaluationStrings.confirmDelete(context)),
        content: Text(_EvaluationStrings.confirmDeleteMessage(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_EvaluationStrings.cancel(context)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_EvaluationStrings.delete(context)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _api.delete('/evaluations/$id');
      await _loadEvaluations();
    } catch (error) {
      _showError(ApiService.failureFrom(error).message);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    for (final controller in _studentNotes.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilterCard(context),
          const SizedBox(height: 16),
          _buildCreationArea(context),
          const SizedBox(height: 16),
          _buildEvaluationsList(context, languageCode),
        ],
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context) {
    try {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: .05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _EvaluationStrings.filter(context),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_loadingFilters)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_selectedGradeId != null || _selectedClassroomId != null ||
                    _selectedSectionId != null || _selectedSubjectId != null)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                    label: Text(appIsArabic(context) ? 'مسح' : 'Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: _EvaluationStrings.selectGrade(context),
                    value: _selectedGradeId,
                    options: _grades,
                    onChanged: _onGradeChanged,
                    icon: Icons.school_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdown(
                    label: _EvaluationStrings.selectClassroom(context),
                    value: _selectedClassroomId,
                    options: _classrooms,
                    onChanged: _onClassroomChanged,
                    icon: Icons.meeting_room_rounded,
                    enabled: _selectedGradeId != null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: _EvaluationStrings.selectSection(context),
                    value: _selectedSectionId,
                    options: _sections,
                    onChanged: _onSectionChanged,
                    icon: Icons.grid_view_rounded,
                    enabled: _selectedClassroomId != null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdown(
                    label: _EvaluationStrings.selectSubject(context),
                    value: _selectedSubjectId,
                    options: _subjects,
                    onChanged: (value) => setState(() {
                      _selectedSubjectId = value;
                      _studentLevels.clear();
                      _studentNotes.clear();
                    }),
                    icon: Icons.menu_book_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildIntDropdown(
                    label: _EvaluationStrings.month(context),
                    value: _selectedMonth,
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem<int>(
                        value: i + 1,
                        child: Text(_EvaluationStrings.monthName(context, i + 1)),
                      ),
                    ),
                    onChanged: (value) => setState(() {
                      _selectedMonth = value ?? 1;
                      _studentLevels.clear();
                      _studentNotes.clear();
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildIntDropdown(
                    label: _EvaluationStrings.year(context),
                    value: _selectedYear,
                    items: List.generate(
                      6,
                      (i) {
                        final year = DateTime.now().year - i;
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text('$year'),
                        );
                      },
                    ),
                    onChanged: (value) => setState(() {
                      _selectedYear = value ?? DateTime.now().year;
                      _studentLevels.clear();
                      _studentNotes.clear();
                    }),
                  ),
                ),
              ],
            ),
            if (!_loadingFilters && _teacherAssignments.isEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.coral.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppTheme.coral),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        appIsArabic(context)
                            ? 'لا توجد أقسام مسندة لهذا المعلم.'
                            : 'No sections are assigned to this teacher.',
                        style: const TextStyle(color: AppTheme.coral, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _loadEvaluations,
                icon: const Icon(Icons.filter_list, size: 18, color: Colors.white),
                label: Text(
                  _EvaluationStrings.apply(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('[Evaluations] _buildFilterCard error: $error\n$stackTrace');
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.coral, size: 48),
              const SizedBox(height: 12),
              Text(
                'Filter card error: ${ApiService.failureFrom(error).message}',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCreationArea(BuildContext context) {
    final filtersComplete = _selectedGradeId != null &&
        _selectedClassroomId != null &&
        _selectedSectionId != null &&
        _selectedSubjectId != null;

    if (!filtersComplete) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.touch_app_rounded, color: AppTheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _EvaluationStrings.selectFiltersHint(context),
                  style: const TextStyle(color: AppTheme.muted, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildBulkEvaluationCard(context);
  }

  Widget _buildBulkEvaluationCard(BuildContext context) {
    if (_students.isEmpty && !_loading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              _EvaluationStrings.noData(context),
              style: const TextStyle(color: AppTheme.muted),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _EvaluationStrings.evaluateAll(context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _EvaluationStrings.evaluateAllHint(context),
              style: const TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const LoadingShimmer()
            else
              ..._students.map((student) => _buildStudentEvaluationRow(context, student)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _submitBulk,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_EvaluationStrings.save(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentEvaluationRow(BuildContext context, FormOption student) {
    final studentId = int.parse(student.value);
    final level = _studentLevels[studentId] ?? '';
    final hasEvaluation = level.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  student.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasEvaluation
                      ? AppTheme.success.withValues(alpha: .12)
                      : AppTheme.muted.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasEvaluation
                      ? _EvaluationStrings.evaluated(context)
                      : _EvaluationStrings.notEvaluated(context),
                  style: TextStyle(
                    color: hasEvaluation ? AppTheme.success : AppTheme.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              _levelChoiceChip(context, studentId, level, 'bad', AppTheme.danger),
              _levelChoiceChip(context, studentId, level, 'good', AppTheme.warning),
              _levelChoiceChip(context, studentId, level, 'very_good', AppTheme.primary),
              _levelChoiceChip(context, studentId, level, 'excellent', AppTheme.success),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _studentNotes[studentId],
            decoration: InputDecoration(
              labelText: _EvaluationStrings.notes(context),
              prefixIcon: const Icon(Icons.notes_rounded),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _levelChoiceChip(
    BuildContext context,
    int studentId,
    String selectedLevel,
    String level,
    Color color,
  ) {
    final isSelected = selectedLevel == level;
    return ChoiceChip(
      label: Text(_EvaluationStrings.levelLabel(context, level)),
      selected: isSelected,
      selectedColor: color.withValues(alpha: .16),
      checkmarkColor: color,
      side: BorderSide(color: isSelected ? color : const Color(0xffe3e8fb)),
      labelStyle: TextStyle(
        color: isSelected ? color : AppTheme.ink,
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
      ),
      onSelected: (_) => setState(() => _studentLevels[studentId] = level),
    );
  }

  Widget _buildEvaluationsList(BuildContext context, String languageCode) {
    if (_loading && _evaluations.isEmpty) {
      return const LoadingShimmer();
    }

    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _loadEvaluations,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(_EvaluationStrings.retry(context)),
              ),
            ],
          ),
        ),
      );
    }

    if (_evaluations.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.star_outline_rounded, size: 48, color: AppTheme.muted),
              const SizedBox(height: 12),
              Text(
                _EvaluationStrings.noData(context),
                style: const TextStyle(color: AppTheme.muted),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _EvaluationStrings.evaluations(context),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        ..._evaluations.map((evaluation) => _buildEvaluationCard(context, evaluation, languageCode)),
      ],
    );
  }

  Widget _buildEvaluationCard(BuildContext context, dynamic evaluation, String languageCode) {
    final raw = Map<String, dynamic>.from(evaluation as Map);
    final level = '${raw['evaluation_level']}';
    final color = _levelColor(level);
    final studentName = _displayName(raw['student'], languageCode: languageCode);
    final subjectName = _displayName(raw['subject'], languageCode: languageCode);
    final month = raw['month'] as int? ?? 0;
    final year = raw['year'] as int? ?? 0;
    final id = raw['id'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    studentName,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _EvaluationStrings.levelLabel(context, level),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$subjectName · ${_EvaluationStrings.monthName(context, month)} $year',
              style: const TextStyle(color: AppTheme.muted),
            ),
            if (raw['notes'] != null && '${raw['notes']}'.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${raw['notes']}'),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: appIsArabic(context) ? Alignment.centerLeft : Alignment.centerRight,
              child: IconButton(
                onPressed: () => _deleteEvaluation(id),
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.coral),
                tooltip: _EvaluationStrings.delete(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _levelColor(String level) {
    return switch (level) {
      'bad' => AppTheme.danger,
      'good' => AppTheme.warning,
      'very_good' => AppTheme.primary,
      'excellent' => AppTheme.success,
      _ => AppTheme.muted,
    };
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<FormOption> options,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey('${label}_$value'),
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: 280,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
      items: [
        DropdownMenuItem(value: null, child: Text(_EvaluationStrings.all(context))),
        for (final option in options)
          DropdownMenuItem(
            value: option.value,
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _buildIntDropdown({
    required String label,
    required int value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      key: ValueKey('${label}_$value'),
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: 280,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

class ParentEvaluationsContent extends StatefulWidget {
  const ParentEvaluationsContent({super.key});

  @override
  State<ParentEvaluationsContent> createState() =>
      _ParentEvaluationsContentState();
}

class _ParentEvaluationsContentState extends State<ParentEvaluationsContent> {
  late final ApiService _api;
  Map<String, dynamic>? _reportData;
  bool _loading = true;
  String? _error;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final Set<int> _expandedStudentIds = {};

  @override
  void initState() {
    super.initState();
    _api = context.read<SessionController>().api;
    context.read<AppState>().addListener(_onSelectedChildChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  @override
  void dispose() {
    context.read<AppState>().removeListener(_onSelectedChildChanged);
    super.dispose();
  }

  void _onSelectedChildChanged() => _loadReport();

  Future<void> _loadReport() async {
    final selectedChildId = context.read<AppState>().selectedChildId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      const path = '/evaluations/report/parent';
      final fullUrl = '${_api.dio.options.baseUrl}$path?month=$_selectedMonth&year=$_selectedYear';
      debugPrint('[ParentEvaluations] ===== REQUEST =====');
      debugPrint('[ParentEvaluations] baseUrl=${_api.dio.options.baseUrl}');
      debugPrint('[ParentEvaluations] fullUrl=$fullUrl');
      debugPrint('[ParentEvaluations] month=$_selectedMonth year=$_selectedYear');
      debugPrint('[ParentEvaluations] =================');

      final body = await _api.get(
        path,
        query: {
          'month': _selectedMonth,
          'year': _selectedYear,
          if (selectedChildId != null) 'student_id': selectedChildId,
        },
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );

      debugPrint('[ParentEvaluations] ===== RESPONSE =====');
      debugPrint('[ParentEvaluations] success=${body['success']}');
      debugPrint('[ParentEvaluations] message=${body['message']}');
      debugPrint('[ParentEvaluations] data runtimeType=${body['data']?.runtimeType}');
      if (body['data'] is Map) {
        final dataKeys = (body['data'] as Map).keys.toList();
        debugPrint('[ParentEvaluations] data keys=$dataKeys');
      }
      debugPrint('[ParentEvaluations] ==================');

      try {
        _reportData = body['data'] is Map ? Map<String, dynamic>.from(body['data']) : null;
        debugPrint('[ParentEvaluations] parsed _reportData keys=${_reportData?.keys.toList()}');
      } catch (parseError, parseStack) {
        debugPrint('[ParentEvaluations] ===== PARSE ERROR =====');
        debugPrint('[ParentEvaluations] parseError=$parseError');
        debugPrint('[ParentEvaluations] parseStack=$parseStack');
        debugPrint('[ParentEvaluations] =====================');
        rethrow;
      }
    } on FormatException catch (error, stackTrace) {
      _logDetailedError(error, stackTrace);
      _error = 'Server returned invalid JSON. Please check the server response format.';
      // Try to fetch the raw response body so we can see what corrupted the JSON.
      _fetchRawResponseForDiagnostics();
    } catch (error, stackTrace) {
      _logDetailedError(error, stackTrace);
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _logDetailedError(Object error, StackTrace stackTrace) {
    debugPrint('[ParentEvaluations] ===== LOAD ERROR =====');
    debugPrint('[ParentEvaluations] error runtimeType: ${error.runtimeType}');
    debugPrint('[ParentEvaluations] error toString: $error');
    if (error is DioException) {
      debugPrint('[ParentEvaluations] dio type: ${error.type}');
      debugPrint('[ParentEvaluations] dio message: ${error.message}');
      debugPrint('[ParentEvaluations] dio error: ${error.error}');
      debugPrint('[ParentEvaluations] request path: ${error.requestOptions.path}');
      debugPrint('[ParentEvaluations] request baseUrl: ${error.requestOptions.baseUrl}');
      debugPrint('[ParentEvaluations] request full uri: ${error.requestOptions.uri}');
      debugPrint('[ParentEvaluations] request headers: ${error.requestOptions.headers}');
      debugPrint('[ParentEvaluations] response status: ${error.response?.statusCode}');
      try {
        final responseData = error.response?.data;
        if (responseData != null) {
          debugPrint('[ParentEvaluations] response data runtimeType: ${responseData.runtimeType}');
          debugPrint('[ParentEvaluations] response data: $responseData');
        } else {
          debugPrint('[ParentEvaluations] response data: null');
        }
      } catch (e) {
        debugPrint('[ParentEvaluations] response data print failed: $e');
      }
    }
    debugPrint('[ParentEvaluations] stackTrace: $stackTrace');
    debugPrint('[ParentEvaluations] ====================');
  }

  Future<void> _fetchRawResponseForDiagnostics() async {
    try {
      final response = await _api.dio.get<String>(
        '/evaluations/report/parent',
        queryParameters: {'month': _selectedMonth, 'year': _selectedYear},
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          responseType: ResponseType.plain,
        ),
      );
      final raw = response.data ?? '';
      debugPrint('[ParentEvaluations] ===== RAW RESPONSE START =====');
      debugPrint('[ParentEvaluations] raw length=${raw.length}');
      if (raw.length > 500) {
        debugPrint('[ParentEvaluations] raw head: ${raw.substring(0, 250)}');
        debugPrint('[ParentEvaluations] raw tail: ${raw.substring(raw.length - 250)}');
      } else {
        debugPrint('[ParentEvaluations] raw body: $raw');
      }
      debugPrint('[ParentEvaluations] ===== RAW RESPONSE END =====');
    } catch (e) {
      debugPrint('[ParentEvaluations] raw fetch failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final selectedChildId = context.watch<AppState>().selectedChildId;
    final allChildren = _reportData?['children'] as List<dynamic>? ?? [];
    final children = selectedChildId == null
        ? allChildren
        : allChildren
            .where((c) => c is Map && c['id'] == selectedChildId)
            .toList();

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 150),
      children: [
        _buildFilterBar(context),
        const SizedBox(height: 16),
        if (_loading)
          const LoadingShimmer()
        else if (_error != null)
          _buildErrorCard(context)
        else if (children.isEmpty)
          _buildEmptyChildrenCard(context)
        else ...[
          _buildOverallStatsCard(context),
          const SizedBox(height: 24),
          _buildChildrenList(context, children, languageCode),
        ],
      ],
    );
  }

  Widget _buildOverallStatsCard(BuildContext context) {
    final stats = _reportData?['overall_statistics'] as Map<String, dynamic>?;
    if (stats == null) return const SizedBox.shrink();

    final total = stats['total'] ?? 0;
    final bad = stats['bad'] ?? 0;
    final good = stats['good'] ?? 0;
    final veryGood = stats['very_good'] ?? 0;
    final excellent = stats['excellent'] ?? 0;
    final average = stats['average_level'] ?? 0;

    final items = [
      _StatItemData(
        label: _EvaluationStrings.levelLabel(context, 'bad'),
        value: bad,
        color: AppTheme.danger,
      ),
      _StatItemData(
        label: _EvaluationStrings.levelLabel(context, 'good'),
        value: good,
        color: AppTheme.warning,
      ),
      _StatItemData(
        label: _EvaluationStrings.levelLabel(context, 'very_good'),
        value: veryGood,
        color: AppTheme.primary,
      ),
      _StatItemData(
        label: _EvaluationStrings.levelLabel(context, 'excellent'),
        value: excellent,
        color: AppTheme.success,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appIsArabic(context) ? 'الإحصائيات العامة' : 'Overall Statistics',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _bigStat(
                        context,
                        value: '$total',
                        label: _EvaluationStrings.total(context),
                        color: AppTheme.primary,
                      ),
                    ),
                    Container(width: 1, height: 50, color: const Color(0xffedf1ff)),
                    Expanded(
                      child: _bigStat(
                        context,
                        value: '$average',
                        label: _EvaluationStrings.average(context),
                        color: AppTheme.honey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: Color(0xffedf1ff)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      Expanded(child: _miniStat(context, items[i])),
                      if (i < items.length - 1)
                        Container(width: 1, height: 40, color: const Color(0xffedf1ff)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bigStat(BuildContext context, {required String value, required String label, required Color color}) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.muted, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _miniStat(BuildContext context, _StatItemData item) {
    return Column(
      children: [
        Text(
          '${item.value}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: item.color,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          style: TextStyle(
            color: AppTheme.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final isAr = appIsArabic(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? 'تصفية حسب الشهر والسنة' : 'Filter by Month & Year',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _filterDropdown(
                    label: _EvaluationStrings.month(context),
                    value: _selectedMonth,
                    items: [
                      for (var i = 1; i <= 12; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text(_EvaluationStrings.monthName(context, i)),
                        ),
                    ],
                    onChanged: (value) => setState(() => _selectedMonth = value ?? DateTime.now().month),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _filterDropdown(
                    label: _EvaluationStrings.year(context),
                    value: _selectedYear,
                    items: [
                      for (var i = 0; i < 6; i++)
                        DropdownMenuItem(
                          value: DateTime.now().year - i,
                          child: Text('${DateTime.now().year - i}'),
                        ),
                    ],
                    onChanged: (value) => setState(() => _selectedYear = value ?? DateTime.now().year),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _loading ? null : _loadReport,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.filter_list_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cloud,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.muted, size: 20),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.ink),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final session = context.read<SessionController>();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.coral, size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${appIsArabic(context) ? 'عنوان الخادم' : 'Server URL'}: ${session.api.dio.options.baseUrl}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadReport,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_EvaluationStrings.retry(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChildrenCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.child_care_rounded, size: 48, color: AppTheme.muted),
            const SizedBox(height: 12),
            Text(
              appIsArabic(context)
                  ? 'لا يوجد أبناء مرتبطون بهذا الحساب.'
                  : 'No children are linked to this account.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenList(BuildContext context, List<dynamic> children, String languageCode) {
    final rawByStudent = _reportData?['evaluations_by_student'];
    final Map<String, dynamic> byStudent = rawByStudent is Map
        ? Map<String, dynamic>.from(rawByStudent)
        : {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appIsArabic(context) ? 'أبنائي' : 'My Children',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        for (final child in children)
          _buildChildCard(
            context,
            child is Map ? Map<String, dynamic>.from(child) : <String, dynamic>{},
            byStudent,
            languageCode,
          ),
      ],
    );
  }

  Widget _buildChildCard(
    BuildContext context,
    Map<String, dynamic> child,
    Map<String, dynamic> byStudent,
    String languageCode,
  ) {
    final studentId = child['id'] as int?;
    final isExpanded = studentId != null && _expandedStudentIds.contains(studentId);
    final studentData = studentId != null
        ? (byStudent['$studentId'] is Map ? Map<String, dynamic>.from(byStudent['$studentId']) : null)
        : null;
    final evaluations = studentData?['evaluations'] as List<dynamic>? ?? [];
    final studentStats = studentData?['statistics'] as Map<String, dynamic>?;
    final average = studentStats?['average_level'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: isExpanded
            ? const BorderSide(color: AppTheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: studentId == null
                ? null
                : () => setState(() {
                      if (isExpanded) {
                        _expandedStudentIds.remove(studentId);
                      } else {
                        _expandedStudentIds.add(studentId);
                      }
                    }),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Color(0xFF1E3C72), Color(0xFF2A52BE)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.child_care_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName(child, languageCode: languageCode),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_displayName(child['grade'], languageCode: languageCode)} · ${_displayName(child['classroom'], languageCode: languageCode)} · ${_displayName(child['section'], languageCode: languageCode)}',
                          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (average != 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${appIsArabic(context) ? 'متوسط' : 'Avg'} $average',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Icon(
                        isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: AppTheme.muted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: evaluations.isEmpty
                  ? _buildNoEvaluationsMessage(context)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final evaluation in evaluations)
                          _buildEvaluationTile(
                            context,
                            evaluation is Map
                                ? Map<String, dynamic>.from(evaluation)
                                : <String, dynamic>{},
                            languageCode,
                          ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoEvaluationsMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cloud,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              appIsArabic(context)
                  ? 'لا توجد تقييمات لهذا الشهر.'
                  : 'No evaluations for this month.',
              style: const TextStyle(color: AppTheme.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationTile(
    BuildContext context,
    Map<String, dynamic> raw,
    String languageCode,
  ) {
    final level = '${raw['evaluation_level']}';
    final subject = raw['subject'];
    final teacher = raw['teacher'];
    final notes = raw['notes'] as String?;
    final color = _levelColor(level);
    final isAr = appIsArabic(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffe8edff)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff3d4c8f).withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu_book_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  subject is Map
                      ? _displayName(Map<String, dynamic>.from(subject), languageCode: languageCode)
                      : '-',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _EvaluationStrings.levelLabel(context, level),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_rounded, size: 16, color: AppTheme.muted),
              const SizedBox(width: 6),
              Text(
                isAr ? 'المعلم: ' : 'Teacher: ',
                style: const TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
              Expanded(
                child: Text(
                  teacher is Map
                      ? _displayName(Map<String, dynamic>.from(teacher), languageCode: languageCode)
                      : '-',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.cloud,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded, size: 16, color: AppTheme.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      notes,
                      style: const TextStyle(color: AppTheme.ink, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _levelColor(String level) {
    return switch (level) {
      'bad' => AppTheme.danger,
      'good' => AppTheme.warning,
      'very_good' => AppTheme.primary,
      'excellent' => AppTheme.success,
      _ => AppTheme.muted,
    };
  }
}

class StudentEvaluationsContent extends StatefulWidget {
  const StudentEvaluationsContent({super.key});

  @override
  State<StudentEvaluationsContent> createState() =>
      _StudentEvaluationsContentState();
}

class _StudentEvaluationsContentState extends State<StudentEvaluationsContent> {
  late final ApiService _api;
  Map<String, dynamic>? _reportData;
  bool _loading = true;
  String? _error;
  int? _studentId;

  @override
  void initState() {
    super.initState();
    _studentId = context.read<SessionController>().authStorage.user?['id'] as int?;
    _api = context.read<SessionController>().api;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  Future<void> _loadReport() async {
    if (_studentId == null) {
      setState(() {
        _error = appIsArabic(context) ? 'لم يتم تحديد الطالب' : 'Student not identified';
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final body = await _api.get(
        '/evaluations/report/student/$_studentId',
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );
      _reportData = body['data'] is Map ? Map<String, dynamic>.from(body['data']) : null;
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 150),
      children: [
        if (_loading)
          const LoadingShimmer()
        else if (_error != null)
          _buildErrorCard(context)
        else if (_reportData != null)
          _buildReportContent(context, languageCode),
      ],
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _loadReport,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_EvaluationStrings.retry(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, String languageCode) {
    final evaluations = _reportData?['evaluations'] as List<dynamic>? ?? [];
    final stats = _reportData?['statistics'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stats != null) ...[
          _buildStatsCard(context, stats),
          const SizedBox(height: 16),
        ],
        if (evaluations.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  _EvaluationStrings.noData(context),
                  style: const TextStyle(color: AppTheme.muted),
                ),
              ),
            ),
          )
        else
          ...evaluations.map((evaluation) {
            final raw = Map<String, dynamic>.from(evaluation as Map);
            final level = '${raw['evaluation_level']}';
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _displayName(raw['subject'], languageCode: languageCode),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _levelColor(level).withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _EvaluationStrings.levelLabel(context, level),
                            style: TextStyle(
                              color: _levelColor(level),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_displayName(raw['teacher'], languageCode: languageCode)} · '
                      '${_EvaluationStrings.monthName(context, raw['month'] as int? ?? 1)} ${raw['year']}',
                      style: const TextStyle(color: AppTheme.muted),
                    ),
                    if (raw['notes'] != null && '${raw['notes']}'.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('${raw['notes']}'),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _EvaluationStrings.statistics(context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem(context, _EvaluationStrings.total(context), '${stats['total'] ?? 0}'),
                _statItem(
                  context,
                  _EvaluationStrings.average(context),
                  '${stats['average_level'] ?? 0}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
              ),
        ),
        Text(label, style: const TextStyle(color: AppTheme.muted)),
      ],
    );
  }

  Color _levelColor(String level) {
    return switch (level) {
      'bad' => AppTheme.danger,
      'good' => AppTheme.warning,
      'very_good' => AppTheme.primary,
      'excellent' => AppTheme.success,
      _ => AppTheme.muted,
    };
  }
}
