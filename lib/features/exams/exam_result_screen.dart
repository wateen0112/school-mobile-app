import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/module_localization.dart';
import '../../core/models/quiz_models.dart';
import '../../core/network/exam_service.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import 'exam_controller.dart';

class ExamResultScreen extends StatelessWidget {
  const ExamResultScreen({
    super.key,
    this.controller,
    required this.quizId,
  });

  final ExamController? controller;
  final int quizId;

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionController>();
    return ChangeNotifierProvider(
      create: (_) => controller ?? ExamController(ExamService(session.api)),
      child: _ExamResultView(quizId: quizId, hasController: controller != null),
    );
  }
}

class _ExamResultView extends StatefulWidget {
  const _ExamResultView({required this.quizId, required this.hasController});

  final int quizId;
  final bool hasController;

  @override
  State<_ExamResultView> createState() => _ExamResultViewState();
}

class _ExamResultViewState extends State<_ExamResultView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<ExamController>();
      if (controller.result == null || controller.result?.quiz.id != widget.quizId) {
        controller.loadResult(widget.quizId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = appIsArabic(context);
    final controller = context.watch<ExamController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'نتيجة الاختبار' : 'Exam Result'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/student/exams'),
        ),
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
    if (controller.loading || controller.result == null) {
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
              onPressed: () => controller.loadResult(widget.quizId),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      );
    }

    final result = controller.result!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildScoreCard(context, result, isAr),
        const SizedBox(height: 16),
        Text(
          isAr ? 'مراجعة الإجابات' : 'Review Answers',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: result.questions.length,
            itemBuilder: (context, index) {
              return _QuestionReviewCard(
                question: result.questions[index],
                index: index,
                isAr: isAr,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => context.go('/student/exams'),
          icon: const Icon(Icons.home_rounded),
          label: Text(isAr ? 'العودة للاختبارات' : 'Back to Exams'),
        ),
      ],
    );
  }

  Widget _buildScoreCard(BuildContext context, ExamResultModel result, bool isAr) {
    final passed = result.percentage >= 50;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: passed ? AppTheme.heroGradient : AppTheme.ctaGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (passed ? AppTheme.primary : AppTheme.coral).withValues(alpha: .3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            result.quiz.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          if (result.quiz.subject != null)
            Text(
              result.quiz.subject!,
              style: const TextStyle(color: Colors.white70),
            ),
          const SizedBox(height: 20),
          Text(
            '${result.totalScore.toStringAsFixed(1)} / ${result.maxScore.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${result.percentage.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            '${isAr ? 'الوقت المستغرق' : 'Time spent'}: ${ExamController.formatDuration(result.timeSpentSeconds)}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  const _QuestionReviewCard({
    required this.question,
    required this.index,
    required this.isAr,
  });

  final ResultQuestionModel question;
  final int index;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: question.isCorrect ? AppTheme.success : AppTheme.coral,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${isAr ? 'سؤال' : 'Q'} ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${question.studentScore.toStringAsFixed(1)} / ${question.score.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: question.isCorrect ? AppTheme.success : AppTheme.coral,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            ...question.answers.map((answer) {
              final isCorrect = answer == question.rightAnswer;
              final isSelected = answer == question.studentAnswer;

              Color borderColor = AppTheme.cloud;
              Color bgColor = Colors.white;
              Color textColor = AppTheme.ink;
              IconData? icon;
              Color? iconColor;

              if (isCorrect) {
                borderColor = AppTheme.success;
                bgColor = AppTheme.success.withValues(alpha: .08);
                icon = Icons.check_circle_rounded;
                iconColor = AppTheme.success;
              }

              if (isSelected && !isCorrect) {
                borderColor = AppTheme.coral;
                bgColor = AppTheme.coral.withValues(alpha: .08);
                icon = Icons.cancel_rounded;
                iconColor = AppTheme.coral;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: iconColor, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        answer,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
