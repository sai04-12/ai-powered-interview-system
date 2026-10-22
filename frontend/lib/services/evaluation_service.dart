import 'package:dio/dio.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/models/evaluation_model.dart';

class EvaluationService {
  final ApiClient _apiClient;

  EvaluationService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<AnswerEvaluationModel> evaluateAnswer(
    String answerId, {
    bool forceReevaluate = false,
  }) async {
    try {
      final response = await _apiClient.client.post(
        '${ApiConstants.evaluationsPrefix}/answers/$answerId',
        data: {'force_reevaluate': forceReevaluate},
      );
      return AnswerEvaluationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Failed to evaluate answer';
      throw Exception(detail.toString());
    }
  }

  Future<AnswerEvaluationModel?> getAnswerEvaluation(String answerId) async {
    try {
      final response = await _apiClient.client.get(
        '${ApiConstants.evaluationsPrefix}/answers/$answerId',
      );
      return AnswerEvaluationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Failed to retrieve answer evaluation';
      throw Exception(detail.toString());
    }
  }

  Future<SessionEvaluationReportModel> evaluateSession(
    String sessionId, {
    bool forceReevaluate = false,
  }) async {
    try {
      final response = await _apiClient.client.post(
        '${ApiConstants.evaluationsPrefix}/sessions/$sessionId/evaluate',
        data: {'force_reevaluate': forceReevaluate},
      );
      return SessionEvaluationReportModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Failed to evaluate interview session';
      throw Exception(detail.toString());
    }
  }

  Future<SessionEvaluationReportModel> getSessionReport(String sessionId) async {
    try {
      final response = await _apiClient.client.get(
        '${ApiConstants.evaluationsPrefix}/sessions/$sessionId/report',
      );
      return SessionEvaluationReportModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Failed to load evaluation report';
      throw Exception(detail.toString());
    }
  }
}
