import '../localization/error_messages.dart';
import '../models/quiz_models.dart';
import 'api_service.dart';

class ExamService {
  const ExamService(this._api);

  final ApiService _api;

  Future<List<QuizModel>> fetchExams({
    String? languageCode,
  }) async {
    final response = await _api.get('/student/exams');
    return _parseQuizList(response, languageCode: languageCode);
  }

  /// Exams created by the authenticated teacher (scoped server-side).
  Future<List<QuizModel>> fetchTeacherExams({
    String? languageCode,
  }) async {
    final response = await _api.get('/teacher/exams');
    return _parseQuizList(response, languageCode: languageCode);
  }

  List<QuizModel> _parseQuizList(
    Map<String, dynamic> response, {
    String? languageCode,
  }) {
    final data = response['data'];

    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) => QuizModel.fromJson(
              Map<String, dynamic>.from(item),
              languageCode: languageCode,
            ),
          )
          .toList();
    }

    return [];
  }

  Future<QuizDetailModel> fetchExam(
    int quizId, {
    String? languageCode,
  }) async {
    final response = await _api.get('/student/exams/$quizId');
    return QuizDetailModel.fromJson(
      response['data'] as Map<String, dynamic>,
      languageCode: languageCode,
    );
  }

  Future<Map<String, dynamic>> startExam(int quizId) async {
    final response = await _api.post('/student/exams/$quizId/start');
    return response;
  }

  Future<Map<String, dynamic>> submitAnswer(
    int quizId,
    int questionId,
    String answer,
  ) async {
    final response = await _api.post('/student/exams/$quizId/answer', data: {
      'question_id': questionId,
      'answer': answer,
    });
    return response;
  }

  Future<Map<String, dynamic>> submitExam(int quizId) async {
    final response = await _api.post('/student/exams/$quizId/submit');
    return response;
  }

  Future<ExamResultModel> fetchResult(
    int quizId, {
    String? languageCode,
  }) async {
    final response = await _api.get('/student/exams/$quizId/result');
    return ExamResultModel.fromJson(
      response['data'] as Map<String, dynamic>,
      languageCode: languageCode,
    );
  }
}

class QuizDetailModel {
  const QuizDetailModel({
    required this.id,
    required this.name,
    this.subject,
    this.grade,
    this.classroom,
    this.section,
    required this.timeLimit,
    required this.status,
    this.score,
    required this.questions,
  });

  final int id;
  final String name;
  final String? subject;
  final String? grade;
  final String? classroom;
  final String? section;
  final int timeLimit;
  final String status;
  final double? score;
  final List<QuestionModel> questions;

factory QuizDetailModel.fromJson(
    Map<String, dynamic> json, {
    String? languageCode,
  }) {
    final lang = languageCode ?? ErrorLocale.languageCode;
    final questionsRaw = json['questions'];
    final questions = questionsRaw is List
        ? questionsRaw
            .map(
              (e) => QuestionModel.fromJson(
                e as Map<String, dynamic>,
                languageCode: lang,
              ),
            )
            .toList()
        : <QuestionModel>[];

    return QuizDetailModel(
      id: json['id'] as int,
      name: quizLocalizedString(json['name'], lang),
      subject: quizRelationName(json['subject'], lang).letNullable(),
      grade: quizRelationName(json['grade'], lang).letNullable(),
      classroom: quizRelationName(json['classroom'], lang).letNullable(),
      section: quizRelationName(json['section'], lang).letNullable(),
      timeLimit: (json['time_limit'] as num?)?.toInt() ?? 0,
      status: '${json['status'] ?? 'not_started'}',
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      questions: questions,
    );
  }
}
