class ResumeModel {
  final String id;
  final String userId;
  final String filename;
  final String fileType;
  final int fileSize;
  final String extractionStatus;
  final String? rawText;
  final Map<String, dynamic>? structuredData;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ResumeModel({
    required this.id,
    required this.userId,
    required this.filename,
    required this.fileType,
    required this.fileSize,
    required this.extractionStatus,
    this.rawText,
    this.structuredData,
    this.createdAt,
    this.updatedAt,
  });

  factory ResumeModel.fromJson(Map<String, dynamic> json) {
    return ResumeModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      fileType: json['file_type'] as String? ?? '',
      fileSize: json['file_size'] as int? ?? 0,
      extractionStatus: json['extraction_status'] as String? ?? 'pending',
      rawText: json['raw_text'] as String?,
      structuredData: json['structured_data'] as Map<String, dynamic>?,
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
      'user_id': userId,
      'filename': filename,
      'file_type': fileType,
      'file_size': fileSize,
      'extraction_status': extractionStatus,
      'raw_text': rawText,
      'structured_data': structuredData,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isCompleted => extractionStatus == 'completed';
  bool get isPending => extractionStatus == 'pending';
  bool get isProcessing => extractionStatus == 'processing';
  bool get isFailed => extractionStatus == 'failed';

  List<String> get skills {
    final list = structuredData?['skills'];
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return [];
  }

  String? get summary => structuredData?['professional_summary'] as String? ?? structuredData?['summary'] as String?;

  double? get totalExperienceYears {
    final exp = structuredData?['total_experience_years'] ?? structuredData?['total_years_experience'];
    if (exp is num) {
      return exp.toDouble();
    }
    return null;
  }
}
