import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/job_model.dart';
import 'package:frontend/models/match_model.dart';
import 'package:frontend/models/resume_model.dart';

void main() {
  group('ResumeModel Tests', () {
    test('ResumeModel.fromJson parses complete resume metadata and structured data', () {
      final json = {
        'id': 'resume-uuid-1',
        'user_id': 'user-uuid-1',
        'filename': 'johndoe_resume.pdf',
        'file_type': 'pdf',
        'file_size': 123456,
        'extraction_status': 'completed',
        'raw_text': 'Senior Python and Flutter developer with 5 years experience',
        'structured_data': {
          'skills': ['Python', 'Flutter', 'PostgreSQL'],
          'summary': 'Senior Engineer',
          'total_years_experience': 5.0,
        },
        'created_at': '2026-10-18T10:00:00Z',
        'updated_at': '2026-10-18T10:05:00Z',
      };

      final resume = ResumeModel.fromJson(json);

      expect(resume.id, 'resume-uuid-1');
      expect(resume.userId, 'user-uuid-1');
      expect(resume.filename, 'johndoe_resume.pdf');
      expect(resume.fileType, 'pdf');
      expect(resume.fileSize, 123456);
      expect(resume.isCompleted, isTrue);
      expect(resume.isProcessing, isFalse);
      expect(resume.isFailed, isFalse);
      expect(resume.skills, contains('Python'));
      expect(resume.skills, contains('Flutter'));
      expect(resume.skills, contains('PostgreSQL'));
      expect(resume.summary, 'Senior Engineer');
      expect(resume.totalExperienceYears, 5.0);
    });

    test('ResumeModel.toJson serializes accurately', () {
      final resume = ResumeModel(
        id: 'res-10',
        userId: 'usr-10',
        filename: 'resume.docx',
        fileType: 'docx',
        fileSize: 50000,
        extractionStatus: 'pending',
      );

      final json = resume.toJson();

      expect(json['id'], 'res-10');
      expect(json['filename'], 'resume.docx');
      expect(json['file_type'], 'docx');
      expect(json['extraction_status'], 'pending');
      expect(resume.isProcessing, isFalse);
      expect(resume.isCompleted, isFalse);
    });
  });

  group('JobModel Tests', () {
    test('JobModel.fromJson parses job posting correctly', () {
      final json = {
        'id': 'job-uuid-1',
        'recruiter_id': 'recruiter-uuid-1',
        'title': 'Senior Backend Engineer',
        'company': 'Tech Corp',
        'description': 'Building scalable microservices',
        'required_skills': ['Python', 'FastAPI', 'PostgreSQL'],
        'preferred_skills': ['Docker', 'Kubernetes'],
        'min_experience_years': 4,
        'education_requirements': 'Bachelor in Computer Science',
        'created_at': '2026-10-18T09:00:00Z',
      };

      final job = JobModel.fromJson(json);

      expect(job.id, 'job-uuid-1');
      expect(job.title, 'Senior Backend Engineer');
      expect(job.company, 'Tech Corp');
      expect(job.requiredSkills, hasLength(3));
      expect(job.preferredSkills, hasLength(2));
      expect(job.minExperienceYears, 4);
      expect(job.educationRequirements, 'Bachelor in Computer Science');
    });

    test('JobModel.toJson serializes job correctly', () {
      final job = JobModel(
        id: 'job-2',
        recruiterId: 'rec-2',
        title: 'Flutter Developer',
        company: 'Mobile Solutions',
        description: 'Cross-platform app development',
        requiredSkills: const ['Flutter', 'Dart'],
        preferredSkills: const ['Riverpod'],
        minExperienceYears: 2,
      );

      final json = job.toJson();

      expect(json['title'], 'Flutter Developer');
      expect(json['company'], 'Mobile Solutions');
      expect(json['required_skills'], ['Flutter', 'Dart']);
      expect(json['preferred_skills'], ['Riverpod']);
    });
  });

  group('MatchModel Tests', () {
    test('MatchModel.fromJson parses match score and skills breakdown', () {
      final json = {
        'id': 'match-uuid-1',
        'resume_id': 'res-1',
        'job_id': 'job-1',
        'job_title': 'Senior Backend Engineer',
        'candidate_id': 'cand-1',
        'overall_score': 85.5,
        'skill_score': 90.0,
        'experience_score': 80.0,
        'education_score': 85.0,
        'matched_skills': [
          {'skill': 'Python', 'is_required': true, 'evidence': 'Found in skills section'},
          {'skill': 'Docker', 'is_required': false, 'evidence': null},
        ],
        'missing_skills': ['Kubernetes'],
        'explanation': 'Candidate satisfies Python and Docker requirements.',
        'limitations': 'Deterministic keyword analysis.',
        'created_at': '2026-10-18T10:30:00Z',
      };

      final match = MatchModel.fromJson(json);

      expect(match.id, 'match-uuid-1');
      expect(match.overallScore, 85.5);
      expect(match.skillScore, 90.0);
      expect(match.matchedSkills, hasLength(2));
      expect(match.matchedSkills[0].skill, 'Python');
      expect(match.matchedSkills[0].isRequired, isTrue);
      expect(match.matchedSkills[1].skill, 'Docker');
      expect(match.matchedSkills[1].isRequired, isFalse);
      expect(match.missingSkills, ['Kubernetes']);
      expect(match.explanation, contains('Python'));
      expect(match.limitations, contains('Deterministic'));
    });
  });
}
