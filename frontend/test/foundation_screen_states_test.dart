import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/app.dart';
import 'package:frontend/models/health_status.dart';
import 'package:frontend/providers/health_provider.dart';

void main() {
  group('FoundationScreen State Tests', () {
    testWidgets('Displays loading state when healthCheckProvider is pending', (
      WidgetTester tester,
    ) async {
      final completer = Completer<HealthStatus>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthCheckProvider.overrideWith((ref) => completer.future),
          ],
          child: const InterviewPlatformApp(),
        ),
      );

      // Verify loading state is shown initially
      expect(find.text('Connecting to Backend...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete to avoid pending timers
      completer.complete(
        const HealthStatus(
          status: 'healthy',
          timestamp: '2026-10-18T11:00:00Z',
          environment: 'test',
          version: '1.0.0',
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('Displays success state when backend is reachable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthCheckProvider.overrideWith(
              (ref) async => const HealthStatus(
                status: 'healthy',
                timestamp: '2026-10-18T11:00:00Z',
                environment: 'development',
                version: '1.0.0',
                database: 'ready',
              ),
            ),
          ],
          child: const InterviewPlatformApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('FastAPI Backend Operational'), findsOneWidget);
      expect(find.text('CONNECTED'), findsOneWidget);
      expect(
        find.textContaining('Environment: development | API Version: 1.0.0'),
        findsOneWidget,
      );
    });

    testWidgets('Displays error state gracefully without crashing when backend is offline', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthCheckProvider.overrideWith(
              (ref) async => throw Exception('Cannot reach backend at http://127.0.0.1:8000'),
            ),
          ],
          child: const InterviewPlatformApp(),
        ),
      );

      await tester.pumpAndSettle();

      // UI should gracefully display error state and not crash
      expect(find.text('Backend Offline / Unreachable'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsWidgets);
    });
  });
}
