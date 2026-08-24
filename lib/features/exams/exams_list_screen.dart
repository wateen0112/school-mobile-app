import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/module_localization.dart';
import '../../core/network/exam_service.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/refreshable_content.dart';
import '../../widgets/shared_widgets.dart';
import 'exam_controller.dart';

class ExamsListScreen extends StatelessWidget {
  const ExamsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionController>();
    return ChangeNotifierProvider(
      create: (_) => ExamController(ExamService(session.api)),
      child: const _ExamsListView(),
    );
  }
}

class _ExamsListView extends StatefulWidget {
  const _ExamsListView();

  @override
  State<_ExamsListView> createState() => _ExamsListViewState();
}

class _ExamsListViewState extends State<_ExamsListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamController>().loadExams();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = appIsArabic(context);
    final controller = context.watch<ExamController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الاختبارات' : 'Exams'),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildBody(context, controller, isAr),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ExamController controller, bool isAr) {
    if (controller.loading && controller.exams.isEmpty) {
      return RefreshablePage(
        onRefresh: controller.loadExams,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.error != null && controller.exams.isEmpty) {
      return RefreshablePage(
        onRefresh: controller.loadExams,
        child: NoDataWidget(
          icon: Icons.error_outline_rounded,
          title: controller.error!,
          onRefresh: () => context.read<ExamController>().loadExams(),
        ),
      );
    }

    if (controller.exams.isEmpty) {
      return RefreshablePage(
        onRefresh: controller.loadExams,
        child: NoDataWidget(
          icon: Icons.assignment_rounded,
          title: isAr ? 'لا توجد اختبارات متاحة' : 'No exams available',
          message: t(context, 'noDataMessage'),
          onRefresh: controller.loadExams,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadExams,
      color: AppTheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: controller.exams.length,
        itemBuilder: (context, index) {
          final exam = controller.exams[index];
          return _ExamCard(
            exam: exam,
            isAr: isAr,
            onTap: () {
              if (exam.isFinished) {
                context.push('/student/exams/${exam.id}/result');
              } else {
                context.push('/student/exams/${exam.id}/start');
              }
            },
          );
        },
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({
    required this.exam,
    required this.isAr,
    required this.onTap,
  });

  final dynamic exam;
  final bool isAr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = exam.isFinished
        ? AppTheme.success
        : exam.isStarted
            ? AppTheme.warning
            : AppTheme.primary;

    final statusText = exam.isFinished
        ? (isAr ? 'تم الأداء' : 'Completed')
        : exam.isStarted
            ? (isAr ? 'مستمر' : 'In progress')
            : (isAr ? 'متاح' : 'Available');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.cloud,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.assignment_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        if (exam.subject != null)
                          Text(
                            exam.subject,
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.help_outline_rounded,
                    label: '${exam.questionsCount} ${isAr ? 'سؤال' : 'Questions'}',
                  ),
                  const SizedBox(width: 10),
                  _InfoChip(
                    icon: Icons.timer_outlined,
                    label: '${exam.timeLimit} ${isAr ? 'دقيقة' : 'min'}',
                  ),
                  if (exam.score != null) ...[
                    const SizedBox(width: 10),
                    _InfoChip(
                      icon: Icons.score_rounded,
                      label: '${exam.score}',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.muted),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
