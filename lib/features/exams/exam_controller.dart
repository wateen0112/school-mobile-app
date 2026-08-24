import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/quiz_models.dart';
import '../../core/network/api_service.dart';
import '../../core/network/exam_service.dart';

class ExamController extends ChangeNotifier {
  ExamController(this._service);

  final ExamService _service;

  List<QuizModel> _exams = [];
  bool _loading = false;
  String? _error;

  QuizDetailModel? _currentExam;
  int _currentQuestionIndex = 0;
  final Map<int, String> _selectedAnswers = {};
  bool _submitting = false;
  bool _examFinished = false;
  ExamResultModel? _result;

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _timeUp = false;

  List<QuizModel> get exams => _exams;
  bool get loading => _loading;
  String? get error => _error;

  QuizDetailModel? get currentExam => _currentExam;
  int get currentQuestionIndex => _currentQuestionIndex;
  Map<int, String> get selectedAnswers => _selectedAnswers;
  bool get submitting => _submitting;
  bool get examFinished => _examFinished;
  ExamResultModel? get result => _result;

  int get remainingSeconds => _remainingSeconds;
  bool get timeUp => _timeUp;

  QuestionModel? get currentQuestion {
    if (_currentExam == null) return null;
    if (_currentQuestionIndex < 0 || _currentQuestionIndex >= _currentExam!.questions.length) {
      return null;
    }
    return _currentExam!.questions[_currentQuestionIndex];
  }

  bool get isLastQuestion {
    if (_currentExam == null) return false;
    return _currentQuestionIndex == _currentExam!.questions.length - 1;
  }

  Future<void> loadExams({String? languageCode}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _exams = await _service.fetchExams(languageCode: languageCode);
    } catch (e) {
      _error = ApiService.failureFrom(e).message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadExam(int quizId, {String? languageCode}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _currentExam = await _service.fetchExam(
        quizId,
        languageCode: languageCode,
      );
      _currentQuestionIndex = 0;
      _selectedAnswers.clear();
    } catch (e) {
      _error = ApiService.failureFrom(e).message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> startExam(int quizId, {String? languageCode}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.startExam(quizId);

      if (response['success'] != true) {
        _error = '${response['message'] ?? 'Could not start exam'}';
        _loading = false;
        notifyListeners();
        return false;
      }

      _currentExam = await _service.fetchExam(
        quizId,
        languageCode: languageCode,
      );
      _currentQuestionIndex = 0;
      _selectedAnswers.clear();
      _examFinished = false;
      _result = null;
      _startTimer();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiService.failureFrom(e).message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void selectAnswer(String answer) {
    final question = currentQuestion;
    if (question == null) return;
    _selectedAnswers[question.id] = answer;
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentExam == null) return;
    if (_currentQuestionIndex < _currentExam!.questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  Future<bool> submitCurrentAnswer() async {
    final question = currentQuestion;
    if (question == null || _currentExam == null) return false;

    final answer = _selectedAnswers[question.id];
    if (answer == null) return false;

    _submitting = true;
    notifyListeners();

    try {
      final response = await _service.submitAnswer(_currentExam!.id, question.id, answer);

      if (response['success'] != true) {
        _error = '${response['message'] ?? 'Could not submit answer'}';
        _submitting = false;
        notifyListeners();
        return false;
      }

      _submitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiService.failureFrom(e).message;
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> finishExam() async {
    if (_currentExam == null) return false;

    _submitting = true;
    notifyListeners();

    try {
      _stopTimer();
      final response = await _service.submitExam(_currentExam!.id);

      if (response['success'] != true) {
        _error = '${response['message'] ?? 'Could not submit exam'}';
        _submitting = false;
        notifyListeners();
        return false;
      }

      _examFinished = true;
      _submitting = false;
      await loadResult(_currentExam!.id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiService.failureFrom(e).message;
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadResult(int quizId, {String? languageCode}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _result = await _service.fetchResult(
        quizId,
        languageCode: languageCode,
      );
    } catch (e) {
      _error = ApiService.failureFrom(e).message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _startTimer() {
    _stopTimer();
    if (_currentExam == null || _currentExam!.timeLimit <= 0) return;

    _remainingSeconds = _currentExam!.timeLimit * 60;
    _timeUp = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        _timeUp = true;
        _stopTimer();
        finishExam();
        return;
      }
      _remainingSeconds--;
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String get formattedRemainingTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
