import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/app_theme.dart';
import 'package:frontend/features/jobs/screens/job_list_screen.dart';
import 'package:frontend/features/resume/screens/resume_list_screen.dart';
import 'package:frontend/features/resume/screens/resume_match_screen.dart';
import 'package:frontend/models/job_model.dart';
import 'package:frontend/models/resume_model.dart';
import 'package:frontend/providers/job_provider.dart';
import 'package:frontend/providers/resume_provider.dart';

void main() {
  group('Resume and Job Screens UI Tests', () {
    testWidgets('ResumeListScreen displays empty state when no resumes uploaded', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resumesListProvider.overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ResumeListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Resumes & Documents'), findsOneWidget);
      expect(find.text('No Resumes Uploaded Yet'), findsOneWidget);
      expect(find.text('Upload Resume'), findsWidgets);
    });

    testWidgets('ResumeListScreen displays resumes list and extraction status', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockResume = ResumeModel(
        id: 'res-101',
        userId: 'usr-1',
        filename: 'senior_developer_resume.pdf',
        fileType: 'pdf',
        fileSize: 204800,
        extractionStatus: 'completed',
        structuredData: {
          'skills': ['Python', 'FastAPI', 'Flutter'],
          'summary': 'Full Stack Developer',
          'total_years_experience': 4.5,
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resumesListProvider.overrideWith((ref) => Future.value([mockResume])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ResumeListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('senior_developer_resume.pdf'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('Python'), findsOneWidget);
      expect(find.text('FastAPI'), findsOneWidget);
    });

    testWidgets('JobListScreen displays jobs list with skills and experience', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockJob = JobModel(
        id: 'job-101',
        recruiterId: 'rec-1',
        title: 'Lead AI Engineer',
        company: 'Neural Innovations',
        description: 'Design and deploy state-of-the-art AI systems.',
        requiredSkills: const ['Python', 'PyTorch'],
        preferredSkills: const ['Docker'],
        minExperienceYears: 5,
        educationRequirements: 'BS in Computer Science or related field',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            jobsListProvider.overrideWith((ref) => Future.value([mockJob])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const JobListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Lead AI Engineer'), findsOneWidget);
      expect(find.text('Neural Innovations'), findsOneWidget);
      expect(find.text('Python'), findsOneWidget);
      expect(find.text('PyTorch'), findsOneWidget);
      expect(find.text('Match My Resume'), findsOneWidget);
    });

    testWidgets('JobListScreen displays empty state when no jobs available', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            jobsListProvider.overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const JobListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Job Openings & Positions'), findsOneWidget);
      expect(find.text('No Job Postings Available'), findsOneWidget);
    });

    testWidgets('ResumeMatchScreen renders selector header and instructions', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resumesListProvider.overrideWith((ref) => Future.value([])),
            jobsListProvider.overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ResumeMatchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Intelligent Job Matching'), findsOneWidget);
      expect(find.text('Run Match Analysis'), findsOneWidget);
    });
  });
}
