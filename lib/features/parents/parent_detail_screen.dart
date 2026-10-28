import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/data/school_repository.dart';
import '../../core/localization/module_localization.dart';
import '../../core/models/app_models.dart';
import '../../core/network/api_service.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class ParentDetailScreen extends StatefulWidget {
  const ParentDetailScreen({super.key, required this.parentId});

  final int parentId;

  @override
  State<ParentDetailScreen> createState() => _ParentDetailScreenState();
}

class _ParentDetailScreenState extends State<ParentDetailScreen> {
  ApiService? _api;
  SchoolRecord? _parent;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = context.read<SessionController>().api;
    _load();
  }

  void _navigateBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/admin/parents');
    }
  }

  Future<void> _load() async {
    try {
      final body = await _api!.get('/parents/${widget.parentId}');
      final data = body['data'];
      if (data is Map) {
        _parent = SchoolRecord(
          id: int.tryParse('${data['id']}'),
          raw: Map<String, dynamic>.from(data),
        );
      }
    } catch (e) {
      try {
        final body = await _api!.get('/parents');
        final data = body['data'];
        if (data is List) {
          for (final item in data) {
            if (item is Map && int.tryParse('${item['id']}') == widget.parentId) {
              _parent = SchoolRecord(
                id: int.tryParse('${item['id']}'),
                raw: Map<String, dynamic>.from(item),
              );
              break;
            }
          }
        }
      } catch (_) {
        _error = ApiService.failureFrom(e).message;
      }
    }
    if (mounted) {
      setState(() {
        _loading = false;
        if (_parent == null && _error == null) {
          _error = 'Parent not found';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: Text(isArabic ? 'تفاصيل ولي الأمر' : 'Parent Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _navigateBack,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _parent == null) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: Text(isArabic ? 'تفاصيل ولي الأمر' : 'Parent Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _navigateBack,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.coral),
                const SizedBox(height: 16),
                Text(
                  _error ?? (isArabic ? 'غير موجود' : 'Not found'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _navigateBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(isArabic ? 'رجوع' : 'Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final raw = _parent!.raw;
    final name = displayValue(
      raw['Name_Father'] ?? raw['name'] ?? (isArabic ? 'ولي الأمر' : 'Parent'),
      languageCode: languageCode,
    );
    final email = raw['email'] ?? '-';
    final phone = raw['Phone_Father'] ?? '-';
    final address = displayValue(raw['Address_Father'] ?? '-', languageCode: languageCode);
    final nationalId = raw['National_ID_Father'] ?? '-';
    final passportId = raw['Passport_ID_Father'];
    final motherName = raw['Name_Mother'] != null
        ? displayValue(raw['Name_Mother'], languageCode: languageCode)
        : null;
    final nationalIdMother = raw['National_ID_Mother'];
    final phoneMother = raw['Phone_Mother'];
    final jobFather = raw['Job_Father'] != null
        ? displayValue(raw['Job_Father'], languageCode: languageCode)
        : null;
    final jobMother = raw['Job_Mother'] != null
        ? displayValue(raw['Job_Mother'], languageCode: languageCode)
        : null;
    final addressMother = raw['Address_Mother'] != null
        ? displayValue(raw['Address_Mother'], languageCode: languageCode)
        : null;
    final religion = displayValue(raw['religion'], languageCode: languageCode);
    final bloodType = displayValue(raw['blood_type'], languageCode: languageCode);
    final nationality = displayValue(raw['nationality'], languageCode: languageCode);
    final students = raw['students'] is List ? (raw['students'] as List) : const [];

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _navigateBack,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3C72), Color(0xFF2A52BE)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3C72).withValues(alpha: .3),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.family_restroom_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email.toString(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Father Info Card
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'بيانات الأب' : 'Father Information',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 20),
                  _infoRow(isArabic ? 'الاسم' : 'Name', name),
                  _infoRow(isArabic ? 'البريد الإلكتروني' : 'Email', email.toString()),
                  _infoRow(isArabic ? 'الهاتف' : 'Phone', phone.toString()),
                  _infoRow(isArabic ? 'الرقم القومي' : 'National ID', nationalId.toString()),
                  if (passportId != null)
                    _infoRow(isArabic ? 'جواز السفر' : 'Passport ID', passportId.toString()),
                  if (jobFather != null && jobFather.isNotEmpty)
                    _infoRow(isArabic ? 'الوظيفة' : 'Job', jobFather),
                  _infoRow(isArabic ? 'العنوان' : 'Address', address),
                  if (religion.isNotEmpty && religion != '-')
                    _infoRow(isArabic ? 'الديانة' : 'Religion', religion),
                  if (bloodType.isNotEmpty && bloodType != '-')
                    _infoRow(isArabic ? 'فصيلة الدم' : 'Blood Type', bloodType),
                  if (nationality.isNotEmpty && nationality != '-')
                    _infoRow(isArabic ? 'الجنسية' : 'Nationality', nationality),
                ],
              ),
            ),
          ),

          // Mother Info Card
          if (motherName != null || phoneMother != null || jobMother != null || nationalIdMother != null) ...[
            const SizedBox(height: 16),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'بيانات الأم' : 'Mother Information',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20),
                    if (motherName != null)
                      _infoRow(isArabic ? 'اسم الأم' : 'Mother Name', motherName),
                    if (nationalIdMother != null)
                      _infoRow(isArabic ? 'الرقم القومي للأم' : 'Mother National ID', nationalIdMother.toString()),
                    if (phoneMother != null)
                      _infoRow(isArabic ? 'هاتف الأم' : 'Mother Phone', phoneMother.toString()),
                    if (jobMother != null && jobMother.isNotEmpty)
                      _infoRow(isArabic ? 'وظيفة الأم' : 'Mother Job', jobMother),
                    if (addressMother != null && addressMother.isNotEmpty && addressMother != '-')
                      _infoRow(isArabic ? 'عنوان الأم' : 'Mother Address', addressMother),
                  ],
                ),
              ),
            ),
          ],

          // Children Card
          if (students.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school_rounded, size: 20, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          isArabic ? 'الأبناء المسجلون' : 'Enrolled Children',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${students.length}',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    for (var i = 0; i < students.length; i++) ...[
                      if (i > 0) const Divider(height: 16),
                      _buildStudentTile(context, students[i], languageCode, isArabic),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentTile(
    BuildContext context,
    dynamic studentData,
    String languageCode,
    bool isArabic,
  ) {
    if (studentData is! Map) return const SizedBox.shrink();
    final student = Map<String, dynamic>.from(studentData);
    final studentName = displayValue(student['name'] ?? student['Name'] ?? '', languageCode: languageCode);
    final grade = displayValue(student['grade'] ?? student['Grade'] ?? '', languageCode: languageCode);
    final classroom = displayValue(student['classroom'] ?? student['Classroom'] ?? '', languageCode: languageCode);
    final section = displayValue(student['section'] ?? student['Section'] ?? '', languageCode: languageCode);

    final details = [grade, classroom, section].where((s) => s.isNotEmpty && s != '-').join(' • ');

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.person_rounded, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                studentName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  details,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.muted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
