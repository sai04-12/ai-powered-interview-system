import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/evaluation_model.dart';

void main() {
  group('Evaluation Models Serialization & Methods', () {
    test('CriterionScoreModel parses JSON and computes score percentage accurately', () {
      final json = {
        'key': 'technical_knowledge',
        'name': 'Technical Knowledge & Correctness',
        'score': 3,
        'max_score': 4,
        'base_weight': 0.35,
        'normalized_weight': 0.35,
        'explanation': 'Strong evidence of Python concurrency principles.',
        'evidence_quote': 'async def enables coroutines to run concurrently',
        'is_applicable': true,
      };

      final model = CriterionScoreModel.fromJson(json);

      expect(model.key, 'technical_knowledge');
      expect(model.score, 3);
      expect(model.maxScore, 4);
      expect(model.scorePercentage, 75.0);
      expect(model.isApplicable, isTrue);
      expect(model.evidenceQuote, contains('async def'));

      final outJson = model.toJson();
      expect(outJson['score'], 3);
      expect(outJson['name'], 'Technical Knowledge & Correctness');
    });

    test('AnswerEvaluationModel parses JSON and status helpers properly', () {
      final json = {
        'id': 'eval-123',
        'session_id': 'sess-456',
        'answer_id': 'ans-789',
        'question_id': 'q-101',
        'answer_revision': 1,
        'status': 'completed',
        'rubric_version': '1.0.0',
        'overall_score': 82.5,
        'normalized_score': 3.3,
        'criteria_scores': [
          {
            'key': 'relevance',
            'name': 'Relevance to Question',
            'score': 4,
            'max_score': 4,
            'base_weight': 0.25,
            'normalized_weight': 0.25,
            'explanation': 'Thorough evidence addressing the prompt.',
            'evidence_quote': 'We utilized async connection pools.',
            'is_applicable': true,
          }
        ],
        'evidence_excerpts': ['We utilized async connection pools.'],
        'strengths': ['Direct topical focus and accurate technical terms.'],
        'improvement_areas': ['Provide deeper trade-off analysis.'],
        'evaluator_type': 'deterministic',
        'evaluation_limitations': 'AI rubric evaluation is an automated assessment.',
        'feedback_summary': 'Strong technical response with clear terminology.',
        'created_at': '2026-10-22T10:00:00.000Z',
      };

      final model = AnswerEvaluationModel.fromJson(json);

      expect(model.id, 'eval-123');
      expect(model.isCompleted, isTrue);
      expect(model.isFailed, isFalse);
      expect(model.requiresReview, isFalse);
      expect(model.formattedOverallScore, '82.5%');
      expect(model.formattedRubricScore, '3.30 / 4.0');
      expect(model.criteriaScores.length, 1);
      expect(model.strengths.first, contains('Direct topical focus'));
    });

    test('SessionEvaluationReportModel parses complete session report and handles pending scores', () {
      final json = {
        'session_id': 'sess-999',
        'candidate_id': 'cand-001',
        'job_id': 'job-002',
        'job_title': 'Senior Flutter Engineer',
        'company': 'AppWorks Corp',
        'status': 'completed',
        'total_questions': 2,
        'answered_questions': 2,
        'evaluated_questions': 2,
        'average_overall_score': 85.0,
        'average_rubric_score': 3.4,
        'question_evaluations': [
          {
            'question_id': 'q1',
            'question_order': 0,
            'question_text': 'Explain Riverpod state lifecycle.',
            'category': 'technical',
            'skill': 'Flutter',
            'difficulty': 'medium',
            'answer_id': 'a1',
            'answer_revision': 1,
            'word_count': 45,
            'evaluation': null,
          }
        ],
        'aggregated_strengths': ['Excellent widget architecture comprehension.'],
        'aggregated_improvements': ['Detail memory management during streams.'],
        'evaluation_limitations': 'AI scoring evaluates strictly candidate text evidence.',
        'evaluator_type': 'deterministic',
        'is_complete': true,
      };

      final report = SessionEvaluationReportModel.fromJson(json);

      expect(report.sessionId, 'sess-999');
      expect(report.jobTitle, 'Senior Flutter Engineer');
      expect(report.hasScores, isTrue);
      expect(report.formattedOverallScore, '85.0%');
      expect(report.formattedRubricScore, '3.40 / 4.0');
      expect(report.isComplete, isTrue);
      expect(report.questionEvaluations.length, 1);
      expect(report.aggregatedStrengths.first, contains('widget architecture'));
    });
  });
}
