import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/app_theme.dart';
import 'package:frontend/features/evaluation/screens/interview_evaluation_screen.dart';
import 'package:frontend/models/evaluation_model.dart';
import 'package:frontend/providers/evaluation_provider.dart';
import 'package:frontend/services/evaluation_service.dart';

class MockEvaluationService extends EvaluationService {
  final SessionEvaluationReportModel? mockReport;
  final bool shouldThrow;

  MockEvaluationService({
    this.mockReport,
    this.shouldThrow = false,
  });

  @override
  Future<SessionEvaluationReportModel> getSessionReport(String sessionId) async {
    if (shouldThrow) {
      throw Exception('Simulated report network failure');
    }
    return mockReport ??
        SessionEvaluationReportModel(
          sessionId: sessionId,
          candidateId: 'cand-1',
          jobId: 'job-1',
          status: 'completed',
          totalQuestions: 1,
          answeredQuestions: 1,
          evaluatedQuestions: 1,
          evaluationLimitations: 'AI rubric evaluation disclaimer.',
          isComplete: true,
        );
  }

  @override
  Future<SessionEvaluationReportModel> evaluateSession(
    String sessionId, {
    bool forceReevaluate = false,
  }) async {
    if (shouldThrow) {
      throw Exception('Simulated evaluation failure');
    }
    return mockReport ??
        SessionEvaluationReportModel(
          sessionId: sessionId,
          candidateId: 'cand-1',
          jobId: 'job-1',
          status: 'completed',
          totalQuestions: 1,
          answeredQuestions: 1,
          evaluatedQuestions: 1,
          evaluationLimitations: 'AI rubric evaluation disclaimer.',
          isComplete: true,
        );
  }
}

void main() {
  final sampleReport = SessionEvaluationReportModel(
    sessionId: 'sess-eval-12345',
    candidateId: 'user-cand-1',
    jobId: 'job-python-dev',
    jobTitle: 'Senior Python Developer',
    company: 'FastCloud Ltd',
    status: 'completed',
    totalQuestions: 1,
    answeredQuestions: 1,
    evaluatedQuestions: 1,
    averageOverallScore: 88.5,
    averageRubricScore: 3.54,
    aggregatedStrengths: ['Outstanding asyncio comprehension', 'Production database patterns'],
    aggregatedImprovements: ['Explore distributed cache invalidation strategies'],
    evaluationLimitations:
        'AI rubric evaluation assesses only candidate submitted text against specified rubrics and does not measure overall worth or future performance.',
    evaluatorType: 'deterministic',
    isComplete: true,
    questionEvaluations: [
      SessionQuestionEvaluationModel(
        questionId: 'q-101',
        questionOrder: 0,
        questionText: 'Explain how FastAPI leverages ASGI coroutines for concurrency.',
        category: 'technical',
        skill: 'FastAPI',
        difficulty: 'medium',
        answerId: 'ans-101',
        answerRevision: 1,
        wordCount: 52,
        evaluation: AnswerEvaluationModel(
          id: 'eval-1',
          sessionId: 'sess-eval-12345',
          answerId: 'ans-101',
          questionId: 'q-101',
          answerRevision: 1,
          status: 'completed',
          rubricVersion: '1.0.0',
          overallScore: 88.5,
          normalizedScore: 3.54,
          strengths: ['Accurate ASGI terminology'],
          improvementAreas: ['Detail thread pool delegation for sync routes'],
          evidenceExcerpts: ['async def runs concurrently on the event loop'],
          feedbackSummary: 'Thorough and well-reasoned explanation.',
          criteriaScores: [
            CriterionScoreModel(
              key: 'technical_knowledge',
              name: 'Technical Knowledge & Correctness',
              score: 4,
              maxScore: 4,
              baseWeight: 0.35,
              normalizedWeight: 0.35,
              explanation: 'Thorough evidence of coroutines and event loop mechanics.',
              evidenceQuote: 'async def runs concurrently on the event loop',
              isApplicable: true,
            ),
            CriterionScoreModel(
              key: 'relevance',
              name: 'Relevance to Question',
              score: 3,
              maxScore: 4,
              baseWeight: 0.25,
              normalizedWeight: 0.25,
              explanation: 'Directly addresses concurrency without drift.',
              evidenceQuote: 'async def runs concurrently on the event loop',
              isApplicable: true,
            ),
          ],
        ),
      ),
    ],
  );

  Widget createTestWidget(EvaluationService service) {
    return ProviderScope(
      overrides: [
        evaluationServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const InterviewEvaluationScreen(sessionId: 'sess-eval-12345'),
      ),
    );
  }

  testWidgets('InterviewEvaluationScreen renders complete evaluation report with scores and rubrics',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final service = MockEvaluationService(mockReport: sampleReport);
    await tester.pumpWidget(createTestWidget(service));
    await tester.pumpAndSettle();

    // Verify Title, Job, and Company
    expect(find.text('Senior Python Developer'), findsOneWidget);
    expect(find.text('FastCloud Ltd'), findsOneWidget);

    // Verify Overall Scores
    expect(find.text('88.5%'), findsOneWidget);
    expect(find.text('Overall Rubric Proficiency Score'), findsOneWidget);
    expect(find.textContaining('3.54 / 4.0'), findsOneWidget);

    // Verify Disclaimer
    expect(find.text('Transparent Scoring & Evaluation Limitations Disclaimer'), findsOneWidget);
    expect(find.textContaining('AI rubric evaluation assesses only candidate'), findsOneWidget);

    // Verify Strengths and Growth Opportunities
    expect(find.text('Demonstrated Strengths'), findsOneWidget);
    expect(find.textContaining('asyncio comprehension'), findsOneWidget);
    expect(find.text('Growth Opportunities'), findsOneWidget);
    expect(find.textContaining('distributed cache invalidation'), findsOneWidget);

    // Verify Question Criteria and Quote
    expect(find.text('Explain how FastAPI leverages ASGI coroutines for concurrency.'), findsOneWidget);
    expect(find.text('Technical Knowledge & Correctness'), findsOneWidget);
    expect(find.textContaining('async def runs concurrently'), findsWidgets);
  });

  testWidgets('InterviewEvaluationScreen displays error state gracefully upon failure',
      (tester) async {
    final failingService = MockEvaluationService(shouldThrow: true);
    await tester.pumpWidget(createTestWidget(failingService));
    await tester.pumpAndSettle();

    expect(find.text('Unable to Load Evaluation Report'), findsOneWidget);
    expect(find.textContaining('Simulated report network failure'), findsOneWidget);
    expect(find.text('Retry Loading'), findsOneWidget);
    expect(find.text('Back to Interviews'), findsOneWidget);
  });
}
