/// Models for Answer Rubric Evaluation and Session Evaluation Reports.
library;

class CriterionScoreModel {
  final String key;
  final String name;
  final int score;
  final int maxScore;
  final double baseWeight;
  final double normalizedWeight;
  final String explanation;
  final String? evidenceQuote;
  final bool isApplicable;

  const CriterionScoreModel({
    required this.key,
    required this.name,
    required this.score,
    this.maxScore = 4,
    required this.baseWeight,
    required this.normalizedWeight,
    required this.explanation,
    this.evidenceQuote,
    this.isApplicable = true,
  });

  factory CriterionScoreModel.fromJson(Map<String, dynamic> json) {
    return CriterionScoreModel(
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      maxScore: (json['max_score'] as num?)?.toInt() ?? 4,
      baseWeight: (json['base_weight'] as num?)?.toDouble() ?? 0.0,
      normalizedWeight: (json['normalized_weight'] as num?)?.toDouble() ?? 0.0,
      explanation: json['explanation'] as String? ?? '',
      evidenceQuote: json['evidence_quote'] as String?,
      isApplicable: json['is_applicable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'name': name,
      'score': score,
      'max_score': maxScore,
      'base_weight': baseWeight,
      'normalized_weight': normalizedWeight,
      'explanation': explanation,
      'evidence_quote': evidenceQuote,
      'is_applicable': isApplicable,
    };
  }

  double get scorePercentage => maxScore > 0 ? (score / maxScore) * 100 : 0.0;
}

class AnswerEvaluationModel {
  final String id;
  final String sessionId;
  final String answerId;
  final String questionId;
  final int answerRevision;
  final String status;
  final String rubricVersion;
  final double? overallScore;
  final double? normalizedScore;
  final List<CriterionScoreModel> criteriaScores;
  final List<String> evidenceExcerpts;
  final List<String> strengths;
  final List<String> improvementAreas;
  final String evaluatorType;
  final String? evaluationLimitations;
  final String? feedbackSummary;
  final DateTime? createdAt;

  const AnswerEvaluationModel({
    required this.id,
    required this.sessionId,
    required this.answerId,
    required this.questionId,
    required this.answerRevision,
    required this.status,
    required this.rubricVersion,
    this.overallScore,
    this.normalizedScore,
    this.criteriaScores = const [],
    this.evidenceExcerpts = const [],
    this.strengths = const [],
    this.improvementAreas = const [],
    this.evaluatorType = 'deterministic',
    this.evaluationLimitations,
    this.feedbackSummary,
    this.createdAt,
  });

  factory AnswerEvaluationModel.fromJson(Map<String, dynamic> json) {
    final rawCriteria = json['criteria_scores'] as List<dynamic>? ?? [];
    final criteria = rawCriteria
        .map((c) => CriterionScoreModel.fromJson(c as Map<String, dynamic>))
        .toList();

    final rawExcerpts = json['evidence_excerpts'] as List<dynamic>? ?? [];
    final excerpts = rawExcerpts.map((e) => e.toString()).toList();

    final rawStrengths = json['strengths'] as List<dynamic>? ?? [];
    final strList = rawStrengths.map((s) => s.toString()).toList();

    final rawImpr = json['improvement_areas'] as List<dynamic>? ?? [];
    final imprList = rawImpr.map((i) => i.toString()).toList();

    return AnswerEvaluationModel(
      id: json['id'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
      answerId: json['answer_id'] as String? ?? '',
      questionId: json['question_id'] as String? ?? '',
      answerRevision: json['answer_revision'] as int? ?? 1,
      status: json['status'] as String? ?? 'pending',
      rubricVersion: json['rubric_version'] as String? ?? '1.0.0',
      overallScore: (json['overall_score'] as num?)?.toDouble(),
      normalizedScore: (json['normalized_score'] as num?)?.toDouble(),
      criteriaScores: criteria,
      evidenceExcerpts: excerpts,
      strengths: strList,
      improvementAreas: imprList,
      evaluatorType: json['evaluator_type'] as String? ?? 'deterministic',
      evaluationLimitations: json['evaluation_limitations'] as String?,
      feedbackSummary: json['feedback_summary'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'answer_id': answerId,
      'question_id': questionId,
      'answer_revision': answerRevision,
      'status': status,
      'rubric_version': rubricVersion,
      'overall_score': overallScore,
      'normalized_score': normalizedScore,
      'criteria_scores': criteriaScores.map((c) => c.toJson()).toList(),
      'evidence_excerpts': evidenceExcerpts,
      'strengths': strengths,
      'improvement_areas': improvementAreas,
      'evaluator_type': evaluatorType,
      'evaluation_limitations': evaluationLimitations,
      'feedback_summary': feedbackSummary,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get requiresReview => status == 'requires_review';
  bool get isPending => status == 'pending';

  String get formattedOverallScore =>
      overallScore != null ? '${overallScore!.toStringAsFixed(1)}%' : 'N/A';

  String get formattedRubricScore =>
      normalizedScore != null ? '${normalizedScore!.toStringAsFixed(2)} / 4.0' : 'N/A';
}

class SessionQuestionEvaluationModel {
  final String questionId;
  final int questionOrder;
  final String questionText;
  final String category;
  final String skill;
  final String difficulty;
  final String? answerId;
  final int? answerRevision;
  final int? wordCount;
  final AnswerEvaluationModel? evaluation;

  const SessionQuestionEvaluationModel({
    required this.questionId,
    required this.questionOrder,
    required this.questionText,
    required this.category,
    required this.skill,
    required this.difficulty,
    this.answerId,
    this.answerRevision,
    this.wordCount,
    this.evaluation,
  });

  factory SessionQuestionEvaluationModel.fromJson(Map<String, dynamic> json) {
    return SessionQuestionEvaluationModel(
      questionId: json['question_id'] as String? ?? '',
      questionOrder: json['question_order'] as int? ?? 0,
      questionText: json['question_text'] as String? ?? '',
      category: json['category'] as String? ?? 'technical',
      skill: json['skill'] as String? ?? 'General',
      difficulty: json['difficulty'] as String? ?? 'medium',
      answerId: json['answer_id'] as String?,
      answerRevision: json['answer_revision'] as int?,
      wordCount: json['word_count'] as int?,
      evaluation: json['evaluation'] != null
          ? AnswerEvaluationModel.fromJson(json['evaluation'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'question_order': questionOrder,
      'question_text': questionText,
      'category': category,
      'skill': skill,
      'difficulty': difficulty,
      'answer_id': answerId,
      'answer_revision': answerRevision,
      'word_count': wordCount,
      'evaluation': evaluation?.toJson(),
    };
  }
}

class SessionEvaluationReportModel {
  final String sessionId;
  final String candidateId;
  final String jobId;
  final String? jobTitle;
  final String? company;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int totalQuestions;
  final int answeredQuestions;
  final int evaluatedQuestions;
  final double? averageOverallScore;
  final double? averageRubricScore;
  final List<SessionQuestionEvaluationModel> questionEvaluations;
  final List<String> aggregatedStrengths;
  final List<String> aggregatedImprovements;
  final String evaluationLimitations;
  final String evaluatorType;
  final bool isComplete;

  const SessionEvaluationReportModel({
    required this.sessionId,
    required this.candidateId,
    required this.jobId,
    this.jobTitle,
    this.company,
    required this.status,
    this.startedAt,
    this.completedAt,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.evaluatedQuestions,
    this.averageOverallScore,
    this.averageRubricScore,
    this.questionEvaluations = const [],
    this.aggregatedStrengths = const [],
    this.aggregatedImprovements = const [],
    required this.evaluationLimitations,
    this.evaluatorType = 'deterministic',
    this.isComplete = false,
  });

  factory SessionEvaluationReportModel.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['question_evaluations'] as List<dynamic>? ?? [];
    final questions = rawQuestions
        .map((q) => SessionQuestionEvaluationModel.fromJson(q as Map<String, dynamic>))
        .toList();

    final rawStrengths = json['aggregated_strengths'] as List<dynamic>? ?? [];
    final strengths = rawStrengths.map((s) => s.toString()).toList();

    final rawImpr = json['aggregated_improvements'] as List<dynamic>? ?? [];
    final improvements = rawImpr.map((i) => i.toString()).toList();

    return SessionEvaluationReportModel(
      sessionId: json['session_id'] as String? ?? '',
      candidateId: json['candidate_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      jobTitle: json['job_title'] as String?,
      company: json['company'] as String?,
      status: json['status'] as String? ?? 'draft',
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'] as String) : null,
      totalQuestions: json['total_questions'] as int? ?? 0,
      answeredQuestions: json['answered_questions'] as int? ?? 0,
      evaluatedQuestions: json['evaluated_questions'] as int? ?? 0,
      averageOverallScore: (json['average_overall_score'] as num?)?.toDouble(),
      averageRubricScore: (json['average_rubric_score'] as num?)?.toDouble(),
      questionEvaluations: questions,
      aggregatedStrengths: strengths,
      aggregatedImprovements: improvements,
      evaluationLimitations: json['evaluation_limitations'] as String? ?? '',
      evaluatorType: json['evaluator_type'] as String? ?? 'deterministic',
      isComplete: json['is_complete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'candidate_id': candidateId,
      'job_id': jobId,
      'job_title': jobTitle,
      'company': company,
      'status': status,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'total_questions': totalQuestions,
      'answered_questions': answeredQuestions,
      'evaluated_questions': evaluatedQuestions,
      'average_overall_score': averageOverallScore,
      'average_rubric_score': averageRubricScore,
      'question_evaluations': questionEvaluations.map((q) => q.toJson()).toList(),
      'aggregated_strengths': aggregatedStrengths,
      'aggregated_improvements': aggregatedImprovements,
      'evaluation_limitations': evaluationLimitations,
      'evaluator_type': evaluatorType,
      'is_complete': isComplete,
    };
  }

  bool get hasScores => averageOverallScore != null;

  String get formattedOverallScore =>
      averageOverallScore != null ? '${averageOverallScore!.toStringAsFixed(1)}%' : 'Pending';

  String get formattedRubricScore =>
      averageRubricScore != null ? '${averageRubricScore!.toStringAsFixed(2)} / 4.0' : 'Pending';
}
