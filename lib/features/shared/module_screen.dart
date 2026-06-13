import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/localization/module_localization.dart';
import '../../core/data/school_repository.dart';
import '../../core/models/app_models.dart';
import '../../core/network/api_service.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/dynamic_form.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/widgets/school_data_table.dart';
import '../../widgets/shared_widgets.dart';
import 'module_view_model.dart';

class ModuleScreen extends StatelessWidget {
  const ModuleScreen({super.key, required this.module});

  final ModuleSpec module;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(module.route),
      create: (context) => ModuleViewModel(
        module: module,
        repository: SchoolRepository(context.read<SessionController>().api),
      ),
      child: Consumer<ModuleViewModel>(
        builder: (context, viewModel, _) {
          final languageCode = Localizations.localeOf(context).languageCode;
          if (module.key == 'students') {
            Future.microtask(
              () => viewModel.ensureStudentFilters(languageCode),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
            children: [
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
                          else
                            DynamicModuleForm(
                              module: module,
                              initialValues: record?.raw,
                              fieldOptions: fieldOptions,
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
              initialValue: viewModel.selectedSectionId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: localizedColumnLabel(context, 'Section'),
                prefixIcon: const Icon(Icons.meeting_room_rounded),
                helperText: viewModel.selectedGradeId == null
                    ? (appIsArabic(context)
                          ? 'اختر المرحلة أولًا'
                          : 'Choose a grade first')
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
                      viewModel.selectedGradeId == null
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: AppTheme.promoGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: .18),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(module.icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizedModuleTitle(context, module),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    localizedModuleGoal(context, module),
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      'teacherDashboard' => const TeacherDashboardContent(),
      'studentDashboard' => const StudentDashboardContent(),
      'parentDashboard' => const ParentDashboardContent(),
      'attendance' => const AttendanceContent(),
      'attendanceHistory' => const AttendanceHistoryContent(),
      'examFlow' => const ExamFlowContent(),
      'financeTabs' => const FinanceTabsContent(),
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
      _ => SchoolDataTable(
        module: module,
        rows: viewModel.rowsFor(context),
        records: viewModel.records,
        onCreate: () => ModuleScreen._openForm(context, module),
        onEdit: (record) =>
            ModuleScreen._openForm(context, module, record: record),
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

class TeacherDashboardContent extends StatelessWidget {
  const TeacherDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _WelcomeCard(
          title: appIsArabic(context)
              ? 'مرحباً أيها المعلم'
              : 'Welcome, Teacher',
          subtitle: appIsArabic(context)
              ? 'لديك اليوم 4 أقسام واختباران للمراجعة.'
              : 'Today you have 4 sections and 2 quizzes to review.',
        ),
        const SizedBox(height: 12),
        _ScheduleCard(
          actions: appIsArabic(context)
              ? ['تسجيل الحضور', 'إنشاء اختبار']
              : ['Mark attendance', 'Create quiz'],
        ),
      ],
    );
  }
}

class StudentDashboardContent extends StatelessWidget {
  const StudentDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _WelcomeCard(
          title: appIsArabic(context) ? 'مرحباً بعودتك' : 'Welcome back',
          subtitle: appIsArabic(context)
              ? 'لديك 3 اختبارات قادمة هذا الأسبوع.'
              : 'You have 3 upcoming exams this week.',
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const _SoftIcon(icon: Icons.grade_rounded),
            title: Text(t(context, 'recentGrades')),
            subtitle: Text(t(context, 'recentGradesDesc')),
          ),
        ),
      ],
    );
  }
}

class ParentDashboardContent extends StatelessWidget {
  const ParentDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _WelcomeCard(
          title: appIsArabic(context) ? 'ملخص الأبناء' : 'Children summary',
          subtitle: appIsArabic(context)
              ? 'أحمد: الصف الخامس / القسم أ\nلانا: الصف الثاني / القسم ب'
              : 'Ahmed: Grade 5 / Section A\nLana: Grade 2 / Section B',
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const _SoftIcon(icon: Icons.notifications_rounded),
            title: Text(t(context, 'recentAlert')),
            subtitle: Text(t(context, 'recentAlertDesc')),
          ),
        ),
      ],
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey('attendance-grade-$_gradeId'),
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
                  onChanged: _loadingFilters || _saving ? null : _selectGrade,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey('attendance-classroom-$_classroomId'),
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
                  onChanged: _gradeId == null || _loadingFilters || _saving
                      ? null
                      : _selectClassroom,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey('attendance-section-$_sectionId'),
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

class FinanceTabsContent extends StatelessWidget {
  const FinanceTabsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Card(
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: t(context, 'fees')),
                Tab(text: t(context, 'receipts')),
              ],
            ),
            SizedBox(
              height: 260,
              child: TabBarView(
                children: [
                  ListTile(
                    title: Text(t(context, 'tuitionFee')),
                    subtitle: Text(t(context, 'unpaid200')),
                  ),
                  ListTile(
                    title: Text(t(context, 'receipt1021')),
                    subtitle: Text(t(context, 'paidDownload')),
                  ),
                ],
              ),
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

class BulkActionContent extends StatelessWidget {
  const BulkActionContent({
    super.key,
    required this.module,
    required this.action,
  });

  final ModuleSpec module;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: DynamicModuleForm(
        module: module,
        submitLabel: action,
        onSubmit: (_) async {
          final ok = await showConfirmationDialog(
            context,
            title: action,
            message: appIsArabic(context)
                ? 'يرجى تأكيد هذه العملية الجماعية.'
                : 'Please confirm this bulk operation.',
          );
          if (ok && context.mounted) {
            await context.read<ModuleViewModel>().create(const {});
          }
        },
      ),
    );
  }
}

class QuizContent extends StatelessWidget {
  const QuizContent({super.key, required this.module});

  final ModuleSpec module;

  @override
  Widget build(BuildContext context) {
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
              onPressed: () {},
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

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.softPanel(
        gradient: AppTheme.promoGradient,
        radius: 28,
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: AppTheme.honey,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: .86)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.actions});

  final List<String> actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appIsArabic(context) ? 'جدول اليوم' : "Today's schedule",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            ListTile(
              leading: const _SoftIcon(icon: Icons.schedule_rounded),
              title: Text(t(context, 'mathSectionA')),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final action in actions)
                  ActionChip(
                    avatar: const Icon(Icons.bolt_rounded, size: 18),
                    label: Text(action),
                    onPressed: () {},
                  ),
              ],
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
