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
import '../features/interviews/screens/live_interview_screen.dart';
import '../features/jobs/screens/job_list_screen.dart';
import '../features/recruiter/screens/recruiter_analytics_screen.dart';
import '../features/recruiter/screens/recruiter_candidates_screen.dart';
import '../features/reports/screens/interview_evaluation_report_screen.dart';
import '../features/resume/screens/job_role_matching_screen.dart';
import '../features/resume/screens/resume_list_screen.dart';
import '../features/resume/screens/resume_match_screen.dart';
import '../features/resume/screens/resume_upload_screen.dart';
import '../features/workflow/screens/system_workflow_screen.dart';
import '../shared/screens/foundation_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Primary Route: Candidate Dashboard (Page 2 Screen 2)
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const CandidateDashboardScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const CandidateDashboardScreen(),
      ),

      // Page 2 Screen 1: Smart Login & Sign Up
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

      // Page 3: Job Role Matching (Semantic Matching)
      GoRoute(
        path: '/profile-matching',
        name: 'profile_matching',
        builder: (context, state) => const JobRoleMatchingScreen(),
      ),

      // Page 4 Screen 5: Live AI Interview Session
      GoRoute(
        path: '/live-interview',
        name: 'live_interview',
        builder: (context, state) => const LiveInterviewScreen(),
      ),

      // Page 4 Screen 6: Interview Evaluation Report
      GoRoute(
        path: '/evaluation-report',
        name: 'evaluation_report',
        builder: (context, state) => const InterviewEvaluationReportScreen(),
      ),

      // Page 4 Screen 9: Recruiter Candidates List
      GoRoute(
        path: '/recruiter/candidates',
        name: 'recruiter_candidates',
        builder: (context, state) => const RecruiterCandidatesScreen(),
      ),

      // Page 4 Screen 10: Recruiter Analytics Dashboard
      GoRoute(
        path: '/recruiter/dashboard',
        name: 'recruiter_dashboard',
        builder: (context, state) => const RecruiterAnalyticsScreen(),
      ),

      // Page 5: 11-Step System Workflow
      GoRoute(
        path: '/workflow',
        name: 'system_workflow',
        builder: (context, state) => const SystemWorkflowScreen(),
      ),

      // Dev Foundation / Backend Health Check
      GoRoute(
        path: '/foundation',
        name: 'foundation',
        builder: (context, state) => const FoundationScreen(),
      ),

      // Existing feature routes
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
