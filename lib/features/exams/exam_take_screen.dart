import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/module_localization.dart';
import '../../core/theme/app_theme.dart';
import 'exam_controller.dart';
import 'exam_result_screen.dart';

class ExamTakeScreen extends StatelessWidget {
  const ExamTakeScreen({
    super.key,
    required this.controller,
    required this.quizId,
  });

  final ExamController controller;
  final int quizId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: const _ExamTakeView(),
    );
  }
}

class _ExamTakeView extends StatelessWidget {
  const _ExamTakeView();

  @override
  Widget build(BuildContext context) {
    final isAr = appIsArabic(context);
    final controller = context.watch<ExamController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canExit = await _confirmExit(context, isAr);
        if (canExit && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(isAr ? 'الاختبار' : 'Exam'),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: controller.remainingSeconds < 60
                        ? AppTheme.coral.withValues(alpha: .12)
                        : AppTheme.cloud,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_rounded,
                        size: 18,
                        color: controller.remainingSeconds < 60
                            ? AppTheme.coral
                            : AppTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        controller.formattedRemainingTime,
                        style: TextStyle(
                          color: controller.remainingSeconds < 60
                              ? AppTheme.coral
                              : AppTheme.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
          ],
        ),
      );
    }

    if (controller.examFinished && controller.result != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ExamResultScreen(
                controller: controller,
                quizId: controller.currentExam?.id ?? 0,
              ),
            ),
          );
        }
      });
      return const SizedBox.shrink();
    }

    final question = controller.currentQuestion;
    if (question == null) {
      return Center(child: Text(isAr ? 'لا يوجد أسئلة' : 'No questions'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: (controller.currentQuestionIndex + 1) / controller.currentExam!.questions.length,
          backgroundColor: AppTheme.cloud,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 16),
        Text(
          '${isAr ? 'سؤال' : 'Question'} ${controller.currentQuestionIndex + 1} ${isAr ? 'من' : 'of'} ${controller.currentExam!.questions.length}',
          style: const TextStyle(
            color: AppTheme.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              question.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: question.answers.length,
            itemBuilder: (context, index) {
              final answer = question.answers[index];
              final isSelected = controller.selectedAnswers[question.id] == answer;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => controller.selectAnswer(answer),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : AppTheme.cloud,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: .25),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected ? Colors.white : AppTheme.muted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            answer,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.currentQuestionIndex > 0
                    ? controller.previousQuestion
                    : null,
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(isAr ? 'السابق' : 'Previous'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: controller.submitting || controller.selectedAnswers[question.id] == null
                    ? null
                    : () => _onNextOrSubmit(context, controller, isAr),
                icon: controller.submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(controller.isLastQuestion ? Icons.check_rounded : Icons.arrow_forward_rounded),
                label: Text(
                  controller.isLastQuestion
                      ? (isAr ? 'إنهاء' : 'Finish')
                      : (isAr ? 'التالي' : 'Next'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _onNextOrSubmit(BuildContext context, ExamController controller, bool isAr) async {
    final success = await controller.submitCurrentAnswer();
    if (!success || !context.mounted) return;

    if (controller.isLastQuestion) {
      final confirmed = await _confirmSubmit(context, isAr);
      if (!confirmed || !context.mounted) return;

      await controller.finishExam();
      return;
    }

    controller.nextQuestion();
  }

  Future<bool> _confirmSubmit(BuildContext context, bool isAr) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAr ? 'إنهاء الاختبار' : 'Finish Exam'),
        content: Text(
          isAr
              ? 'هل أنت متأكد من إنهاء الاختبار؟ لا يمكنك التراجع بعد ذلك.'
              : 'Are you sure you want to finish the exam? You cannot undo this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isAr ? 'إنهاء' : 'Finish'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _confirmExit(BuildContext context, bool isAr) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAr ? 'مغادرة الاختبار' : 'Leave Exam'),
        content: Text(
          isAr
              ? 'إذا غادرت الآن سيُسلّم الاختبار تلقائياً. هل تريد المتابعة؟'
              : 'If you leave now, the exam will be submitted automatically. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isAr ? 'البقاء' : 'Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isAr ? 'مغادرة' : 'Leave'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await context.read<ExamController>().finishExam();
    }

    return result ?? false;
  }
}
