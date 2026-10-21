import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/app_theme.dart';
import 'package:frontend/features/interviews/screens/interview_completion_screen.dart';
import 'package:frontend/features/interviews/screens/interview_list_screen.dart';
import 'package:frontend/features/interviews/screens/interview_session_screen.dart';
import 'package:frontend/features/interviews/screens/interview_setup_screen.dart';
import 'package:frontend/models/interview_model.dart';
import 'package:frontend/models/job_model.dart';
import 'package:frontend/models/resume_model.dart';
import 'package:frontend/providers/interview_provider.dart';
import 'package:frontend/providers/job_provider.dart';
import 'package:frontend/providers/resume_provider.dart';
import 'package:frontend/services/interview_service.dart';

class MockInterviewService extends InterviewService {
  final InterviewSessionModel mockSession;
  final InterviewQuestionModel mockQuestion;

  MockInterviewService({
    required this.mockSession,
    required this.mockQuestion,
  });

  @override
  Future<InterviewSessionModel> getSession(String sessionId) async => mockSession;

  @override
  Future<InterviewQuestionModel> getCurrentQuestion(String sessionId) async => mockQuestion;

  @override
  Future<InterviewAnswerModel> submitAnswer({
    required String sessionId,
    required String answerText,
  }) async {
    return InterviewAnswerModel(
      id: 'ans-1',
      sessionId: sessionId,
      questionId: mockQuestion.id,
      answerText: answerText,
      wordCount: answerText.trim().split(RegExp(r'\s+')).length,
      charCount: answerText.length,
      revisionNumber: 1,
    );
  }

  @override
  Future<InterviewNextResultModel> advanceNext(String sessionId) async {
    return InterviewNextResultModel(
      session: mockSession,
      isCompleted: false,
      nextQuestion: mockQuestion,
      adaptationNote: 'Calibrated to medium difficulty.',
    );
  }

  @override
  Future<void> abandonSession(String sessionId) async {}
}

void main() {
  group('Interview Screens UI Tests', () {
    testWidgets('InterviewSetupScreen renders configuration form, job selector, and consent', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockJob = JobModel(
        id: 'job-1',
        recruiterId: 'rec-1',
        title: 'Backend Python Engineer',
        company: 'AI Solutions',
        description: 'Design and deploy APIs',
        requiredSkills: const ['Python', 'FastAPI'],
      );

      final mockResume = ResumeModel(
        id: 'res-1',
        userId: 'usr-1',
        filename: 'my_resume.pdf',
        fileType: 'pdf',
        fileSize: 1024,
        extractionStatus: 'completed',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            jobsListProvider.overrideWith((ref) => Future.value([mockJob])),
            resumesListProvider.overrideWith((ref) => Future.value([mockResume])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const InterviewSetupScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Interview Setup & Guidelines'), findsOneWidget);
      expect(find.text('Target Position'), findsOneWidget);
      expect(find.text('Candidate Guidelines & Integrity'), findsOneWidget);
      expect(find.text('Begin Interview Session'), findsOneWidget);
    });

    testWidgets('InterviewListScreen displays empty state when candidate has no sessions', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myInterviewSessionsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const InterviewListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Interview Sessions'), findsOneWidget);
      expect(find.text('No Interview Sessions Found'), findsOneWidget);
      expect(find.text('Start New Interview'), findsOneWidget);
    });

    testWidgets('InterviewListScreen displays sessions list with status and progress count', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockSummary = InterviewSessionSummaryModel(
        id: 'sess-active-1',
        jobId: 'job-1',
        jobTitle: 'Senior Full Stack Engineer',
        company: 'Cloud Scale AI',
        status: 'in_progress',
        currentQuestionIndex: 1,
        totalQuestionCount: 5,
        answeredCount: 1,
        startedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myInterviewSessionsProvider.overrideWith((ref) => Future.value([mockSummary])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const InterviewListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Senior Full Stack Engineer'), findsOneWidget);
      expect(find.text('Cloud Scale AI'), findsOneWidget);
      expect(find.text('IN_PROGRESS'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Progress: 1 / 5 questions answered'), findsOneWidget);
    });

    testWidgets('InterviewSessionScreen renders active question, tags, and answer field', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockSession = InterviewSessionModel(
        id: 'sess-run-1',
        userId: 'u-1',
        jobId: 'j-1',
        status: 'in_progress',
        currentQuestionIndex: 0,
        totalQuestionCount: 3,
        jobTitle: 'Lead Flutter Developer',
        company: 'Mobile Dynamics',
      );

      final mockQuestion = InterviewQuestionModel(
        id: 'q-run-1',
        sessionId: 'sess-run-1',
        questionText: 'Explain Riverpod code generation and provider lifecycle in Flutter.',
        category: 'technical',
        skill: 'Flutter',
        difficulty: 'medium',
        questionOrder: 0,
        questionSource: 'predefined',
        selectionReason: 'Core competency assessment',
      );

      final mockService = MockInterviewService(
        mockSession: mockSession,
        mockQuestion: mockQuestion,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            interviewServiceProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const InterviewSessionScreen(sessionId: 'sess-run-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Lead Flutter Developer'), findsOneWidget);
      expect(find.text('Question 1 of 3'), findsOneWidget);
      expect(find.text('TECHNICAL'), findsOneWidget);
      expect(find.text('MEDIUM'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Explain Riverpod code generation and provider lifecycle in Flutter.'), findsOneWidget);
      expect(find.text('Abandon'), findsOneWidget);
      expect(find.text('Your Response'), findsOneWidget);
      expect(find.text('Submit Answer'), findsOneWidget);
      expect(find.text('Next Question'), findsOneWidget);
    });

    testWidgets('InterviewCompletionScreen renders completion status and Phase 7 notice', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final completedSession = InterviewSessionModel(
        id: 'sess-done-1',
        userId: 'u-1',
        jobId: 'j-1',
        status: 'completed',
        currentQuestionIndex: 5,
        totalQuestionCount: 5,
        jobTitle: 'Senior Python Engineer',
        startedAt: DateTime.parse('2026-10-19T10:00:00Z'),
        completedAt: DateTime.parse('2026-10-19T10:25:00Z'),
      );

      final mockQuestion = InterviewQuestionModel(
        id: 'q-1',
        sessionId: 'sess-done-1',
        questionText: 'Question text',
        category: 'technical',
        skill: 'Python',
        difficulty: 'medium',
        questionOrder: 0,
        questionSource: 'predefined',
      );

      final mockService = MockInterviewService(
        mockSession: completedSession,
        mockQuestion: mockQuestion,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            interviewServiceProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const InterviewCompletionScreen(sessionId: 'sess-done-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Interview Session Completed'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('Questions Answered'), findsOneWidget);
      expect(find.text('5 of 5'), findsOneWidget);
      expect(find.text('My Interviews'), findsOneWidget);
      expect(find.text('Explore Jobs'), findsOneWidget);
    });
  });
}
