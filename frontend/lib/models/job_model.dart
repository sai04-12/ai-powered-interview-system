class JobModel {
  final String id;
  final String recruiterId;
  final String title;
  final String? company;
  final String description;
  final List<String> requiredSkills;
  final List<String> preferredSkills;
  final int? minExperienceYears;
  final String? educationRequirements;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const JobModel({
    required this.id,
    required this.recruiterId,
    required this.title,
    this.company,
    required this.description,
    this.requiredSkills = const [],
    this.preferredSkills = const [],
    this.minExperienceYears,
    this.educationRequirements,
    this.createdAt,
    this.updatedAt,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as String? ?? '',
      recruiterId: json['recruiter_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      company: json['company'] as String?,
      description: json['description'] as String? ?? '',
      requiredSkills: (json['required_skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      preferredSkills: (json['preferred_skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      minExperienceYears: json['min_experience_years'] as int?,
      educationRequirements: json['education_requirements'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recruiter_id': recruiterId,
      'title': title,
      'company': company,
      'description': description,
      'required_skills': requiredSkills,
      'preferred_skills': preferredSkills,
      'min_experience_years': minExperienceYears,
      'education_requirements': educationRequirements,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
