import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:frontend/services/health_service.dart';

void main() {
  group('Live Backend Integration Tests (Real HTTP)', () {
    test('HealthService connects to live FastAPI server and retrieves valid status', () async {
      final service = HealthService();
      final health = await service.checkHealth();

      expect(health.status, 'healthy');
      expect(health.version, '1.0.0');
      expect(health.environment, isNotEmpty);
      expect(health.timestamp, isNotEmpty);
    });

    test('HealthService handles unavailable server gracefully without crashing', () async {
      // Create a service pointing to a port that is guaranteed not running
      final deadDio = Dio(
        BaseOptions(
          baseUrl: 'http://127.0.0.1:59999',
          connectTimeout: const Duration(milliseconds: 500),
          receiveTimeout: const Duration(milliseconds: 500),
        ),
      );

      final deadService = HealthService(dio: deadDio);

      expect(
        () async => await deadService.checkHealth(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
