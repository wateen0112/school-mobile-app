import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/data/school_repository.dart';
import '../../core/localization/module_localization.dart';
import '../../core/models/app_models.dart';
import '../../core/network/api_service.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../widgets/shared_widgets.dart';

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

String _formatDate(String? dateStr) {
  if (dateStr == null) return '-';
  try {
    final dt = DateTime.parse(dateStr);
    return DateFormat('yyyy-MM-dd').format(dt);
  } catch (_) {
    return dateStr;
  }
}

class TeacherPaperExamsContent extends StatefulWidget {
  const TeacherPaperExamsContent({super.key});

  @override
  State<TeacherPaperExamsContent> createState() =>
      _TeacherPaperExamsContentState();
}

class _TeacherPaperExamsContentState extends State<TeacherPaperExamsContent> {
  late final ApiService _api;
  late final SchoolRepository _repository;

  List<SchoolRecord> _subjects = [];
  List<SchoolRecord> _exams = [];
  List<SchoolRecord> _students = [];

  String? _selectedSubjectId;
  bool _loadingSubjects = true;
  bool _loadingExams = false;
  bool _loadingStudents = false;
  bool _saving = false;
  String? _error;
  String? _selectedView; // null = list, 'create', 'marks'

  // Create form
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _examDate = '';
  String _maxScore = '100';

  // Marks form
  int? _selectedExamId;
  final Map<int, TextEditingController> _markControllers = {};
  final Map<int, TextEditingController> _markNotesControllers = {};

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionController>();
    _api = session.api;
    _repository = SchoolRepository(_api);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSubjects());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _markControllers.values) {
      c.dispose();
    }
    for (final c in _markNotesControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _loadingSubjects = true;
      _error = null;
    });
    try {
      final body = await _api.get('/teacher/paper-exams/subjects');
      final data = body['data'];
      final rawList = data is List ? data : [];
      _subjects = rawList
          .map((e) => SchoolRecord(
              id: e['id'] is int ? e['id'] : int.tryParse('${e['id']}'),
              raw: Map<String, dynamic>.from(e)))
          .toList();
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _loadingSubjects = false);
    }
  }

  Future<void> _loadExams() async {
    if (_selectedSubjectId == null) return;
    setState(() {
      _loadingExams = true;
      _error = null;
    });
    try {
      final body =
          await _api.get('/teacher/paper-exams/$_selectedSubjectId');
      final data = body['data'];
      final rawList = data is List ? data : [];
      _exams = rawList
          .map((e) => SchoolRecord(
              id: e['id'] is int ? e['id'] : int.tryParse('${e['id']}'),
              raw: Map<String, dynamic>.from(e)))
          .toList();
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _loadingExams = false);
    }
  }

  Future<void> _loadStudents(int examId) async {
    setState(() {
      _loadingStudents = true;
      _error = null;
    });
    try {
      final body = await _api.get('/paper-exams/$examId/students');
      final data = body['data'];
      final rawList = data is List ? data : [];
      _students = rawList
          .map((e) => SchoolRecord(
              id: e['id'] is int ? e['id'] : int.tryParse('${e['id']}'),
              raw: Map<String, dynamic>.from(e)))
          .toList();

      _markControllers.clear();
      _markNotesControllers.clear();
      for (final student in _students) {
        final sid = student.id;
        if (sid == null) continue;
        final existing = student.raw['marks_obtained'];
        _markControllers[sid] = TextEditingController(
            text: existing != null ? '$existing' : '');
        _markNotesControllers[sid] = TextEditingController(
            text: student.raw['mark_notes'] ?? '');
      }

      _selectedExamId = examId;
      _selectedView = 'marks';
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

  Future<void> _createExam() async {
    if (_selectedSubjectId == null ||
        _titleCtrl.text.trim().isEmpty ||
        _examDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(appIsArabic(context)
              ? 'يرجى إدخال العنوان والتاريخ واختيار المادة'
              : 'Please fill in title, date, and select a subject')));
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Find the subject to get grade/classroom/section info
      final subject = _subjects.firstWhere(
          (s) => '${s.id}' == _selectedSubjectId,
          orElse: () => _subjects.first);
      final subjectRaw = subject.raw;

      final body = await _api.post('/paper-exams', data: {
        'title': _titleCtrl.text.trim(),
        'exam_date': _examDate,
        'subject_id': int.tryParse(_selectedSubjectId!) ?? 0,
        'teacher_id': context.read<SessionController>().authStorage.user?['id'] ?? 0,
        'grade_id': subjectRaw['grade_id'] ?? subjectRaw['Grade_id'] ?? 1,
        'classroom_id': subjectRaw['classroom_id'] ?? subjectRaw['Classroom_id'] ?? 1,
        'section_id': subjectRaw['section_id'] ?? 1,
        'max_score': double.tryParse(_maxScore) ?? 100,
        'notes': _notesCtrl.text.trim(),
      });

      _titleCtrl.clear();
      _notesCtrl.clear();
      _examDate = '';
      _maxScore = '100';
      _selectedView = null;
      await _loadExams();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam created successfully')));
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveMarks() async {
    if (_selectedExamId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final marks = _students.where((s) => s.id != null).map((s) {
        final sid = s.id!;
        return {
          'student_id': sid,
          'marks_obtained': double.tryParse(
                  _markControllers[sid]?.text.trim() ?? '') ??
              0,
          'notes': _markNotesControllers[sid]?.text.trim() ?? '',
        };
      }).toList();

      await _api.post('/paper-exams/$_selectedExamId/marks', data: {
        'marks': marks,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marks saved successfully')));
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publishExam(int examId) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Publish Results',
      message:
          'Are you sure? Notifications will be sent to students and parents.',
    );
    if (confirmed != true) return;

    try {
      await _api.post('/paper-exams/$examId/publish');
      await _loadExams();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Results published!')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.failureFrom(error).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isArabic = languageCode == 'ar';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
      children: [
        // Subject selector
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isArabic ? 'الاختبارات الورقية' : 'Paper Exams',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSubjectId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText:
                        isArabic ? 'المادة الدراسية' : 'Subject',
                    prefixIcon: const Icon(Icons.menu_book_rounded),
                  ),
                  items: [
                    for (final subject in _subjects)
                      DropdownMenuItem(
                        value: '${subject.id}',
                        child: Text(_displayName(subject.raw,
                            languageCode: languageCode)),
                      ),
                  ],
                  onChanged: _loadingSubjects
                      ? null
                      : (value) {
                          setState(() {
                            _selectedSubjectId = value;
                            _selectedView = null;
                            _exams = [];
                          });
                          _loadExams();
                        },
                ),
                if (_loadingSubjects) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(minHeight: 3),
                ],
              ],
            ),
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline_rounded,
                  color: AppTheme.coral),
              title: Text(_error!),
            ),
          ),
        ],

        if (_selectedSubjectId != null && _selectedView != 'create' && _selectedView != 'marks') ...[
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    _examDate = DateTime.now().toIso8601String().split('T')[0];
                    setState(() => _selectedView = 'create');
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: Text(isArabic ? 'إضافة اختبار' : 'Create Exam'),
                ),
              ),
            ],
          ),
        ],

        // Create form
        if (_selectedView == 'create') ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isArabic ? 'اختبار جديد' : 'New Exam',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'عنوان الاختبار' : 'Exam Title',
                      prefixIcon: const Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(text: _examDate),
                    decoration: InputDecoration(
                      labelText: isArabic ? 'تاريخ الاختبار' : 'Exam Date',
                      prefixIcon: const Icon(Icons.calendar_today_rounded),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _examDate =
                            picked.toIso8601String().split('T')[0]);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: TextEditingController(text: _maxScore),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText:
                          isArabic ? 'الدرجة العظمى' : 'Max Score',
                      prefixIcon: const Icon(Icons.score_rounded),
                    ),
                    onChanged: (v) => _maxScore = v,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'ملاحظات' : 'Notes',
                      prefixIcon: const Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _createExam,
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(isArabic ? 'حفظ' : 'Save'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _selectedView = null),
                          icon: const Icon(Icons.close_rounded),
                          label: Text(isArabic ? 'إلغاء' : 'Cancel'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],

        // Exam list
        if (_selectedSubjectId != null && _selectedView != 'create' && _selectedView != 'marks') ...[
          const SizedBox(height: 16),
          if (_loadingExams)
            const LoadingShimmer()
          else if (_exams.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    isArabic
                        ? 'لا توجد اختبارات لهذه المادة'
                        : 'No exams for this subject',
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                ),
              ),
            )
          else
            for (final exam in _exams) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
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
                                  exam.raw['title'] ?? '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${isArabic ? 'التاريخ' : 'Date'}: ${_formatDate(exam.raw['exam_date'])}',
                                  style: const TextStyle(
                                      color: AppTheme.muted,
                                      fontSize: 13),
                                ),
                                Text(
                                  '${isArabic ? 'الدرجة' : 'Score'}: ${exam.raw['max_score'] ?? 100}',
                                  style: const TextStyle(
                                      color: AppTheme.muted,
                                      fontSize: 13),
                                ),
                                Text(
                                  '${isArabic ? 'الطلاب' : 'Students'}: ${exam.raw['marks_count'] ?? 0}',
                                  style: const TextStyle(
                                      color: AppTheme.muted,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: exam.raw['status'] == 'published'
                                      ? Colors.green.shade50
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  exam.raw['status'] == 'published'
                                      ? (isArabic ? 'منشور' : 'Published')
                                      : (isArabic ? 'مسودة' : 'Draft'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        exam.raw['status'] == 'published'
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (exam.raw['status'] != 'published')
                                TextButton.icon(
                                  onPressed: () => _publishExam(exam.id!),
                                  icon: const Icon(Icons.send_rounded,
                                      size: 16),
                                  label: Text(
                                    isArabic ? 'نشر' : 'Publish',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FilledButton.tonalIcon(
                        onPressed: () => _loadStudents(exam.id!),
                        icon: const Icon(Icons.edit_note_rounded),
                        label: Text(
                            isArabic ? 'إدخال العلامات' : 'Enter Marks'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],

        // Marks entry view
        if (_selectedView == 'marks') ...[
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() => _selectedView = null);
                },
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'إدخال العلامات' : 'Enter Marks',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingStudents)
            const LoadingShimmer()
          else if (_students.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    isArabic
                        ? 'لا يوجد طلاب مرتبطون بهذه المادة'
                        : 'No students linked to this subject',
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                ),
              ),
            )
          else
            for (final student in _students) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _displayName(student.raw,
                                  languageCode: languageCode),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: student.id != null
                                  ? _markControllers[student.id]
                                  : null,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: '0',
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: student.id != null
                            ? _markNotesControllers[student.id]
                            : null,
                        decoration: InputDecoration(
                          hintText: isArabic
                              ? 'ملاحظات (اختياري)'
                              : 'Notes (optional)',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          if (_students.isNotEmpty) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _saveMarks,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(isArabic ? 'حفظ العلامات' : 'Save Marks'),
            ),
          ],
        ],
      ],
    );
  }
}
