import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/module_localization.dart';
import '../../core/network/exam_service.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import 'exam_controller.dart';
import 'exam_take_screen.dart';

class ExamStartScreen extends StatelessWidget {
  const ExamStartScreen({super.key, required this.quizId});

  final int quizId;

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionController>();
    return ChangeNotifierProvider(
      create: (_) => ExamController(ExamService(session.api)),
      child: _ExamStartView(quizId: quizId),
    );
  }
}

class _ExamStartView extends StatefulWidget {
  const _ExamStartView({required this.quizId});

  final int quizId;

  @override
  State<_ExamStartView> createState() => _ExamStartViewState();
}

class _ExamStartViewState extends State<_ExamStartView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamController>().loadExam(widget.quizId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = appIsArabic(context);
    final controller = context.watch<ExamController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'بدء الاختبار' : 'Start Exam'),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildBody(context, controller, isAr),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ExamController controller, bool isAr) {
    if (controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.coral, size: 48),
            const SizedBox(height: 12),
            Text(
              controller.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => controller.loadExam(widget.quizId),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      );
    }

    final exam = controller.currentExam;
    if (exam == null) {
      return Center(
        child: Text(isAr ? 'الاختبار غير موجود' : 'Exam not found'),
      );
    }

    if (exam.status != 'not_started' && exam.status != 'started') {
      return _buildAlreadyFinished(context, exam, isAr);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: .3),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  exam.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                if (exam.subject != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      exam.subject!,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                _buildInfoGrid(context, exam, isAr),
                const SizedBox(height: 28),
                _buildInstructions(context, isAr),
              ],
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: controller.submitting
              ? null
              : () => _startExam(context, controller),
          icon: controller.submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.play_arrow_rounded),
          label: Text(
            exam.status == 'started'
                ? (isAr ? 'متابعة الاختبار' : 'Continue Exam')
                : (isAr ? 'بدء الاختبار' : 'Start Exam'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(BuildContext context, dynamic exam, bool isAr) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _InfoTile(
          icon: Icons.help_outline_rounded,
          value: '${exam.questions.length}',
          label: isAr ? 'أسئلة' : 'Questions',
        ),
        _InfoTile(
          icon: Icons.timer_outlined,
          value: '${exam.timeLimit}',
          label: isAr ? 'دقيقة' : 'Minutes',
        ),
        _InfoTile(
          icon: Icons.school_outlined,
          value: exam.grade ?? '-',
          label: isAr ? 'المرحلة' : 'Grade',
        ),
        _InfoTile(
          icon: Icons.meeting_room_outlined,
          value: exam.classroom ?? '-',
          label: isAr ? 'الصف' : 'Classroom',
        ),
      ],
    );
  }

  Widget _buildInstructions(BuildContext context, bool isAr) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? 'تعليمات مهمة:' : 'Important instructions:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            _InstructionItem(
              isAr
                  ? 'اقرأ كل سؤال بعناية قبل اختيار الإجابة.'
                  : 'Read each question carefully before choosing an answer.',
            ),
            _InstructionItem(
              isAr
                  ? 'بمجرد الانتقال للسؤال التالي لا يمكنك العودة.'
                  : 'Once you move to the next question, you cannot go back.',
            ),
            _InstructionItem(
              isAr
                  ? 'سيُسلّم الاختبار تلقائياً عند انتهاء الوقت.'
                  : 'The exam will be submitted automatically when time runs out.',
            ),
            _InstructionItem(
              isAr
                  ? 'لا تحاول إعادة تحميل الصفحة أثناء الاختبار.'
                  : 'Do not try to reload the page during the exam.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyFinished(BuildContext context, dynamic exam, bool isAr) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 72),
          const SizedBox(height: 20),
          Text(
            isAr ? 'لقد أديت هذا الاختبار مسبقاً' : 'You have already taken this exam',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          if (exam.score != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${isAr ? 'النتيجة' : 'Score'}: ${exam.score}',
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 16,
                ),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/student/exams/${widget.quizId}/result'),
            icon: const Icon(Icons.visibility_rounded),
            label: Text(isAr ? 'عرض النتيجة' : 'View Result'),
          ),
        ],
      ),
    );
  }

  Future<void> _startExam(BuildContext context, ExamController controller) async {
    final started = await controller.startExam(widget.quizId);
    if (!started || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExamTakeScreen(
          controller: controller,
          quizId: widget.quizId,
        ),
      ),
    );

    if (context.mounted) {
      controller.loadExam(widget.quizId);
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primary, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  const _InstructionItem(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
