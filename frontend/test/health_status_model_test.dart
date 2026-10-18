import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/health_status.dart';

void main() {
  group('HealthStatus Model Tests', () {
    test('fromJson parses complete valid JSON correctly', () {
      final json = {
        'status': 'healthy',
        'timestamp': '2026-10-18T11:00:00Z',
        'environment': 'development',
        'version': '1.0.0',
        'database': 'ready',
      };

      final model = HealthStatus.fromJson(json);

      expect(model.status, 'healthy');
      expect(model.timestamp, '2026-10-18T11:00:00Z');
      expect(model.environment, 'development');
      expect(model.version, '1.0.0');
      expect(model.database, 'ready');
    });

    test('fromJson handles missing optional fields with sensible defaults', () {
      final json = <String, dynamic>{};

      final model = HealthStatus.fromJson(json);

      expect(model.status, 'unknown');
      expect(model.timestamp, '');
      expect(model.environment, 'unknown');
      expect(model.version, '0.0.0');
      expect(model.database, isNull);
    });

    test('toJson serializes model accurately', () {
      const model = HealthStatus(
        status: 'healthy',
        timestamp: '2026-10-18T11:00:00Z',
        environment: 'staging',
        version: '1.0.0',
        database: 'ready',
      );

      final json = model.toJson();

      expect(json['status'], 'healthy');
      expect(json['timestamp'], '2026-10-18T11:00:00Z');
      expect(json['environment'], 'staging');
      expect(json['version'], '1.0.0');
      expect(json['database'], 'ready');
    });
  });
}
