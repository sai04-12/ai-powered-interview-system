import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/interview_model.dart';
import 'package:frontend/services/interview_service.dart';

final interviewServiceProvider = Provider<InterviewService>((ref) {
  return InterviewService();
});

final myInterviewSessionsProvider = FutureProvider.autoDispose<List<InterviewSessionSummaryModel>>((ref) async {
  final service = ref.watch(interviewServiceProvider);
  return service.getMySessions();
});

class InterviewActiveState {
  final InterviewSessionModel? session;
  final InterviewQuestionModel? currentQuestion;
  final String currentAnswerText;
  final bool hasSubmittedCurrentAnswer;
  final bool isLoading;
  final bool isSubmitting;
  final bool isAdvancing;
  final bool isCompleted;
  final String? lastAdaptationNote;
  final String? errorMessage;

  const InterviewActiveState({
    this.session,
    this.currentQuestion,
    this.currentAnswerText = '',
    this.hasSubmittedCurrentAnswer = false,
    this.isLoading = false,
    this.isSubmitting = false,
    this.isAdvancing = false,
    this.isCompleted = false,
    this.lastAdaptationNote,
    this.errorMessage,
  });

  InterviewActiveState copyWith({
    InterviewSessionModel? session,
    InterviewQuestionModel? currentQuestion,
    String? currentAnswerText,
    bool? hasSubmittedCurrentAnswer,
    bool? isLoading,
    bool? isSubmitting,
    bool? isAdvancing,
    bool? isCompleted,
    String? lastAdaptationNote,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InterviewActiveState(
      session: session ?? this.session,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      currentAnswerText: currentAnswerText ?? this.currentAnswerText,
      hasSubmittedCurrentAnswer: hasSubmittedCurrentAnswer ?? this.hasSubmittedCurrentAnswer,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isAdvancing: isAdvancing ?? this.isAdvancing,
      isCompleted: isCompleted ?? this.isCompleted,
      lastAdaptationNote: lastAdaptationNote ?? this.lastAdaptationNote,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class InterviewNotifier extends Notifier<InterviewActiveState> {
  late final InterviewService _service;

  @override
  InterviewActiveState build() {
    _service = ref.watch(interviewServiceProvider);
    return const InterviewActiveState();
  }

  Future<void> loadSession(String sessionId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _service.getSession(sessionId);
      InterviewQuestionModel? q;
      if (session.isInProgress) {
        try {
          q = await _service.getCurrentQuestion(sessionId);
        } catch (_) {}
      }
      state = state.copyWith(
        session: session,
        currentQuestion: q,
        isLoading: false,
        isCompleted: session.isCompleted,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> startSession(String sessionId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _service.startSession(sessionId);
      InterviewQuestionModel? q;
      try {
        q = await _service.getCurrentQuestion(sessionId);
      } catch (_) {}
      state = state.copyWith(
        session: session,
        currentQuestion: q,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void updateAnswerText(String text) {
    state = state.copyWith(currentAnswerText: text);
  }

  Future<bool> submitAnswer(String sessionId) async {
    if (state.currentAnswerText.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please type an answer before submitting.');
      return false;
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _service.submitAnswer(
        sessionId: sessionId,
        answerText: state.currentAnswerText.trim(),
      );
      state = state.copyWith(
        isSubmitting: false,
        hasSubmittedCurrentAnswer: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> advanceNext(String sessionId) async {
    state = state.copyWith(isAdvancing: true, clearError: true);
    try {
      final result = await _service.advanceNext(sessionId);
      state = state.copyWith(
        session: result.session,
        currentQuestion: result.nextQuestion,
        currentAnswerText: '',
        hasSubmittedCurrentAnswer: false,
        isAdvancing: false,
        isCompleted: result.isCompleted,
        lastAdaptationNote: result.adaptationNote,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isAdvancing: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> abandonSession(String sessionId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.abandonSession(sessionId);
      final session = await _service.getSession(sessionId);
      state = state.copyWith(session: session, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void clearSession() {
    state = const InterviewActiveState();
  }
}

final interviewNotifierProvider = NotifierProvider<InterviewNotifier, InterviewActiveState>(
  InterviewNotifier.new,
);
