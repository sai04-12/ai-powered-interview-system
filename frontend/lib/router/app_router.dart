import 'package:go_router/go_router.dart';
import '../features/authentication/screens/login_screen.dart';
import '../features/authentication/screens/register_screen.dart';
import '../features/authentication/screens/smart_login_screen.dart';
import '../features/candidate/screens/candidate_dashboard_screen.dart';
import '../features/evaluation/screens/interview_evaluation_screen.dart';
import '../features/interviews/screens/interview_completion_screen.dart';
import '../features/interviews/screens/interview_list_screen.dart';
import '../features/interviews/screens/interview_session_screen.dart';
import '../features/interviews/screens/interview_setup_screen.dart';
import '../features/interviews/screens/live_coding_screen.dart';
import '../features/interviews/screens/live_interview_screen.dart';
import '../features/jobs/screens/create_job_posting_screen.dart';
import '../features/jobs/screens/job_list_screen.dart';
import '../features/landing/screens/landing_page_screen.dart';
import '../features/recruiter/screens/recruiter_analytics_screen.dart';
import '../features/recruiter/screens/recruiter_candidates_screen.dart';
import '../features/reports/screens/interview_evaluation_report_screen.dart';
import '../features/resume/screens/job_role_matching_screen.dart';
import '../features/resume/screens/resume_list_screen.dart';
import '../features/resume/screens/resume_match_screen.dart';
import '../features/resume/screens/resume_upload_analysis_screen.dart';
import '../features/resume/screens/resume_upload_screen.dart';
import '../features/settings/screens/admin_settings_screen.dart';
import '../features/verification/screens/profile_verification_screen.dart';
import '../features/workflow/screens/system_workflow_screen.dart';
import '../shared/screens/foundation_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // 1. Landing Page
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const LandingPageScreen(),
      ),
      GoRoute(
        path: '/landing',
        name: 'landing',
        builder: (context, state) => const LandingPageScreen(),
      ),

      // 2. Login / Sign Up
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const SmartLoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const SmartLoginScreen(),
      ),

      // 3. Candidate Dashboard
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const CandidateDashboardScreen(),
      ),

      // 4. Recruiter Dashboard
      GoRoute(
        path: '/recruiter/dashboard',
        name: 'recruiter_dashboard',
        builder: (context, state) => const RecruiterAnalyticsScreen(),
      ),

      // 5. Profile Verification
      GoRoute(
        path: '/verification',
        name: 'verification',
        builder: (context, state) => const ProfileVerificationScreen(),
      ),

      // 6. Resume Upload & Analysis
      GoRoute(
        path: '/resume-analysis',
        name: 'resume_analysis',
        builder: (context, state) => const ResumeUploadAnalysisScreen(),
      ),

      // 7. Interview Session (Video + Questions)
      GoRoute(
        path: '/live-interview',
        name: 'live_interview',
        builder: (context, state) => const LiveInterviewScreen(),
      ),

      // 8. Live Coding / Response Input
      GoRoute(
        path: '/live-coding',
        name: 'live_coding',
        builder: (context, state) => const LiveCodingScreen(),
      ),

      // 9. Interview Result / Report
      GoRoute(
        path: '/evaluation-report',
        name: 'evaluation_report',
        builder: (context, state) => const InterviewEvaluationReportScreen(),
      ),

      // 10. Candidates List (Recruiter)
      GoRoute(
        path: '/recruiter/candidates',
        name: 'recruiter_candidates',
        builder: (context, state) => const RecruiterCandidatesScreen(),
      ),

      // 11. Job Posting Management
      GoRoute(
        path: '/jobs/create',
        name: 'create_job_posting',
        builder: (context, state) => const CreateJobPostingScreen(),
      ),

      // 12. Settings / Admin
      GoRoute(
        path: '/settings',
        name: 'admin_settings',
        builder: (context, state) => const AdminSettingsScreen(),
      ),

      // Semantic Matching (Page 3)
      GoRoute(
        path: '/profile-matching',
        name: 'profile_matching',
        builder: (context, state) => const JobRoleMatchingScreen(),
      ),

      // System Workflow (Page 5)
      GoRoute(
        path: '/workflow',
        name: 'system_workflow',
        builder: (context, state) => const SystemWorkflowScreen(),
      ),

      // Dev & Legacy routes
      GoRoute(
        path: '/foundation',
        name: 'foundation',
        builder: (context, state) => const FoundationScreen(),
      ),
      GoRoute(
        path: '/legacy-login',
        name: 'legacy_login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/legacy-register',
        name: 'legacy_register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/resumes',
        name: 'resumes',
        builder: (context, state) => const ResumeListScreen(),
      ),
      GoRoute(
        path: '/resumes/upload',
        name: 'resume_upload',
        builder: (context, state) => const ResumeUploadScreen(),
      ),
      GoRoute(
        path: '/jobs',
        name: 'jobs',
        builder: (context, state) => const JobListScreen(),
      ),
      GoRoute(
        path: '/match',
        name: 'match',
        builder: (context, state) => ResumeMatchScreen(
          initialResumeId: state.uri.queryParameters['resumeId'],
          initialJobId: state.uri.queryParameters['jobId'],
        ),
      ),
      GoRoute(
        path: '/interviews',
        name: 'interviews',
        builder: (context, state) => const InterviewListScreen(),
      ),
      GoRoute(
        path: '/interviews/setup',
        name: 'interview_setup',
        builder: (context, state) => InterviewSetupScreen(
          initialJobId: state.uri.queryParameters['jobId'],
          initialResumeId: state.uri.queryParameters['resumeId'],
        ),
      ),
      GoRoute(
        path: '/interviews/:sessionId',
        name: 'interview_session',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId'] ?? '';
          return InterviewSessionScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/interviews/:sessionId/completed',
        name: 'interview_completion',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId'] ?? '';
          return InterviewCompletionScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/interviews/:sessionId/evaluation',
        name: 'interview_evaluation',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId'] ?? '';
          return InterviewEvaluationScreen(sessionId: sessionId);
        },
      ),
    ],
  );
}
