import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_status.dart';
import '../services/health_service.dart';

final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService();
});

final healthCheckProvider = FutureProvider.autoDispose<HealthStatus>((ref) async {
  final service = ref.watch(healthServiceProvider);
  return await service.checkHealth();
});
