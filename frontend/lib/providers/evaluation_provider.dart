import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/evaluation_model.dart';
import 'package:frontend/services/evaluation_service.dart';

final evaluationServiceProvider = Provider<EvaluationService>((ref) {
  return EvaluationService();
});

final sessionEvaluationReportProvider = FutureProvider.autoDispose.family<SessionEvaluationReportModel, String>((ref, sessionId) async {
  final service = ref.watch(evaluationServiceProvider);
  return service.getSessionReport(sessionId);
});

class SessionEvaluationNotifier extends Notifier<AsyncValue<SessionEvaluationReportModel?>> {
  @override
  AsyncValue<SessionEvaluationReportModel?> build() {
    return const AsyncValue.data(null);
  }

  Future<SessionEvaluationReportModel> evaluateSession(String sessionId, {bool forceReevaluate = false}) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(evaluationServiceProvider);
      final report = await service.evaluateSession(sessionId, forceReevaluate: forceReevaluate);
      state = AsyncValue.data(report);
      return report;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<SessionEvaluationReportModel> loadReport(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(evaluationServiceProvider);
      final report = await service.getSessionReport(sessionId);
      state = AsyncValue.data(report);
      return report;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final sessionEvaluationNotifierProvider =
    NotifierProvider<SessionEvaluationNotifier, AsyncValue<SessionEvaluationReportModel?>>(
  SessionEvaluationNotifier.new,
);
