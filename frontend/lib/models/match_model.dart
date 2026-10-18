class MatchedSkill {
  final String skill;
  final bool isRequired;
  final String? evidence;

  const MatchedSkill({
    required this.skill,
    this.isRequired = true,
    this.evidence,
  });

  factory MatchedSkill.fromJson(Map<String, dynamic> json) {
    return MatchedSkill(
      skill: json['skill'] as String? ?? '',
      isRequired: json['is_required'] as bool? ?? true,
      evidence: json['evidence'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skill': skill,
      'is_required': isRequired,
      'evidence': evidence,
    };
  }
}

class MatchModel {
  final String id;
  final String resumeId;
  final String jobId;
  final String jobTitle;
  final String candidateId;
  final double overallScore;
  final double skillScore;
  final double experienceScore;
  final double? educationScore;
  final List<MatchedSkill> matchedSkills;
  final List<String> missingSkills;
  final String explanation;
  final String limitations;
  final DateTime? createdAt;

  const MatchModel({
    required this.id,
    required this.resumeId,
    required this.jobId,
    required this.jobTitle,
    required this.candidateId,
    required this.overallScore,
    required this.skillScore,
    required this.experienceScore,
    this.educationScore,
    this.matchedSkills = const [],
    this.missingSkills = const [],
    required this.explanation,
    required this.limitations,
    this.createdAt,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String? ?? '',
      resumeId: json['resume_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      jobTitle: json['job_title'] as String? ?? '',
      candidateId: json['candidate_id'] as String? ?? '',
      overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0.0,
      skillScore: (json['skill_score'] as num?)?.toDouble() ?? 0.0,
      experienceScore: (json['experience_score'] as num?)?.toDouble() ?? 0.0,
      educationScore: (json['education_score'] as num?)?.toDouble(),
      matchedSkills: (json['matched_skills'] as List<dynamic>?)
              ?.map((e) => MatchedSkill.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      missingSkills: (json['missing_skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      explanation: json['explanation'] as String? ?? '',
      limitations: json['limitations'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resume_id': resumeId,
      'job_id': jobId,
      'job_title': jobTitle,
      'candidate_id': candidateId,
      'overall_score': overallScore,
      'skill_score': skillScore,
      'experience_score': experienceScore,
      'education_score': educationScore,
      'matched_skills': matchedSkills.map((e) => e.toJson()).toList(),
      'missing_skills': missingSkills,
      'explanation': explanation,
      'limitations': limitations,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
