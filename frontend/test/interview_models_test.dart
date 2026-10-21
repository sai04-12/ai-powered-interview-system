import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/interview_model.dart';

void main() {
  group('Interview Models Tests', () {
    test('InterviewQuestionModel fromJson and toJson serialization', () {
      final json = {
        'id': 'q-101',
        'session_id': 'sess-1',
        'question_text': 'Explain event loop and async/await in Python.',
        'category': 'technical',
        'skill': 'Python',
        'difficulty': 'medium',
        'question_order': 0,
        'question_source': 'predefined',
        'selection_reason': 'Core skill assessed for backend engineering',
        'created_at': '2026-10-19T10:00:00Z',
      };

      final question = InterviewQuestionModel.fromJson(json);

      expect(question.id, 'q-101');
      expect(question.sessionId, 'sess-1');
      expect(question.questionText, 'Explain event loop and async/await in Python.');
      expect(question.category, 'technical');
      expect(question.skill, 'Python');
      expect(question.difficulty, 'medium');
      expect(question.questionOrder, 0);
      expect(question.questionSource, 'predefined');
      expect(question.selectionReason, 'Core skill assessed for backend engineering');

      final serialized = question.toJson();
      expect(serialized['id'], 'q-101');
      expect(serialized['category'], 'technical');
      expect(serialized['difficulty'], 'medium');
    });

    test('InterviewAnswerModel fromJson and toJson serialization', () {
      final json = {
        'id': 'ans-201',
        'session_id': 'sess-1',
        'question_id': 'q-101',
        'answer_text': 'Asyncio uses an event loop to schedule and execute asynchronous tasks cooperatively.',
        'word_count': 12,
        'char_count': 82,
        'submitted_at': '2026-10-19T10:05:00Z',
        'revision_number': 1,
      };

      final answer = InterviewAnswerModel.fromJson(json);

      expect(answer.id, 'ans-201');
      expect(answer.sessionId, 'sess-1');
      expect(answer.questionId, 'q-101');
      expect(answer.wordCount, 12);
      expect(answer.charCount, 82);
      expect(answer.revisionNumber, 1);

      final serialized = answer.toJson();
      expect(serialized['id'], 'ans-201');
      expect(serialized['word_count'], 12);
      expect(serialized['revision_number'], 1);
    });

    test('InterviewSessionModel status flags and progressPercent calculation', () {
      final draftSession = InterviewSessionModel(
        id: 'sess-draft',
        userId: 'usr-1',
        jobId: 'job-1',
        status: 'draft',
        currentQuestionIndex: 0,
        totalQuestionCount: 5,
      );
      expect(draftSession.isDraft, isTrue);
      expect(draftSession.isInProgress, isFalse);
      expect(draftSession.isCompleted, isFalse);
      expect(draftSession.isAbandoned, isFalse);
      expect(draftSession.progressPercent, 0.0);

      final activeSession = InterviewSessionModel(
        id: 'sess-active',
        userId: 'usr-1',
        jobId: 'job-1',
        status: 'in_progress',
        currentQuestionIndex: 2,
        totalQuestionCount: 5,
      );
      expect(activeSession.isDraft, isFalse);
      expect(activeSession.isInProgress, isTrue);
      expect(activeSession.progressPercent, 0.4);

      final completedSession = InterviewSessionModel(
        id: 'sess-completed',
        userId: 'usr-1',
        jobId: 'job-1',
        status: 'completed',
        currentQuestionIndex: 5,
        totalQuestionCount: 5,
      );
      expect(completedSession.isCompleted, isTrue);
      expect(completedSession.progressPercent, 1.0);
    });

    test('InterviewSessionSummaryModel parses summary fields correctly', () {
      final json = {
        'id': 'sess-sum-1',
        'job_id': 'job-88',
        'job_title': 'Senior Flutter Engineer',
        'company': 'Tech Corp',
        'status': 'in_progress',
        'current_question_index': 3,
        'total_question_count': 5,
        'answered_count': 3,
        'started_at': '2026-10-19T09:00:00Z',
        'created_at': '2026-10-19T08:55:00Z',
      };

      final summary = InterviewSessionSummaryModel.fromJson(json);

      expect(summary.id, 'sess-sum-1');
      expect(summary.jobId, 'job-88');
      expect(summary.jobTitle, 'Senior Flutter Engineer');
      expect(summary.company, 'Tech Corp');
      expect(summary.isInProgress, isTrue);
      expect(summary.isCompleted, isFalse);
      expect(summary.answeredCount, 3);
      expect(summary.totalQuestionCount, 5);
    });

    test('InterviewNextResultModel parses transition outcome with adaptation note', () {
      final json = {
        'session': {
          'id': 'sess-trans',
          'user_id': 'usr-1',
          'job_id': 'job-1',
          'status': 'in_progress',
          'current_question_index': 1,
          'total_question_count': 3,
        },
        'is_completed': false,
        'next_question': {
          'id': 'q-next',
          'session_id': 'sess-trans',
          'question_text': 'Explain Docker multi-stage builds.',
          'category': 'technical',
          'skill': 'Docker',
          'difficulty': 'hard',
          'question_order': 1,
          'question_source': 'adaptive follow-up',
          'selection_reason': 'Candidate provided detailed technical response; escalating difficulty to hard.',
        },
        'adaptation_note': 'Calibrated next question difficulty to hard based on substantive technical depth.',
      };

      final result = InterviewNextResultModel.fromJson(json);

      expect(result.isCompleted, isFalse);
      expect(result.session.currentQuestionIndex, 1);
      expect(result.nextQuestion?.difficulty, 'hard');
      expect(result.adaptationNote, contains('Calibrated next question difficulty to hard'));
    });
  });
}
