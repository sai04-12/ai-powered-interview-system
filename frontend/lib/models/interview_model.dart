class InterviewQuestionModel {
  final String id;
  final String sessionId;
  final String questionText;
  final String category;
  final String skill;
  final String difficulty;
  final int questionOrder;
  final String questionSource;
  final String? selectionReason;
  final DateTime? createdAt;

  const InterviewQuestionModel({
    required this.id,
    required this.sessionId,
    required this.questionText,
    required this.category,
    required this.skill,
    required this.difficulty,
    required this.questionOrder,
    required this.questionSource,
    this.selectionReason,
    this.createdAt,
  });

  factory InterviewQuestionModel.fromJson(Map<String, dynamic> json) {
    return InterviewQuestionModel(
      id: json['id'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
      questionText: json['question_text'] as String? ?? '',
      category: json['category'] as String? ?? 'technical',
      skill: json['skill'] as String? ?? 'General',
      difficulty: json['difficulty'] as String? ?? 'medium',
      questionOrder: json['question_order'] as int? ?? 0,
      questionSource: json['question_source'] as String? ?? 'predefined',
      selectionReason: json['selection_reason'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'question_text': questionText,
      'category': category,
      'skill': skill,
      'difficulty': difficulty,
      'question_order': questionOrder,
      'question_source': questionSource,
      'selection_reason': selectionReason,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class InterviewAnswerModel {
  final String id;
  final String sessionId;
  final String questionId;
  final String answerText;
  final int wordCount;
  final int charCount;
  final DateTime? submittedAt;
  final int revisionNumber;

  const InterviewAnswerModel({
    required this.id,
    required this.sessionId,
    required this.questionId,
    required this.answerText,
    required this.wordCount,
    required this.charCount,
    this.submittedAt,
    required this.revisionNumber,
  });

  factory InterviewAnswerModel.fromJson(Map<String, dynamic> json) {
    return InterviewAnswerModel(
      id: json['id'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
      questionId: json['question_id'] as String? ?? '',
      answerText: json['answer_text'] as String? ?? '',
      wordCount: json['word_count'] as int? ?? 0,
      charCount: json['char_count'] as int? ?? 0,
      submittedAt: json['submitted_at'] != null ? DateTime.tryParse(json['submitted_at'] as String) : null,
      revisionNumber: json['revision_number'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'question_id': questionId,
      'answer_text': answerText,
      'word_count': wordCount,
      'char_count': charCount,
      'submitted_at': submittedAt?.toIso8601String(),
      'revision_number': revisionNumber,
    };
  }
}

class InterviewSessionModel {
  final String id;
  final String userId;
  final String jobId;
  final String? resumeId;
  final String status;
  final int currentQuestionIndex;
  final int totalQuestionCount;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? jobTitle;
  final String? company;
  final InterviewQuestionModel? currentQuestion;

  const InterviewSessionModel({
    required this.id,
    required this.userId,
    required this.jobId,
    this.resumeId,
    required this.status,
    required this.currentQuestionIndex,
    required this.totalQuestionCount,
    this.startedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
    this.jobTitle,
    this.company,
    this.currentQuestion,
  });

  factory InterviewSessionModel.fromJson(Map<String, dynamic> json) {
    return InterviewSessionModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      resumeId: json['resume_id'] as String?,
      status: json['status'] as String? ?? 'draft',
      currentQuestionIndex: json['current_question_index'] as int? ?? 0,
      totalQuestionCount: json['total_question_count'] as int? ?? 5,
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      jobTitle: json['job_title'] as String?,
      company: json['company'] as String?,
      currentQuestion: json['current_question'] != null
          ? InterviewQuestionModel.fromJson(json['current_question'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'job_id': jobId,
      'resume_id': resumeId,
      'status': status,
      'current_question_index': currentQuestionIndex,
      'total_question_count': totalQuestionCount,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'job_title': jobTitle,
      'company': company,
      'current_question': currentQuestion?.toJson(),
    };
  }

  bool get isDraft => status == 'draft';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isAbandoned => status == 'abandoned';

  double get progressPercent {
    if (totalQuestionCount == 0) return 0.0;
    if (isCompleted) return 1.0;
    return (currentQuestionIndex / totalQuestionCount).clamp(0.0, 1.0);
  }
}

class InterviewSessionSummaryModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String? company;
  final String status;
  final int currentQuestionIndex;
  final int totalQuestionCount;
  final int answeredCount;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;

  const InterviewSessionSummaryModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    this.company,
    required this.status,
    required this.currentQuestionIndex,
    required this.totalQuestionCount,
    required this.answeredCount,
    this.startedAt,
    this.completedAt,
    this.createdAt,
  });

  factory InterviewSessionSummaryModel.fromJson(Map<String, dynamic> json) {
    return InterviewSessionSummaryModel(
      id: json['id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      jobTitle: json['job_title'] as String? ?? 'Untitled Role',
      company: json['company'] as String?,
      status: json['status'] as String? ?? 'draft',
      currentQuestionIndex: json['current_question_index'] as int? ?? 0,
      totalQuestionCount: json['total_question_count'] as int? ?? 5,
      answeredCount: json['answered_count'] as int? ?? 0,
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isDraft => status == 'draft';
}

class InterviewNextResultModel {
  final InterviewSessionModel session;
  final bool isCompleted;
  final InterviewQuestionModel? nextQuestion;
  final String? adaptationNote;

  const InterviewNextResultModel({
    required this.session,
    required this.isCompleted,
    this.nextQuestion,
    this.adaptationNote,
  });

  factory InterviewNextResultModel.fromJson(Map<String, dynamic> json) {
    return InterviewNextResultModel(
      session: InterviewSessionModel.fromJson(json['session'] as Map<String, dynamic>),
      isCompleted: json['is_completed'] as bool? ?? false,
      nextQuestion: json['next_question'] != null
          ? InterviewQuestionModel.fromJson(json['next_question'] as Map<String, dynamic>)
          : null,
      adaptationNote: json['adaptation_note'] as String?,
    );
  }
}
