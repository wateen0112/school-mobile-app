import '../localization/error_messages.dart';

/// Resolves a possibly-localized value (String or `{en, ar}` map) into a
/// string in the requested language.
String quizLocalizedString(dynamic value, String languageCode) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is Map) {
    final lang = value[languageCode];
    if (lang != null) return '$lang';
    final ar = value['ar'];
    if (ar != null) return '$ar';
    final en = value['en'];
    if (en != null) return '$en';
    final first = value.values.whereType<String>().firstOrNull;
    return first ?? '';
  }
  return '$value';
}

/// Extracts a display string from a nested relation object such as
/// `subject: {id: 2, Name: {en, ar}}` or `grade: {Name: {en, ar}}`, falling
/// back to the raw value when the shape does not match.
String quizRelationName(dynamic value, String languageCode) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is Map) {
    final key = value.keys
        .where(
          (k) =>
              k is String &&
              (k.toLowerCase() == 'name' ||
                  k.toLowerCase().contains('name')),
        )
        .firstOrNull;
    if (key != null) {
      final name = quizLocalizedString(value[key], languageCode);
      if (name.isNotEmpty) return name;
    }
    return quizLocalizedString(value, languageCode);
  }
  return '$value';
}

class QuizModel {
  const QuizModel({
    required this.id,
    required this.name,
    this.subject,
    this.grade,
    this.classroom,
    this.section,
    this.teacherId,
    required this.timeLimit,
    required this.questionsCount,
    required this.status,
    this.score,
    this.startedAt,
    this.submittedAt,
  });

  final int id;
  final String name;
  final String? subject;
  final String? grade;
  final String? classroom;
  final String? section;
  final int? teacherId;
  final int timeLimit;
  final int questionsCount;
  final String status;
  final double? score;
  final String? startedAt;
  final String? submittedAt;

  factory QuizModel.fromJson(
    Map<String, dynamic> json, {
    String? languageCode,
  }) {
    final lang = languageCode ?? ErrorLocale.languageCode;
    return QuizModel(
      id: json['id'] as int,
      name: quizLocalizedString(json['name'], lang),
      subject: quizRelationName(json['subject'], lang).letNullable(),
      grade: quizRelationName(json['grade'], lang).letNullable(),
      classroom: quizRelationName(json['classroom'], lang).letNullable(),
      section: quizRelationName(json['section'], lang).letNullable(),
      teacherId: (json['teacher_id'] as num?)?.toInt(),
      timeLimit: (json['time_limit'] as num?)?.toInt() ?? 0,
      questionsCount: (json['questions_count'] as num?)?.toInt() ?? 0,
      status: '${json['status'] ?? 'not_started'}',
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      startedAt: json['started_at'] as String?,
      submittedAt: json['submitted_at'] as String?,
    );
  }

  bool get isNotStarted => status == 'not_started';
  bool get isStarted => status == 'started';
  bool get isSubmitted => status == 'submitted';
  bool get isFinished => status == 'submitted' || status == 'timeout' || status == 'abuse';
}

extension NullableString on String {
  String? letNullable() => isEmpty ? null : this;
}

class QuestionModel {
  const QuestionModel({
    required this.id,
    required this.title,
    required this.answers,
    required this.score,
  });

  final int id;
  final String title;
  final List<String> answers;
  final double score;

  factory QuestionModel.fromJson(
    Map<String, dynamic> json, {
    String? languageCode,
  }) {
    final lang = languageCode ?? ErrorLocale.languageCode;
    final answersRaw = json['answers'];
    final answers = answersRaw is List
        ? answersRaw
            .where((e) => e is String || e is Map)
            .map((e) => quizLocalizedString(e, lang))
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    return QuestionModel(
      id: json['id'] as int,
      title: quizLocalizedString(json['title'] ?? json['name'], lang),
      answers: answers,
      score: (json['score'] as num?)?.toDouble() ?? 0,
    );
  }
}

class StudentAnswerModel {
  const StudentAnswerModel({
    required this.questionId,
    this.selectedAnswer,
    required this.isCorrect,
    required this.score,
  });

  final int questionId;
  final String? selectedAnswer;
  final bool isCorrect;
  final double score;

  factory StudentAnswerModel.fromJson(Map<String, dynamic> json) {
    return StudentAnswerModel(
      questionId: json['question_id'] as int,
      selectedAnswer: json['selected_answer'] as String?,
      isCorrect: json['is_correct'] == true,
      score: (json['score'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ExamResultModel {
  const ExamResultModel({
    required this.quiz,
    required this.totalScore,
    required this.maxScore,
    required this.percentage,
    required this.timeSpentSeconds,
    required this.status,
    required this.questions,
  });

  final QuizSummaryModel quiz;
  final double totalScore;
  final double maxScore;
  final double percentage;
  final int timeSpentSeconds;
  final String status;
  final List<ResultQuestionModel> questions;

  factory ExamResultModel.fromJson(
    Map<String, dynamic> json, {
    String? languageCode,
  }) {
    final lang = languageCode ?? ErrorLocale.languageCode;
    return ExamResultModel(
      quiz: QuizSummaryModel.fromJson(
        json['quiz'] as Map<String, dynamic>,
        languageCode: lang,
      ),
      totalScore: (json['total_score'] as num?)?.toDouble() ?? 0,
      maxScore: (json['max_score'] as num?)?.toDouble() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      timeSpentSeconds: (json['time_spent_seconds'] as num?)?.toInt() ?? 0,
      status: '${json['status'] ?? 'submitted'}',
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map(
            (e) => ResultQuestionModel.fromJson(
              e as Map<String, dynamic>,
              languageCode: lang,
            ),
          )
          .toList(),
    );
  }
}

class QuizSummaryModel {
  const QuizSummaryModel({
    required this.id,
    required this.name,
    this.subject,
    required this.timeLimit,
  });

  final int id;
  final String name;
  final String? subject;
  final int timeLimit;

  factory QuizSummaryModel.fromJson(
    Map<String, dynamic> json, {
    String? languageCode,
  }) {
    final lang = languageCode ?? ErrorLocale.languageCode;
    return QuizSummaryModel(
      id: json['id'] as int,
      name: quizLocalizedString(json['name'], lang),
      subject: quizRelationName(json['subject'], lang).letNullable(),
      timeLimit: (json['time_limit'] as num?)?.toInt() ?? 0,
    );
  }
}

class ResultQuestionModel {
  const ResultQuestionModel({
    required this.id,
    required this.title,
    required this.answers,
    required this.rightAnswer,
    required this.score,
    this.studentAnswer,
    required this.isCorrect,
    required this.studentScore,
  });

  final int id;
  final String title;
  final List<String> answers;
  final String rightAnswer;
  final double score;
  final String? studentAnswer;
  final bool isCorrect;
  final double studentScore;

  factory ResultQuestionModel.fromJson(
    Map<String, dynamic> json, {
    String? languageCode,
  }) {
    final lang = languageCode ?? ErrorLocale.languageCode;
    final answersRaw = json['answers'];
    final answers = answersRaw is List
        ? answersRaw
            .where((e) => e is String || e is Map)
            .map((e) => quizLocalizedString(e, lang))
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    return ResultQuestionModel(
      id: json['id'] as int,
      title: quizLocalizedString(json['title'] ?? json['name'], lang),
      answers: answers,
      rightAnswer: quizLocalizedString(json['right_answer'], lang),
      score: (json['score'] as num?)?.toDouble() ?? 0,
      studentAnswer:
          quizLocalizedString(json['student_answer'], lang).letNullable(),
      isCorrect: json['is_correct'] == true,
      studentScore: (json['student_score'] as num?)?.toDouble() ?? 0,
    );
  }
}
