import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/school_repository.dart';
import '../../core/localization/module_localization.dart';
import '../../core/models/app_models.dart';
import '../../core/network/api_service.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/loading_shimmer.dart';

class _Strings {
  const _Strings._();

  static String filter(BuildContext context) =>
      appIsArabic(context) ? 'تصفية الطلاب' : 'Filter students';

  static String selectGrade(BuildContext context) =>
      appIsArabic(context) ? 'المرحلة الدراسية' : 'Grade';

  static String selectClassroom(BuildContext context) =>
      appIsArabic(context) ? 'الفصل الدراسي' : 'Classroom';

  static String selectSection(BuildContext context) =>
      appIsArabic(context) ? 'الشعبة' : 'Section';

  static String selectSubject(BuildContext context) =>
      appIsArabic(context) ? 'المادة الدراسية' : 'Subject';

  static String all(BuildContext context) =>
      appIsArabic(context) ? 'الكل' : 'All';

  static String apply(BuildContext context) =>
      appIsArabic(context) ? 'تطبيق' : 'Apply';

  static String clear(BuildContext context) =>
      appIsArabic(context) ? 'مسح' : 'Clear';

  static String students(BuildContext context) =>
      appIsArabic(context) ? 'الطلاب' : 'Students';

  static String evaluateSelected(BuildContext context) => appIsArabic(context)
      ? 'تقييم المحدد'
      : 'Evaluate selected';

  static String selectedCount(BuildContext context, int count) =>
      appIsArabic(context) ? 'مختار: $count' : 'Selected: $count';

  static String noStudents(BuildContext context) =>
      appIsArabic(context) ? 'لا يوجد طلاب' : 'No students found';

  static String month(BuildContext context) =>
      appIsArabic(context) ? 'الشهر' : 'Month';

  static String year(BuildContext context) =>
      appIsArabic(context) ? 'السنة' : 'Year';

  static String notes(BuildContext context) =>
      appIsArabic(context) ? 'ملاحظات (اختياري)' : 'Notes (optional)';

  static String evaluationLevel(BuildContext context) =>
      appIsArabic(context) ? 'مستوى التقييم' : 'Evaluation level';

  static String save(BuildContext context) =>
      appIsArabic(context) ? 'حفظ' : 'Save';

  static String savedSuccessfully(BuildContext context) =>
      appIsArabic(context) ? 'تم الحفظ بنجاح' : 'Saved successfully';

  static String cancel(BuildContext context) =>
      appIsArabic(context) ? 'إلغاء' : 'Cancel';

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
          ]
        : [
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
    return names[month - 1];
  }

  static String chooseSubjectAndSection(BuildContext context) =>
      appIsArabic(context)
          ? 'اختر المادة والشعبة لعرض الطلاب'
          : 'Choose a subject and section to view students';

  static String evaluateFormTitle(BuildContext context) =>
      appIsArabic(context) ? 'تقييم الطلاب' : 'Evaluate students';

  static String levelRequired(BuildContext context) =>
      appIsArabic(context)
          ? 'اختر مستوى التقييم'
          : 'Select an evaluation level';
}

String _displayName(dynamic value, {String languageCode = 'en'}) {
  if (value == null) return '-';
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final direct = map[languageCode] ??
        map['Name'] ??
        map['Name_Section'] ??
        map['Name_Class'] ??
        map['name'] ??
        map['Name_en'] ??
        map['Name_ar'] ??
        map['Name_class_en'] ??
        map['Name_class_ar'] ??
        map['name_en'] ??
        map['name_ar'] ??
        map.values.firstOrNull;
    if (direct != null) return _displayName(direct, languageCode: languageCode);
  }
  return '$value';
}

dynamic _lookup(Map<String, dynamic> map, String key) {
  if (map.containsKey(key)) return map[key];
  final lower = key.toLowerCase();
  for (final entry in map.entries) {
    if (entry.key.toLowerCase() == lower) return entry.value;
  }
  return null;
}

class TeacherStudentsEvaluationContent extends StatefulWidget {
  const TeacherStudentsEvaluationContent({super.key});

  @override
  State<TeacherStudentsEvaluationContent> createState() =>
      _TeacherStudentsEvaluationContentState();
}

class _TeacherStudentsEvaluationContentState
    extends State<TeacherStudentsEvaluationContent> {
  late final ApiService _api;
  late final SchoolRepository _repository;
  int? _teacherId;

  List<Map<String, dynamic>> _teacherAssignments = const [];
  List<FormOption> _gradeOptions = [];
  List<FormOption> _classroomOptions = [];
  List<FormOption> _sectionOptions = [];
  List<FormOption> _subjectOptions = [];
  List<SchoolRecord> _students = [];

  String? _selectedGradeId;
  String? _selectedClassroomId;
  String? _selectedSectionId;
  String? _selectedSubjectId;

  final Set<int> _selectedStudentIds = {};

  bool _loadingFilters = true;
  bool _loadingStudents = false;
  String? _error;

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
    await _loadAssignments();
  }

  /// Load the teacher's section/subject assignments once. Every filter option
  /// and the student list are derived from these pairs, so the screen only ever
  /// offers combinations the teacher is actually assigned to teach.
  Future<void> _loadAssignments() async {
    setState(() => _loadingFilters = true);
    try {
      _teacherAssignments = await _repository.teacherAssignments();
      _error = null;
      _rebuildFilterOptions();
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
      _teacherAssignments = const [];
    } finally {
      if (mounted) setState(() => _loadingFilters = false);
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedSectionId == null && _selectedSubjectId == null) {
      setState(() => _students = []);
      return;
    }

    setState(() => _loadingStudents = true);
    try {
      final records = await _repository.teacherStudents(
        gradeId: _selectedGradeId,
        classroomId: _selectedClassroomId,
        sectionId: _selectedSectionId,
        subjectId: _selectedSubjectId,
      );
      _students = records;
      _selectedStudentIds.clear();
      _error = null;
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
      _students = [];
    } finally {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

  /// Rebuild every filter option from the loaded assignments, honouring the
  /// currently selected grade/classroom/section/subject so the dropdowns always
  /// cascade and never offer an unassigned combination.
  void _rebuildFilterOptions() {
    _buildGradeOptions();
    _buildClassroomOptions();
    _buildSectionOptions();
    _buildSubjectOptions();
  }

  /// True when the assignment matches the current section/subject selection.
  bool _assignmentMatches(Map<String, dynamic> assignment) {
    if (_selectedSectionId != null &&
        '${assignment['section_id']}' != _selectedSectionId) {
      return false;
    }
    if (_selectedSubjectId != null &&
        '${assignment['subject_id']}' != _selectedSubjectId) {
      return false;
    }
    return true;
  }

  Map<String, dynamic>? _sectionOf(Map<String, dynamic> assignment) {
    final section = _lookup(assignment, 'section');
    return section is Map ? Map<String, dynamic>.from(section) : null;
  }

  void _buildGradeOptions() {
    final languageCode = Localizations.localeOf(context).languageCode;
    final seen = <String>{};
    _gradeOptions = [];
    for (final assignment in _teacherAssignments) {
      if (!_assignmentMatches(assignment)) continue;
      final section = _sectionOf(assignment);
      if (section == null) continue;
      final grade = _lookup(section, 'Grades');
      if (grade is! Map) continue;
      final gradeId = '${grade['id']}';
      if (seen.add(gradeId)) {
        _gradeOptions.add(FormOption(
          value: gradeId,
          label: _displayName(grade, languageCode: languageCode),
        ));
      }
    }
  }

  void _buildClassroomOptions() {
    final languageCode = Localizations.localeOf(context).languageCode;
    final seen = <String>{};
    _classroomOptions = [];
    for (final assignment in _teacherAssignments) {
      if (!_assignmentMatches(assignment)) continue;
      final section = _sectionOf(assignment);
      if (section == null) continue;
      final grade = _lookup(section, 'Grades');
      final classroom = _lookup(section, 'My_classs');
      if (grade is! Map || classroom is! Map) continue;
      if (_selectedGradeId != null && '${grade['id']}' != _selectedGradeId) {
        continue;
      }
      final classroomId = '${classroom['id']}';
      if (seen.add(classroomId)) {
        _classroomOptions.add(FormOption(
          value: classroomId,
          label: _displayName(classroom, languageCode: languageCode),
        ));
      }
    }
  }

  void _buildSectionOptions() {
    final languageCode = Localizations.localeOf(context).languageCode;
    final seen = <String>{};
    _sectionOptions = [];
    for (final assignment in _teacherAssignments) {
      if (!_assignmentMatches(assignment)) continue;
      final section = _sectionOf(assignment);
      if (section == null) continue;
      final grade = _lookup(section, 'Grades');
      final classroom = _lookup(section, 'My_classs');
      if (_selectedGradeId != null &&
          (grade is! Map || '${grade['id']}' != _selectedGradeId)) {
        continue;
      }
      if (_selectedClassroomId != null &&
          (classroom is! Map || '${classroom['id']}' != _selectedClassroomId)) {
        continue;
      }
      final sectionId = '${section['id']}';
      if (seen.add(sectionId)) {
        _sectionOptions.add(FormOption(
          value: sectionId,
          label: _displayName(section, languageCode: languageCode),
        ));
      }
    }
  }

  void _buildSubjectOptions() {
    final languageCode = Localizations.localeOf(context).languageCode;
    final seen = <String>{};
    _subjectOptions = [];
    for (final assignment in _teacherAssignments) {
      final section = _sectionOf(assignment);
      if (section == null) continue;
      final grade = _lookup(section, 'Grades');
      final classroom = _lookup(section, 'My_classs');
      if (_selectedGradeId != null &&
          (grade is! Map || '${grade['id']}' != _selectedGradeId)) {
        continue;
      }
      if (_selectedClassroomId != null &&
          (classroom is! Map || '${classroom['id']}' != _selectedClassroomId)) {
        continue;
      }
      if (_selectedSectionId != null &&
          '${assignment['section_id']}' != _selectedSectionId) {
        continue;
      }
      final subject = _lookup(assignment, 'subject');
      if (subject is! Map) continue;
      final subjectId = '${subject['id']}';
      if (seen.add(subjectId)) {
        _subjectOptions.add(FormOption(
          value: subjectId,
          label: _displayName(subject, languageCode: languageCode),
        ));
      }
    }
  }

  void _onGradeChanged(String? value) {
    setState(() {
      _selectedGradeId = value;
      _selectedClassroomId = null;
      _selectedSectionId = null;
      _selectedSubjectId = null;
      _students = [];
      _selectedStudentIds.clear();
      _rebuildFilterOptions();
    });
  }

  void _onClassroomChanged(String? value) {
    setState(() {
      _selectedClassroomId = value;
      _selectedSectionId = null;
      _selectedSubjectId = null;
      _students = [];
      _selectedStudentIds.clear();
      _rebuildFilterOptions();
    });
  }

  void _onSectionChanged(String? value) {
    setState(() {
      _selectedSectionId = value;
      _selectedSubjectId = null;
      _students = [];
      _selectedStudentIds.clear();
      _rebuildFilterOptions();
    });
  }

  void _onSubjectChanged(String? value) {
    setState(() {
      _selectedSubjectId = value;
      _students = [];
      _selectedStudentIds.clear();
      // Selecting a subject narrows the other filters to the sections where
      // that subject is actually taught.
      if (value != null) _pruneFiltersForSubject(value);
      _rebuildFilterOptions();
    });
  }

  /// Drop a selected grade/classroom/section that the chosen subject is not
  /// taught in, so the filter state never contradicts the subject selection.
  void _pruneFiltersForSubject(String subjectId) {
    bool subjectIn(String sectionId, String? gradeId, String? classroomId) {
      for (final assignment in _teacherAssignments) {
        if ('${assignment['subject_id']}' != subjectId) continue;
        if (sectionId.isNotEmpty && '${assignment['section_id']}' != sectionId) {
          continue;
        }
        if (gradeId != null) {
          final section = _sectionOf(assignment);
          final grade = section == null ? null : _lookup(section, 'Grades');
          if (grade is! Map || '${grade['id']}' != gradeId) continue;
        }
        if (classroomId != null) {
          final section = _sectionOf(assignment);
          final classroom =
              section == null ? null : _lookup(section, 'My_classs');
          if (classroom is! Map || '${classroom['id']}' != classroomId) {
            continue;
          }
        }
        return true;
      }
      return false;
    }

    if (_selectedSectionId != null &&
        !subjectIn(_selectedSectionId!, _selectedGradeId, _selectedClassroomId)) {
      _selectedSectionId = null;
      _selectedClassroomId = null;
      _selectedGradeId = null;
      return;
    }
    if (_selectedClassroomId != null &&
        !subjectIn('', _selectedGradeId, _selectedClassroomId)) {
      _selectedClassroomId = null;
      _selectedGradeId = null;
      return;
    }
    if (_selectedGradeId != null && !subjectIn('', _selectedGradeId, null)) {
      _selectedGradeId = null;
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedGradeId = null;
      _selectedClassroomId = null;
      _selectedSectionId = null;
      _selectedSubjectId = null;
      _students = [];
      _selectedStudentIds.clear();
      _rebuildFilterOptions();
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openEvaluateForm() async {
    if (_selectedStudentIds.isEmpty) return;
    if (_selectedSectionId == null || _selectedSubjectId == null) {
      _showError(appIsArabic(context)
          ? 'اختر الشعبة والمادة أولاً'
          : 'Choose a section and subject first');
      return;
    }

    final selectedSection = _sectionOptions.firstWhere(
      (o) => o.value == _selectedSectionId,
      orElse: () => const FormOption(value: '', label: ''),
    );
    final selectedSubject = _subjectOptions.firstWhere(
      (o) => o.value == _selectedSubjectId,
      orElse: () => const FormOption(value: '', label: ''),
    );
    final selectedStudents = _students
        .where((s) => _selectedStudentIds.contains(s.id))
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .42),
      builder: (_) => _EvaluateSheet(
        teacherId: _teacherId,
        sectionId: int.parse(_selectedSectionId!),
        subjectId: int.parse(_selectedSubjectId!),
        sectionName: selectedSection.label,
        subjectName: selectedSubject.label,
        students: selectedStudents,
        onSaved: () {
          setState(() => _selectedStudentIds.clear());
          _loadStudents();
        },
      ),
    );
  }

  String _optionLabel(Map<String, dynamic> raw, String languageCode) {
    final candidates = [
      'Name',
      'Name_en',
      'Name_ar',
      'Name_Section',
      'Name_Class',
      'name_en',
      'name_ar',
      'name',
      'title',
      'id',
    ];
    for (final key in candidates) {
      final value = raw[key];
      if (value == null) continue;
      return _displayName(value, languageCode: languageCode);
    }
    return '${raw['id']}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilterCard(context),
        const SizedBox(height: 16),
        _buildStudentsArea(context),
      ],
    );
  }

  Widget _buildFilterCard(BuildContext context) {
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
                  _Strings.filter(context),
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
              else if (_selectedGradeId != null ||
                  _selectedClassroomId != null ||
                  _selectedSectionId != null ||
                  _selectedSubjectId != null)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                  label: Text(_Strings.clear(context)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _filterDropdown(
                  label: _Strings.selectGrade(context),
                  value: _selectedGradeId,
                  options: _gradeOptions,
                  onChanged: _onGradeChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _filterDropdown(
                  label: _Strings.selectClassroom(context),
                  value: _selectedClassroomId,
                  options: _classroomOptions,
                  onChanged: _onClassroomChanged,
                  enabled: _selectedGradeId != null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _filterDropdown(
                  label: _Strings.selectSection(context),
                  value: _selectedSectionId,
                  options: _sectionOptions,
                  onChanged: _onSectionChanged,
                  enabled: _selectedClassroomId != null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _filterDropdown(
                  label: _Strings.selectSubject(context),
                  value: _selectedSubjectId,
                  options: _subjectOptions,
                  onChanged: _onSubjectChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  _loadingFilters || _loadingStudents ? null : _loadStudents,
              icon: const Icon(Icons.filter_list, size: 18, color: Colors.white),
              label: Text(
                _Strings.apply(context),
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
  }

  Widget _filterDropdown({
    required String label,
    required String? value,
    required List<FormOption> options,
    required ValueChanged<String?> onChanged,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
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
        DropdownMenuItem(value: null, child: Text(_Strings.all(context))),
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

  Widget _buildStudentsArea(BuildContext context) {
    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _loadStudents,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(_Strings.clear(context)),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadingStudents) {
      return const LoadingShimmer();
    }

    if (_students.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _selectedSectionId == null && _selectedSubjectId == null
                  ? _Strings.chooseSubjectAndSection(context)
                  : _Strings.noStudents(context),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final languageCode = Localizations.localeOf(context).languageCode;

    return Expanded(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_Strings.students(context)} (${_students.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              if (_selectedStudentIds.isNotEmpty)
                Text(
                  _Strings.selectedCount(context, _selectedStudentIds.length),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ..._students.map((student) => _buildStudentTile(context, student, languageCode)),
          const SizedBox(height: 12),
          if (_selectedStudentIds.isNotEmpty)
            FilledButton.icon(
              onPressed: _openEvaluateForm,
              icon: const Icon(Icons.star_rounded),
              label: Text(_Strings.evaluateSelected(context)),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(
    BuildContext context,
    SchoolRecord student,
    String languageCode,
  ) {
    final studentId = student.id ?? 0;
    final raw = student.raw;
    final name = _optionLabel(raw, languageCode);
    final section = _displayName(raw['section'], languageCode: languageCode);
    final isSelected = _selectedStudentIds.contains(studentId);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedStudentIds.add(studentId);
            } else {
              _selectedStudentIds.remove(studentId);
            }
          });
        },
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          section,
          style: const TextStyle(color: AppTheme.muted),
        ),
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.school_rounded, color: AppTheme.primary),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppTheme.primary,
      ),
    );
  }
}

class _EvaluateSheet extends StatefulWidget {
  const _EvaluateSheet({
    required this.teacherId,
    required this.sectionId,
    required this.subjectId,
    required this.sectionName,
    required this.subjectName,
    required this.students,
    required this.onSaved,
  });

  final int? teacherId;
  final int sectionId;
  final int subjectId;
  final String sectionName;
  final String subjectName;
  final List<SchoolRecord> students;
  final VoidCallback onSaved;

  @override
  State<_EvaluateSheet> createState() => _EvaluateSheetState();
}

class _EvaluateSheetState extends State<_EvaluateSheet> {
  final _notesController = TextEditingController();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String? _selectedLevel;
  bool _saving = false;

  Future<void> _submit() async {
    if (_selectedLevel == null || _selectedLevel!.isEmpty) {
      _showError(_Strings.levelRequired(context));
      return;
    }
    if (widget.teacherId == null) {
      _showError(appIsArabic(context) ? 'لم يتم تحديد المعلم' : 'Teacher not identified');
      return;
    }

    final evaluations = widget.students.map((student) {
      final raw = student.raw;
      return {
        'student_id': student.id,
        'teacher_id': widget.teacherId,
        'subject_id': widget.subjectId,
        'grade_id': raw['Grade_id'] ?? raw['grade_id'],
        'classroom_id': raw['Classroom_id'] ?? raw['classroom_id'],
        'section_id': widget.sectionId,
        'evaluation_level': _selectedLevel,
        'notes': _notesController.text.trim(),
        'month': _selectedMonth,
        'year': _selectedYear,
      };
    }).toList();

    _saving = true;
    setState(() {});
    try {
      await context.read<SessionController>().api.post(
        '/evaluations/bulk',
        data: {'evaluations': evaluations},
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_Strings.savedSuccessfully(context))),
        );
        widget.onSaved();
      }
    } catch (error) {
      _showError(ApiService.failureFrom(error).message);
    } finally {
      _saving = false;
      if (mounted) setState(() {});
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isArabic = appIsArabic(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: media.viewInsets + EdgeInsets.only(bottom: media.padding.bottom + 18),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: media.size.width,
            maxHeight: media.size.height * .78,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 68, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _Strings.evaluateFormTitle(context),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.subjectName} · ${widget.sectionName}',
                            style: const TextStyle(color: AppTheme.muted),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: _selectedMonth,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: _Strings.month(context),
                                  ),
                                  items: [
                                    for (var i = 1; i <= 12; i++)
                                      DropdownMenuItem(
                                        value: i,
                                        child: Text(_Strings.monthName(context, i)),
                                      ),
                                  ],
                                  onChanged: (value) => setState(() => _selectedMonth = value ?? 1),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: _selectedYear,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: _Strings.year(context),
                                  ),
                                  items: [
                                    for (var i = 0; i < 6; i++)
                                      DropdownMenuItem(
                                        value: DateTime.now().year - i,
                                        child: Text('${DateTime.now().year - i}'),
                                      ),
                                  ],
                                  onChanged: (value) => setState(
                                    () => _selectedYear = value ?? DateTime.now().year,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _Strings.evaluationLevel(context),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _levelChoiceChip('bad', AppTheme.danger),
                              _levelChoiceChip('good', AppTheme.warning),
                              _levelChoiceChip('very_good', AppTheme.primary),
                              _levelChoiceChip('excellent', AppTheme.success),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: _Strings.notes(context),
                              prefixIcon: const Icon(Icons.notes_rounded),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _saving ? null : _submit,
                            icon: _saving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(_Strings.save(context)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: isArabic ? null : 12,
                    right: isArabic ? 12 : null,
                    child: IconButton.filledTonal(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: _Strings.cancel(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _levelChoiceChip(String level, Color color) {
    final isSelected = _selectedLevel == level;
    return ChoiceChip(
      label: Text(_Strings.levelLabel(context, level)),
      selected: isSelected,
      selectedColor: color.withValues(alpha: .16),
      checkmarkColor: color,
      side: BorderSide(color: isSelected ? color : const Color(0xffe3e8fb)),
      labelStyle: TextStyle(
        color: isSelected ? color : AppTheme.ink,
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
      ),
      onSelected: (_) => setState(() => _selectedLevel = level),
    );
  }
}
