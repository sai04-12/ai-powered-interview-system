import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/app.dart';
import 'package:frontend/models/health_status.dart';
import 'package:frontend/providers/health_provider.dart';

void main() {
  testWidgets('InterviewPlatformApp smoke test', (WidgetTester tester) async {
    // Build our app with mocked health provider to avoid network timeouts during tests
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthCheckProvider.overrideWith(
            (ref) async => const HealthStatus(
              status: 'healthy',
              timestamp: '2026-10-18T11:30:00Z',
              environment: 'test',
              version: '1.0.0',
              database: 'ready',
            ),
          ),
        ],
        child: const InterviewPlatformApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that platform header and title render
    expect(find.text('AI Interviewer Platform'), findsOneWidget);
    expect(find.text('AI-Powered Intelligent Interview System'), findsOneWidget);
    expect(find.text('FastAPI Backend Operational'), findsOneWidget);
    expect(find.text('Sign In'), findsNWidgets(2));
  });
}
