import 'package:go_router/go_router.dart';
import '../features/authentication/screens/login_screen.dart';
import '../features/authentication/screens/register_screen.dart';
import '../features/jobs/screens/job_list_screen.dart';
import '../features/resume/screens/resume_list_screen.dart';
import '../features/resume/screens/resume_match_screen.dart';
import '../features/resume/screens/resume_upload_screen.dart';
import '../shared/screens/foundation_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const FoundationScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
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
    ],
  );
}
