import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/localization/module_localization.dart';
import '../../core/localization/error_messages.dart';
import '../../core/data/school_modules.dart';
import '../../core/data/school_repository.dart';
import '../../core/models/app_models.dart';
import '../../core/network/api_service.dart';
import '../../core/network/promotion_service.dart';
import '../../core/state/dashboard_grid_pref.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/dynamic_form.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/living_icons.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/widgets/school_data_table.dart';
import '../../widgets/shared_widgets.dart';
import '../exams/exams_list_screen.dart';
import '../installments/presentation/screens/installment_plans_screen.dart';
import '../installments/presentation/screens/my_installments_screen.dart';
import '../salary/presentation/screens/my_salary_screen.dart';
import '../profile/profile_screen.dart';
import '../teacher/teacher_students_evaluation_content.dart';
import '../paper_exams/teacher_paper_exams_content.dart';
import '../paper_exams/student_marks_content.dart';
import '../complaints/complaints_content.dart';
import '../parent/parent_children_content.dart';
import '../schedule/presentation/screens/schedule_screen.dart';
import '../transportation/presentation/driver/driver_home_content.dart';
import '../transportation/presentation/driver/driver_schedule_content.dart';
import '../transportation/presentation/parent/parent_transport_content.dart';
import '../schedule/presentation/screens/academic_calendar_screen.dart';
import '../schedule/presentation/screens/my_availability_screen.dart';
import 'evaluation_content.dart';
import 'module_view_model.dart';
import 'parent_finance_content.dart';
import 'role_dashboard_content.dart';
import 'student_reports_content.dart';

class ModuleScreen extends StatelessWidget {
  const ModuleScreen({super.key, required this.module});

  final ModuleSpec module;

  @override
  Widget build(BuildContext context) {
    if (module.specialView == 'myInstallments') {
      return const MyInstallmentsScreen();
    }

    if (module.specialView == 'teacherSalary') {
      return const MySalaryScreen();
    }

    if (module.specialView == 'examFlow') {
      return const ExamsListScreen();
    }

    if (module.specialView == 'installmentPlans') {
      return const InstallmentPlansScreen();
    }

    if (module.specialView == 'schedule') {
      return const ScheduleScreen();
    }

    if (module.specialView == 'academicCalendar') {
      return const AcademicCalendarScreen();
    }

    if (module.specialView == 'myAvailability') {
      return const MyAvailabilityScreen();
    }

    if (module.specialView == 'driverHome') {
      return const DriverHomeContent();
    }

    if (module.specialView == 'driverSchedule') {
      return const DriverScheduleContent();
    }

    if (module.specialView == 'parentTransport') {
      return const ParentTransportContent();
    }

    return ChangeNotifierProvider(
      key: ValueKey(module.route),
      create: (context) => ModuleViewModel(
        module: module,
        repository: SchoolRepository(context.read<SessionController>().api),
        teacherScoped:
            module.key == 'students' &&
            context.read<SessionController>().currentRole == UserRole.teacher,
      ),
      child: Consumer<ModuleViewModel>(
        builder: (context, viewModel, _) {
          final languageCode = Localizations.localeOf(context).languageCode;
          if (module.key == 'students') {
            Future.microtask(
              () => viewModel.ensureStudentFilters(languageCode),
            );
          }
          return RefreshIndicator(
            onRefresh: viewModel.load,
            color: AppTheme.primary,
            backgroundColor: Colors.white,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
              children: [
                if (module.specialView != 'profile' &&
                    module.specialView != 'studentReports' &&
                    module.specialView != 'studentDashboard' &&
                    module.specialView != 'teacherDashboard' &&
                    module.specialView != 'parentDashboard')
                  _ModuleHeader(module: module),
                if (module.key == 'students') ...[
                  const SizedBox(height: 14),
                  _StudentApiFilters(
                    viewModel: viewModel,
                    languageCode: languageCode,
                  ),
                ],
                const SizedBox(height: 16),
                if (viewModel.loading)
                  const LoadingShimmer()
                else if (viewModel.error != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.error_outline_rounded,
                        color: AppTheme.coral,
                      ),
                      title: Text(viewModel.error!),
                      trailing: IconButton(
                        onPressed: viewModel.load,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ),
                  )
                else if (viewModel.empty)
                  IllustratedEmptyState(
                    title: appIsArabic(context)
                        ? 'لا توجد بيانات في ${localizedModuleTitle(context, module)}'
                        : 'No ${localizedModuleTitle(context, module)}',
                    message: appIsArabic(context)
                        ? 'أنشئ أول سجل أو عدل عوامل التصفية.'
                        : 'Create the first record or adjust your filters.',
                    actionLabel: t(context, 'create'),
                    onAction: () => _openForm(context, module),
                  )
                else
                  _SpecialOrTable(module: module, viewModel: viewModel),
              ],
            ),
          );
        },
      ),
    );
  }

  static void _openForm(
    BuildContext context,
    ModuleSpec module, {
    SchoolRecord? record,
  }) {
    final viewModel = context.read<ModuleViewModel>();
    final optionsFuture = viewModel.formOptions(context);

    final isTeacherOwned = module.key == 'teacher-quizzes';
    final session = context.read<SessionController>();
    final teacherId = session.authStorage.user?['id'] as int?;
    final hiddenFields = isTeacherOwned && teacherId != null
        ? const <String>{'teacher'}
        : const <String>{};
    final hiddenValues = isTeacherOwned && teacherId != null
        ? <String, dynamic>{'teacher': '$teacherId'}
        : const <String, dynamic>{};

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .42),
      builder: (context) {
        final media = MediaQuery.of(context);
        final maxHeight = media.size.height * .78;

        return FutureBuilder<Map<String, List<FormOption>>>(
          future: optionsFuture,
          builder: (context, snapshot) {
            final loadingOptions =
                snapshot.connectionState != ConnectionState.done;
            final hasError = snapshot.hasError;
            final fieldOptions = snapshot.data ?? const {};

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding:
                  media.viewInsets +
                  EdgeInsets.only(bottom: media.padding.bottom + 18),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: media.size.width,
                    maxHeight: maxHeight,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: SingleChildScrollView(
                      child: Stack(
                        children: [
                          if (loadingOptions)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 68, 16, 24),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            )
                          else if (hasError)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  68,
                                  16,
                                  24,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.red,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      appIsArabic(context)
                                          ? 'فشل تحميل الخيارات'
                                          : 'Failed to load options',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      translateServerError('${snapshot.error}'),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 16),
                                    FilledButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _openForm(
                                          context,
                                          module,
                                          record: record,
                                        );
                                      },
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: Text(
                                        appIsArabic(context)
                                            ? 'إعادة المحاولة'
                                            : 'Retry',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            DynamicModuleForm(
                              module: module,
                              initialValues: record?.raw,
                              fieldOptions: fieldOptions,
                              hiddenFields: hiddenFields,
                              hiddenValues: hiddenValues,
                              repository: SchoolRepository(context.read<SessionController>().api),
                              submitLabel:
                                  '${t(context, 'save')} ${localizedModuleTitle(context, module)}',
                              topPadding: 52,
                              onSubmit: (values) async {
                                try {
                                  if (record == null) {
                                    await viewModel.create(values);
                                  } else {
                                    await viewModel.update(record, values);
                                  }
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        t(context, 'savedSuccessfully'),
                                      ),
                                    ),
                                  );
                                } catch (error) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error.toString())),
                                  );
                                }
                              },
                            ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: IconButton.filledTonal(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                              tooltip: appIsArabic(context) ? 'إغلاق' : 'Close',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StudentApiFilters extends StatelessWidget {
  const _StudentApiFilters({
    required this.viewModel,
    required this.languageCode,
  });

  final ModuleViewModel viewModel;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    appIsArabic(context) ? 'تصفية الطلاب' : 'Student filters',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (viewModel.selectedGradeId != null ||
                    viewModel.selectedClassroomId != null ||
                    viewModel.selectedSectionId != null)
                  TextButton.icon(
                    onPressed: viewModel.clearStudentFilters,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(appIsArabic(context) ? 'مسح' : 'Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: viewModel.selectedGradeId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: localizedColumnLabel(context, 'Grade'),
                prefixIcon: const Icon(Icons.school_rounded),
              ),
              items: [
                for (final option in viewModel.gradeFilterOptions)
                  DropdownMenuItem(
                    value: option.value,
                    child: Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: viewModel.filterOptionsLoading
                  ? null
                  : (value) => viewModel.setStudentGrade(value, languageCode),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: viewModel.selectedClassroomId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: localizedColumnLabel(context, 'Classroom'),
                prefixIcon: const Icon(Icons.meeting_room_rounded),
                helperText: viewModel.selectedGradeId == null
                    ? (appIsArabic(context)
                          ? 'اختر المرحلة أولًا'
                          : 'Choose a grade first')
                    : null,
              ),
              items: [
                for (final option in viewModel.classroomFilterOptions)
                  DropdownMenuItem(
                    value: option.value,
                    child: Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged:
                  viewModel.filterOptionsLoading ||
                      viewModel.selectedGradeId == null
                  ? null
                  : (value) => viewModel.setStudentClassroom(value, languageCode),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: viewModel.selectedSectionId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: localizedColumnLabel(context, 'Section'),
                prefixIcon: const Icon(Icons.grid_view_rounded),
                helperText: viewModel.selectedClassroomId == null
                    ? (appIsArabic(context)
                          ? 'اختر الفصل أولًا'
                          : 'Choose a classroom first')
                    : null,
              ),
              items: [
                for (final option in viewModel.sectionFilterOptions)
                  DropdownMenuItem(
                    value: option.value,
                    child: Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged:
                  viewModel.filterOptionsLoading ||
                      viewModel.selectedClassroomId == null
                  ? null
                  : viewModel.setStudentSection,
            ),
            if (viewModel.filterOptionsLoading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 3),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModuleHeader extends StatelessWidget {
  const _ModuleHeader({required this.module});

  final ModuleSpec module;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  localizedModuleTitle(context, module),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(module.icon, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            localizedModuleGoal(context, module),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SpecialOrTable extends StatelessWidget {
  const _SpecialOrTable({required this.module, required this.viewModel});

  final ModuleSpec module;
  final ModuleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return switch (module.specialView) {
      'dashboard' => AdminDashboardContent(data: viewModel.dashboardData),
      'teacherDashboard' => const RoleDashboard(
        endpoint: '/teacher/dashboard',
        builder: teacherDashboardBuilder,
      ),
      'studentDashboard' => const RoleDashboard(
        endpoint: '/student/dashboard',
        builder: studentDashboardBuilder,
      ),
      'parentDashboard' => const RoleDashboard(
        endpoint: '/parent/dashboard',
        builder: parentDashboardBuilder,
      ),
      'attendance' => const AttendanceContent(),
      'attendanceHistory' => const AttendanceHistoryContent(),
      'parentAttendance' => ParentAttendanceContent(viewModel: viewModel),
      'parentChildren' => ParentChildrenContent(records: viewModel.records),
      'examFlow' => const ExamsListScreen(),
      'financeTabs' => const ParentFinanceContent(),
      'parentWizard' => WizardContent(moduleTitle: 'Parent wizard'),
      'studentForm' => WizardContent(moduleTitle: 'Student multi-step form'),
      'bulkAction' => BulkActionContent(
        module: module,
        action: appIsArabic(context)
            ? 'ترقية الطلاب المحددين'
            : 'Promote selected students',
      ),
      'archive' => BulkActionContent(
        module: module,
        action: appIsArabic(context)
            ? 'تخريج الطلاب المحددين'
            : 'Graduate selected students',
      ),
      'quiz' => QuizContent(module: module),
      'settings' => const SettingsContent(),
      'teacherEvaluations' => const TeacherEvaluationsContent(),
      'teacherStudentEvaluation' => const TeacherStudentsEvaluationContent(),
      'teacherPaperExams' => const TeacherPaperExamsContent(),
      'studentPaperExamMarks' => const StudentPaperExamMarksContent(),
      'parentPaperExamMarks' => const StudentPaperExamMarksContent(),
      'teacherComplaints' => const ComplaintsContent(),
      'studentComplaints' => const ComplaintsContent(),
      'parentComplaints' => const ComplaintsContent(),
      'parentEvaluations' => const ParentEvaluationsContent(),
      'studentEvaluations' => const StudentEvaluationsContent(),
      'studentReports' => const StudentReportsContent(),
      'myInstallments' => const MyInstallmentsScreen(),
      'installmentPlans' => const InstallmentPlansScreen(),
      'teacherSalary' => const MySalaryScreen(),
      'schedule' => const ScheduleScreen(),
      'profile' => const ProfileScreen(),
      _ => SchoolDataTable(
        module: module,
        rows: viewModel.rowsFor(context),
        records: viewModel.records,
        onCreate: () => ModuleScreen._openForm(context, module),
        onEdit: (record) =>
            ModuleScreen._openForm(context, module, record: record),
        onRowTap: module.key == 'parents'
            ? (record) {
                final id = record.id ?? int.tryParse('${record.raw['id']}');
                if (id != null && id > 0) {
                  context.push('/parents/$id');
                }
              }
            : null,
        onDelete: (record) async {
          try {
            await viewModel.delete(record);
            if (context.mounted) viewModel.showSaved(context);
          } catch (error) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error.toString())));
          }
        },
      ),
    };
  }
}

class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  final _schoolName = TextEditingController();
  final _picker = ImagePicker();
  XFile? _logoFile;
  String? _logoUrl;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSettings());
  }

  @override
  void dispose() {
    _schoolName.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final session = context.read<SessionController>();
    final baseUrl = session.authStorage.baseUrl.replaceFirst(
      RegExp(r'/api$'),
      '',
    );
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final body = await session.api.get('/settings');
      final settings = _settingsMap(body);
      _schoolName.text = '${settings['school_name'] ?? ''}';
      _logoUrl = '${body['logo_url'] ?? ''}'.trim();
      if (_logoUrl!.isEmpty && settings['logo'] != null) {
        _logoUrl = '$baseUrl/attachments/logo/${settings['logo']}';
      }
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickLogo() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    if (!mounted || picked == null) return;
    setState(() => _logoFile = picked);
  }

  Future<void> _saveSettings() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final api = context.read<SessionController>().api;
    final savedLabel = t(context, 'savedSuccessfully');
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final formData = FormData.fromMap({
        'school_name': _schoolName.text.trim(),
        if (_logoFile != null)
          'logo': await MultipartFile.fromFile(
            _logoFile!.path,
            filename: _logoFile!.name,
          ),
      });
      final body = await api.multipart('/settings/school', formData: formData);
      final settings = _settingsMap(body);
      _schoolName.text = '${settings['school_name'] ?? _schoolName.text}';
      _logoUrl = '${body['logo_url'] ?? _logoUrl ?? ''}'.trim();
      _logoFile = null;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(savedLabel)));
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Map<String, dynamic> _settingsMap(Map<String, dynamic> body) {
    final mapped = body['settings'];
    if (mapped is Map) return Map<String, dynamic>.from(mapped);

    final data = body['data'];
    if (data is List) {
      return {
        for (final item in data.whereType<Map>())
          if (item['key'] != null) '${item['key']}': item['value'],
      };
    }
    return const {};
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final isArabic = session.locale.languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: SwitchListTile(
            title: Text(t(context, 'arabic')),
            subtitle: Text(t(context, 'language')),
            value: isArabic,
            onChanged: (value) {
              final next = value ? const Locale('ar') : const Locale('en');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                session.selectLocale(next);
              });
            },
            secondary: const _SoftIcon(icon: Icons.language_rounded),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ValueListenableBuilder<bool>(
            valueListenable: dashboardSectionsGrid,
            builder: (context, showGrid, _) => SwitchListTile(
              title: Text(
                appIsArabic(context)
                    ? 'إظهار الأقسام كشبكة في لوحة التحكم'
                    : 'Show sections grid on dashboard',
              ),
              subtitle: Text(
                appIsArabic(context)
                    ? 'وصول أسرع إلى جميع الوحدات من الصفحة الرئيسية'
                    : 'Quick access to all modules from the home screen',
              ),
              value: showGrid,
              onChanged: (value) async {
                await setDashboardSectionsGrid(value);
              },
              secondary: const _SoftIcon(icon: Icons.grid_view_rounded),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        appIsArabic(context)
                            ? 'بيانات المدرسة'
                            : 'School details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _schoolName,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        decoration: InputDecoration(
                          labelText: appIsArabic(context)
                              ? 'اسم المدرسة'
                              : 'School name',
                          prefixIcon: const Icon(Icons.business_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _LogoPreview(file: _logoFile, logoUrl: _logoUrl),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _pickLogo,
                        icon: const Icon(Icons.image_rounded),
                        label: Text(
                          appIsArabic(context) ? 'اختيار شعار' : 'Choose logo',
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppTheme.coral),
                        ),
                      ],
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _saving ? null : _saveSettings,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          appIsArabic(context)
                              ? 'حفظ الإعدادات'
                              : 'Save settings',
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({required this.file, required this.logoUrl});

  final XFile? file;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final hasNetworkLogo = logoUrl != null && logoUrl!.isNotEmpty;
    return Container(
      height: 132,
      decoration: BoxDecoration(
        color: AppTheme.cloud,
        borderRadius: BorderRadius.circular(22),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: file != null
            ? Image.file(
                File(file!.path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _LogoPlaceholder(hasLogo: true, label: file!.name),
              )
            : hasNetworkLogo
            ? Image.network(
                logoUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const _LogoPlaceholder(hasLogo: false),
              )
            : const _LogoPlaceholder(hasLogo: false),
      ),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder({required this.hasLogo, this.label});

  final bool hasLogo;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasLogo ? Icons.image_rounded : Icons.add_photo_alternate_rounded,
            color: AppTheme.primary,
            size: 34,
          ),
          const SizedBox(height: 8),
          Text(
            label ??
                (appIsArabic(context) ? 'لا يوجد شعار' : 'No logo selected'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminDashboardContent extends StatelessWidget {
  const AdminDashboardContent({super.key, this.data});

  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    final stats = _dashboardStats(data);
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _StatCard(
                label: t(context, 'students'),
                value: _statValue(stats, 'students_count'),
                icon: Icons.school_rounded,
              ),
              _StatCard(
                label: t(context, 'teachers'),
                value: _statValue(stats, 'teachers_count'),
                icon: Icons.badge_rounded,
              ),
              _StatCard(
                label: t(context, 'parents'),
                value: _statValue(stats, 'parents_count'),
                icon: Icons.family_restroom_rounded,
              ),
              _StatCard(
                label: t(context, 'classrooms'),
                value: _statValue(stats, 'classrooms_count'),
                icon: Icons.meeting_room_rounded,
              ),
            ];
            if (constraints.maxWidth < 620) {
              return Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    const SizedBox(height: 10),
                  ],
                ],
              );
            }
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              childAspectRatio: 1.35,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: cards,
            );
          },
        ),
        const SizedBox(height: 16),
        const _SectionsGridSection(),
        const SizedBox(height: 16),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appIsArabic(context) ? 'النشاط الأخير' : 'Recent activity',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                for (final item
                    in appIsArabic(context)
                        ? [
                            'تم تسجيل طالب جديد',
                            'تم إرسال الحضور',
                            'تم دفع فاتورة',
                            'تم نشر اختبار',
                          ]
                        : [
                            'New student registered',
                            'Attendance submitted',
                            'Invoice paid',
                            'Quiz published',
                          ])
                  ListTile(
                    leading: const _SoftIcon(icon: Icons.timeline_rounded),
                    title: Text(
                      item,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(t(context, 'fewMinutesAgo')),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _statValue(Map<String, dynamic> stats, String key) {
    final value = stats[key];
    if (value == null) return '-';
    return '$value';
  }

  Map<String, dynamic> _dashboardStats(Map<String, dynamic>? data) {
    final nested = data?['data'];
    final raw = data?['stats'] ?? (nested is Map ? nested['stats'] : null);
    if (raw is! Map) return const {};
    final stats = Map<String, dynamic>.from(raw);
    stats['students_count'] ??= stats['total_students'];
    stats['teachers_count'] ??= stats['total_teachers'];
    stats['parents_count'] ??= stats['total_parents'];
    stats['classrooms_count'] ??=
        stats['total_classrooms'] ??
        stats['classes_count'] ??
        stats['total_classes'];
    return stats;
  }
}

/// Drawer content rendered as grids of module tiles on the admin dashboard.
/// Visible only when the "sections grid" settings option is enabled.
class _SectionsGridSection extends StatefulWidget {
  const _SectionsGridSection();

  @override
  State<_SectionsGridSection> createState() => _SectionsGridSectionState();
}

class _SectionsGridSectionState extends State<_SectionsGridSection> {
  @override
  void initState() {
    super.initState();
    loadDashboardSectionsGridPref();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: dashboardSectionsGrid,
      builder: (context, show, _) {
        if (!show) return const SizedBox.shrink();
        final role = context.watch<SessionController>().currentRole;
        final currentPath = GoRouterState.of(context).uri.path;
        // Flat grid: every module together, de-duplicated by route, without
        // the drawer's category groupings.
        final items = <NavItem>[];
        final seenRoutes = <String>{};
        for (final group in navGroupsForRole(role)) {
          for (final item in group.items) {
            if (item.route == currentPath) continue;
            if (!seenRoutes.add(item.route)) continue;
            items.add(item);
          }
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 480
                ? 3
                : constraints.maxWidth < 800
                ? 4
                : 6;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.05,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final item in items) _ModuleGridTile(item: item),
              ],
            );
          },
        );
      },
    );
  }
}

class _ModuleGridTile extends StatelessWidget {
  const _ModuleGridTile({required this.item});

  final NavItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: () => GoRouter.of(context).go(item.route),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LivingNavIcon(icon: item.icon, size: 44),
              const SizedBox(height: 8),
              Text(
                localizedNavLabel(context, item),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AttendanceContent extends StatefulWidget {
  const AttendanceContent({super.key});

  @override
  State<AttendanceContent> createState() => _AttendanceContentState();
}

class _AttendanceContentState extends State<AttendanceContent> {
  late final SchoolRepository _repository;
  var _gradeOptions = <FormOption>[];
  var _classroomOptions = <FormOption>[];
  var _sectionOptions = <FormOption>[];
  var _students = <SchoolRecord>[];
  final _statuses = <int, String>{};
  String? _gradeId;
  String? _classroomId;
  String? _sectionId;
  bool _loadingFilters = true;
  bool _loadingStudents = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = SchoolRepository(context.read<SessionController>().api);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGrades());
  }

  Future<void> _loadGrades() async {
    setState(() {
      _loadingFilters = true;
      _error = null;
    });
    try {
      final languageCode = Localizations.localeOf(context).languageCode;
      _gradeOptions = await _repository.optionsFor(
        'grades',
        languageCode: languageCode,
      );
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _loadingFilters = false);
    }
  }

  Future<void> _selectGrade(String? value) async {
    setState(() {
      _gradeId = value;
      _classroomId = null;
      _sectionId = null;
      _classroomOptions = const [];
      _sectionOptions = const [];
      _students = const [];
      _statuses.clear();
      _loadingFilters = value != null;
      _error = null;
    });
    if (value == null) return;
    try {
      final languageCode = Localizations.localeOf(context).languageCode;
      _classroomOptions = await _repository.classroomsForGrade(
        value,
        languageCode: languageCode,
      );
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _loadingFilters = false);
    }
  }

  Future<void> _selectClassroom(String? value) async {
    setState(() {
      _classroomId = value;
      _sectionId = null;
      _sectionOptions = const [];
      _students = const [];
      _statuses.clear();
      _loadingFilters = value != null;
      _error = null;
    });
    if (value == null) return;
    try {
      final languageCode = Localizations.localeOf(context).languageCode;
      _sectionOptions = await _repository.sectionsForClassroom(
        value,
        languageCode: languageCode,
      );
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _loadingFilters = false);
    }
  }

  Future<void> _selectSection(String? value) async {
    setState(() {
      _sectionId = value;
      _students = const [];
      _statuses.clear();
      _loadingStudents = value != null;
      _error = null;
    });
    if (value == null) return;
    try {
      _students = await _repository.attendanceStudentsForSection(value);
      for (final student in _students) {
        final id = student.id;
        if (id != null) _statuses[id] = 'present';
      }
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

  Future<void> _saveAttendance() async {
    if (_gradeId == null ||
        _classroomId == null ||
        _sectionId == null ||
        _statuses.isEmpty) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.submitAttendance(
        gradeId: _gradeId!,
        classroomId: _classroomId!,
        sectionId: _sectionId!,
        attendances: _statuses,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(context, 'savedSuccessfully'))));
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
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
              Text(
                appIsArabic(context) ? 'تصفية الحضور' : 'Filter attendance',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('attendance-grade-$_gradeId'),
                      initialValue: _gradeId,
                      isExpanded: true,
                      menuMaxHeight: 280,
                      decoration: InputDecoration(
                        labelText: localizedColumnLabel(context, 'Grade'),
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
                          borderSide: BorderSide(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: [
                        for (final option in _gradeOptions)
                          DropdownMenuItem(
                            value: option.value,
                            child: Text(
                              option.label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                      onChanged: _loadingFilters || _saving
                          ? null
                          : _selectGrade,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('attendance-classroom-$_classroomId'),
                      initialValue: _classroomId,
                      isExpanded: true,
                      menuMaxHeight: 280,
                      decoration: InputDecoration(
                        labelText: localizedColumnLabel(
                          context,
                          'Classroom',
                        ),
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
                          borderSide: BorderSide(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: [
                        for (final option in _classroomOptions)
                          DropdownMenuItem(
                            value: option.value,
                            child: Text(
                              option.label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                      onChanged:
                          _gradeId == null || _loadingFilters || _saving
                          ? null
                          : _selectClassroom,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('attendance-section-$_sectionId'),
                initialValue: _sectionId,
                isExpanded: true,
                menuMaxHeight: 280,
                decoration: InputDecoration(
                  labelText: localizedColumnLabel(context, 'Section'),
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
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                items: [
                  for (final option in _sectionOptions)
                    DropdownMenuItem(
                      value: option.value,
                      child: Text(
                        option.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
                onChanged: _classroomId == null || _loadingFilters || _saving
                    ? null
                    : _selectSection,
              ),
              if (_loadingFilters) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(minHeight: 3),
              ],
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.coral,
              ),
              title: Text(_error!),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (_loadingStudents)
          const LoadingShimmer()
        else if (_sectionId == null)
          IllustratedEmptyState(
            title: appIsArabic(context) ? 'اختر القسم' : 'Choose a section',
            message: appIsArabic(context)
                ? 'اختر المرحلة والفصل والقسم لعرض الطلاب.'
                : 'Select grade, classroom, and section to load students.',
            actionLabel: appIsArabic(context) ? 'تحديث' : 'Refresh',
            onAction: _loadGrades,
          )
        else if (_students.isEmpty)
          IllustratedEmptyState(
            title: t(context, 'noData'),
            message: appIsArabic(context)
                ? 'لا يوجد طلاب في هذا القسم.'
                : 'No students found in this section.',
            actionLabel: appIsArabic(context) ? 'إعادة المحاولة' : 'Retry',
            onAction: () => _selectSection(_sectionId),
          )
        else ...[
          for (final student in _students) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const _SoftIcon(icon: Icons.person_rounded),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            displayValue(
                              student.raw['name'] ?? student.raw['Name'],
                              languageCode: Localizations.localeOf(
                                context,
                              ).languageCode,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      selected: {_statuses[student.id] ?? 'present'},
                      onSelectionChanged: student.id == null || _saving
                          ? null
                          : (value) => setState(
                              () => _statuses[student.id!] = value.first,
                            ),
                      segments: [
                        ButtonSegment(
                          value: 'present',
                          label: Text(t(context, 'present')),
                        ),
                        ButtonSegment(
                          value: 'absent',
                          label: Text(t(context, 'absent')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          FilledButton.icon(
            onPressed: _saving ? null : _saveAttendance,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.fact_check_rounded),
            label: Text(t(context, 'markAttendance')),
          ),
        ],
      ],
    );
  }
}

class AttendanceHistoryContent extends StatefulWidget {
  const AttendanceHistoryContent({super.key});

  @override
  State<AttendanceHistoryContent> createState() =>
      _AttendanceHistoryContentState();
}

class _AttendanceHistoryContentState extends State<AttendanceHistoryContent> {
  late final SchoolRepository _repository;
  var _gradeOptions = <FormOption>[];
  var _classroomOptions = <FormOption>[];
  var _sectionOptions = <FormOption>[];
  var _records = <SchoolRecord>[];
  String? _gradeId;
  String? _classroomId;
  String? _sectionId;
  DateTime? _date;
  bool _loadingFilters = true;
  bool _loadingHistory = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = SchoolRepository(context.read<SessionController>().api);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loadingFilters = true;
      _error = null;
    });
    try {
      final languageCode = Localizations.localeOf(context).languageCode;
      _gradeOptions = await _repository.optionsFor(
        'grades',
        languageCode: languageCode,
      );
      await _loadHistory();
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _loadingFilters = false);
    }
  }

  Future<void> _selectGrade(String? value) async {
    setState(() {
      _gradeId = value;
      _classroomId = null;
      _sectionId = null;
      _classroomOptions = const [];
      _sectionOptions = const [];
      _loadingFilters = value != null;
      _error = null;
    });
    try {
      if (value != null) {
        final languageCode = Localizations.localeOf(context).languageCode;
        _classroomOptions = await _repository.classroomsForGrade(
          value,
          languageCode: languageCode,
        );
      }
      await _loadHistory();
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _loadingFilters = false);
    }
  }

  Future<void> _selectClassroom(String? value) async {
    setState(() {
      _classroomId = value;
      _sectionId = null;
      _sectionOptions = const [];
      _loadingFilters = value != null;
      _error = null;
    });
    try {
      if (value != null) {
        final languageCode = Localizations.localeOf(context).languageCode;
        _sectionOptions = await _repository.sectionsForClassroom(
          value,
          languageCode: languageCode,
        );
      }
      await _loadHistory();
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _loadingFilters = false);
    }
  }

  Future<void> _selectSection(String? value) async {
    setState(() => _sectionId = value);
    await _loadHistory();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    await _loadHistory();
  }

  Future<void> _clearFilters() async {
    setState(() {
      _gradeId = null;
      _classroomId = null;
      _sectionId = null;
      _date = null;
      _classroomOptions = const [];
      _sectionOptions = const [];
    });
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
      _error = null;
    });
    try {
      _records = await _repository.attendanceHistory(
        gradeId: _gradeId,
        classroomId: _classroomId,
        sectionId: _sectionId,
        date: _date == null ? null : _formatDate(_date!),
      );
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        appIsArabic(context)
                            ? 'فلاتر سجل الحضور'
                            : 'Attendance history filters',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: Text(appIsArabic(context) ? 'مسح' : 'Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey('history-grade-$_gradeId'),
                  initialValue: _gradeId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: localizedColumnLabel(context, 'Grade'),
                    prefixIcon: const Icon(Icons.layers_rounded),
                  ),
                  items: [
                    for (final option in _gradeOptions)
                      DropdownMenuItem(
                        value: option.value,
                        child: Text(
                          option.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _loadingFilters ? null : _selectGrade,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey('history-classroom-$_classroomId'),
                  initialValue: _classroomId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: localizedColumnLabel(context, 'Classroom'),
                    prefixIcon: const Icon(Icons.meeting_room_rounded),
                  ),
                  items: [
                    for (final option in _classroomOptions)
                      DropdownMenuItem(
                        value: option.value,
                        child: Text(
                          option.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _gradeId == null || _loadingFilters
                      ? null
                      : _selectClassroom,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey('history-section-$_sectionId'),
                  initialValue: _sectionId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: localizedColumnLabel(context, 'Section'),
                    prefixIcon: const Icon(Icons.groups_rounded),
                  ),
                  items: [
                    for (final option in _sectionOptions)
                      DropdownMenuItem(
                        value: option.value,
                        child: Text(
                          option.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _classroomId == null || _loadingFilters
                      ? null
                      : _selectSection,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event_rounded),
                  label: Text(
                    _date == null
                        ? localizedColumnLabel(context, 'Date')
                        : _formatDate(_date!),
                  ),
                ),
                if (_loadingFilters) ...[
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
              leading: const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.coral,
              ),
              title: Text(_error!),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (_loadingHistory)
          const LoadingShimmer()
        else if (_records.isEmpty)
          IllustratedEmptyState(
            title: t(context, 'noData'),
            message: appIsArabic(context)
                ? 'لا توجد سجلات حضور لهذه الفلاتر.'
                : 'No attendance records match these filters.',
            actionLabel: appIsArabic(context) ? 'تحديث' : 'Refresh',
            onAction: _loadHistory,
          )
        else
          for (final record in _records) ...[
            _AttendanceHistoryCard(record: record),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }
}

class _AttendanceHistoryCard extends StatelessWidget {
  const _AttendanceHistoryCard({required this.record});

  final SchoolRecord record;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final raw = record.raw;
    final student = displayValue(
      raw['students'] ?? raw['student'] ?? raw['name'],
      languageCode: languageCode,
    );
    final section = displayValue(raw['section'], languageCode: languageCode);
    final classroom = displayValue(
      raw['classroom'],
      languageCode: languageCode,
    );
    final statusValue = raw['attendence_status'];
    final present =
        statusValue == true ||
        statusValue == 1 ||
        '$statusValue' == '1' ||
        '$statusValue'.toLowerCase() == 'presence' ||
        '$statusValue'.toLowerCase() == 'present';
    final statusLabel = present ? t(context, 'present') : t(context, 'absent');
    final date = '${raw['attendence_date'] ?? raw['attendance_date'] ?? '-'}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const _SoftIcon(icon: Icons.person_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    student.isEmpty ? '-' : student,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                StatusPill(label: statusLabel, positive: present),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HistoryChip(icon: Icons.event_rounded, label: date),
                _HistoryChip(
                  icon: Icons.meeting_room_rounded,
                  label: classroom.isEmpty ? '-' : classroom,
                ),
                _HistoryChip(
                  icon: Icons.groups_rounded,
                  label: section.isEmpty ? '-' : section,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ParentAttendanceContent extends StatelessWidget {
  const ParentAttendanceContent({super.key, required this.viewModel});

  final ModuleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final selectedChildId = context.watch<AppState>().selectedChildId;
    final records = selectedChildId == null
        ? viewModel.records
        : viewModel.records
            .where((r) => '${r.raw['student_id']}' == '$selectedChildId')
            .toList();
    if (records.isEmpty) {
      return IllustratedEmptyState(
        title: t(context, 'noData'),
        message: appIsArabic(context)
            ? 'لا توجد سجلات حضور لأبنائك.'
            : 'No attendance records found for your children.',
        actionLabel: appIsArabic(context) ? 'تحديث' : 'Refresh',
        onAction: viewModel.load,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final record in records) ...[
          _AttendanceHistoryCard(record: record),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cloud,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class ExamFlowContent extends StatefulWidget {
  const ExamFlowContent({super.key});

  @override
  State<ExamFlowContent> createState() => _ExamFlowContentState();
}

class _ExamFlowContentState extends State<ExamFlowContent> {
  int index = 0;
  final questions = const [
    'What is 2 + 2?',
    'Water freezes at 0 C.',
    'Choose the noun.',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appIsArabic(context)
                  ? 'السؤال ${index + 1} من ${questions.length}'
                  : 'Question ${index + 1} of ${questions.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              appIsArabic(context)
                  ? [
                      'ما ناتج 2 + 2؟',
                      'يتجمد الماء عند 0 درجة.',
                      'اختر الاسم.',
                    ][index]
                  : questions[index],
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            for (final option in ['A', 'B', 'C', 'D'])
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: option == 'A'
                      ? AppTheme.primary.withValues(alpha: .10)
                      : AppTheme.cloud,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  leading: Icon(
                    option == 'A'
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: option == 'A' ? AppTheme.primary : AppTheme.muted,
                  ),
                  title: Text(
                    appIsArabic(context)
                        ? 'الخيار ${localizedOptionLabel(context, option)}'
                        : 'Option $option',
                  ),
                  onTap: () {},
                ),
              ),
            Row(
              children: [
                OutlinedButton(
                  onPressed: index == 0 ? null : () => setState(() => index--),
                  child: Text(t(context, 'previous')),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () async {
                    if (index < questions.length - 1) {
                      setState(() => index++);
                    } else {
                      await showConfirmationDialog(
                        context,
                        title: appIsArabic(context)
                            ? 'إرسال الاختبار؟'
                            : 'Submit exam?',
                        message: appIsArabic(context)
                            ? 'لا يمكنك تعديل الإجابات بعد الإرسال.'
                            : 'You cannot edit answers after submission.',
                        confirmLabel: appIsArabic(context) ? 'إرسال' : 'Submit',
                      );
                    }
                  },
                  child: Text(
                    index == questions.length - 1
                        ? (appIsArabic(context) ? 'إرسال' : 'Submit')
                        : t(context, 'next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WizardContent extends StatelessWidget {
  const WizardContent({super.key, required this.moduleTitle});

  final String moduleTitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stepper(
        controlsBuilder: (context, details) => Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: FilledButton(
                onPressed: details.onStepContinue,
                child: Text(t(context, 'next')),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: TextButton(
                onPressed: details.onStepCancel,
                child: Text(t(context, 'back')),
              ),
            ),
          ],
        ),
        steps: [
          Step(
            title: Text(
              appIsArabic(context)
                  ? '${_localizedWizardTitle(context, moduleTitle)}: الخطوة 1'
                  : '$moduleTitle: step 1',
            ),
            content: TextField(
              decoration: InputDecoration(
                labelText: appIsArabic(context)
                    ? 'البيانات الشخصية'
                    : 'Personal details',
              ),
            ),
          ),
          Step(
            title: Text(t(context, 'academicMotherDetails')),
            content: TextField(
              decoration: InputDecoration(
                labelText: appIsArabic(context) ? 'التفاصيل' : 'Details',
              ),
            ),
          ),
          Step(
            title: Text(t(context, 'reviewLinkRecords')),
            content: Text(t(context, 'confirmLinked')),
          ),
        ],
      ),
    );
  }
}

String _localizedWizardTitle(BuildContext context, String title) {
  if (!appIsArabic(context)) return title;
  return switch (title) {
    'Parent wizard' => 'معالج ولي الأمر',
    'Student multi-step form' => 'نموذج الطالب متعدد الخطوات',
    _ => title,
  };
}

class BulkActionContent extends StatefulWidget {
  const BulkActionContent({
    super.key,
    required this.module,
    required this.action,
  });

  final ModuleSpec module;
  final String action;

  @override
  State<BulkActionContent> createState() => _BulkActionContentState();
}

class _BulkActionContentState extends State<BulkActionContent> {
  Map<String, List<FormOption>> _fieldOptions = const {};
  bool _loading = true;
  String? _error;
  bool _optionsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_optionsLoaded) {
      _optionsLoaded = true;
      _loadOptions();
    }
  }

  Future<void> _loadOptions() async {
    final viewModel = context.read<ModuleViewModel>();
    try {
      final options = await viewModel.formOptions(context);
      if (mounted) {
        setState(() {
          _fieldOptions = options;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiService.failureFrom(e).message;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(_error!, style: const TextStyle(color: AppTheme.coral)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(2),
      child: widget.module.key == 'promotions'
          ? _PromotionBulkForm(
              module: widget.module,
              fieldOptions: _fieldOptions,
              action: widget.action,
            )
          : DynamicModuleForm(
              module: widget.module,
              fieldOptions: _fieldOptions,
              submitLabel: widget.action,
              onSubmit: (values) async {
                final ok = await showConfirmationDialog(
                  context,
                  title: widget.action,
                  message: appIsArabic(context)
                      ? 'يرجى تأكيد هذه العملية الجماعية.'
                      : 'Please confirm this bulk operation.',
                );
                if (!ok || !context.mounted) return;
                try {
                  await context.read<ModuleViewModel>().create(values);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t(context, 'savedSuccessfully'))),
                  );
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              },
            ),
    );
  }
}

class _PromotionBulkForm extends StatefulWidget {
  const _PromotionBulkForm({
    required this.module,
    required this.fieldOptions,
    required this.action,
  });

  final ModuleSpec module;
  final Map<String, List<FormOption>> fieldOptions;
  final String action;

  @override
  State<_PromotionBulkForm> createState() => _PromotionBulkFormState();
}

class _PromotionBulkFormState extends State<_PromotionBulkForm> {
  bool _submitting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DynamicModuleForm(
          module: widget.module,
          fieldOptions: widget.fieldOptions,
          repository: SchoolRepository(context.read<SessionController>().api),
          submitLabel: widget.action,
          onSubmit: (values) => _executePromotion(context, values),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_error!, style: const TextStyle(color: AppTheme.coral)),
          ),
        if (_submitting)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Future<void> _executePromotion(
    BuildContext context,
    Map<String, dynamic> values,
  ) async {
    // Extract selected student IDs
    final studentsRaw = values['students'];
    final List<String> studentIds = [];
    if (studentsRaw is List) {
      studentIds.addAll(studentsRaw.whereType<String>());
    } else if (studentsRaw is String && studentsRaw.isNotEmpty) {
      studentIds.add(studentsRaw);
    }

    if (studentIds.isEmpty) {
      setState(
        () => _error = appIsArabic(context)
            ? 'يرجى اختيار طالب واحد على الأقل.'
            : 'Please select at least one student.',
      );
      return;
    }

    // Extract all form values
    final fromGrade = '${values['fromGrade'] ?? ''}';
    final fromClassroom = '${values['fromClassroom'] ?? ''}';
    final fromSection = '${values['fromSection'] ?? ''}';
    final toGrade = '${values['toGrade'] ?? ''}';
    final toClassroom = '${values['toClassroom'] ?? ''}';
    final toSection = '${values['toSection'] ?? ''}';
    final academicYear = '${values['academicYear'] ?? ''}';
    final academicYearNew = '${values['academicYearNew'] ?? ''}';

    if (fromGrade.isEmpty ||
        fromClassroom.isEmpty ||
        fromSection.isEmpty ||
        toGrade.isEmpty ||
        toClassroom.isEmpty ||
        toSection.isEmpty ||
        academicYear.isEmpty ||
        academicYearNew.isEmpty) {
      setState(
        () => _error = appIsArabic(context)
            ? 'يرجى تعبئة جميع الحقول المطلوبة.'
            : 'Please fill all required fields.',
      );
      return;
    }

    if (academicYear == academicYearNew) {
      setState(
        () => _error = appIsArabic(context)
            ? 'السنة الدراسية الحالية والجديدة يجب أن تكونا مختلفتين.'
            : 'Current and new academic years must be different.',
      );
      return;
    }

    final ok = await showConfirmationDialog(
      context,
      title: widget.action,
      message: appIsArabic(context)
          ? 'ترقية ${studentIds.length} من الطلاب؟'
          : 'Promote ${studentIds.length} students?',
    );
    if (!ok || !context.mounted) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final api = context.read<SessionController>().api;
      final service = PromotionService(api);

      final result = await service.bulkPromote(
        studentIds: studentIds,
        fromGradeId: fromGrade,
        fromClassroomId: fromClassroom,
        fromSectionId: fromSection,
        toGradeId: toGrade,
        toClassroomId: toClassroom,
        toSectionId: toSection,
        academicYear: academicYear,
        academicYearNew: academicYearNew,
      );

      if (!context.mounted) return;

      final promoted = result['data']?['promoted'] ?? 0;
      final failed = result['data']?['failed'] ?? 0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$promoted promoted, $failed failed.'),
          backgroundColor: failed > 0 ? Colors.orange : Colors.green,
        ),
      );

      context.read<ModuleViewModel>().load();
    } catch (error) {
      if (!context.mounted) return;
      setState(() => _error = ApiService.failureFrom(error).message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class QuizContent extends StatelessWidget {
  const QuizContent({super.key, required this.module});

  final ModuleSpec module;

  @override
  Widget build(BuildContext context) {
    // Find the appropriate questions module based on the current quiz module
    final questionsModule = module.key.startsWith('teacher')
        ? moduleByKey('teacher-questions')
        : moduleByKey('questions');
    return Column(
      children: [
        SchoolDataTable(
          module: module,
          rows: context.watch<ModuleViewModel>().rowsFor(context),
          records: context.watch<ModuleViewModel>().records,
          onCreate: () => ModuleScreen._openForm(context, module),
          onEdit: (record) =>
              ModuleScreen._openForm(context, module, record: record),
          onDelete: (record) => context.read<ModuleViewModel>().delete(record),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const _SoftIcon(icon: Icons.list_alt_rounded),
            title: Text(t(context, 'quizDetail')),
            subtitle: Text(
              appIsArabic(context)
                  ? 'معاينة قائمة الأسئلة مع إجراءات الإضافة والتعديل.'
                  : 'Question list preview with add/edit actions.',
            ),
            trailing: FilledButton(
              onPressed: questionsModule == null
                  ? null
                  : () => ModuleScreen._openForm(context, questionsModule),
              child: Text(t(context, 'addQuestion')),
            ),
          ),
        ),
      ],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _SoftIcon(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: AppTheme.primary),
    );
  }
}
