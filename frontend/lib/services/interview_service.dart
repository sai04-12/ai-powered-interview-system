import 'package:dio/dio.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/models/interview_model.dart';

class InterviewService {
  final ApiClient _apiClient;

  InterviewService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<InterviewSessionModel> createSession({
    required String jobId,
    String? resumeId,
    int totalQuestions = 5,
    String mode = 'mixed',
  }) async {
    try {
      final response = await _apiClient.client.post(
        '${ApiConstants.interviewsPrefix}/',
        data: {
          'job_id': jobId,
          'resume_id': resumeId,
          'total_questions': totalQuestions,
          'mode': mode,
        },
      );
      return InterviewSessionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Failed to create interview session';
      throw Exception(detail.toString());
    }
  }

  Future<List<InterviewSessionSummaryModel>> getMySessions() async {
    try {
      final response = await _apiClient.client.get(
        '${ApiConstants.interviewsPrefix}/',
      );
      final list = response.data as List<dynamic>? ?? [];
      return list.map((item) => InterviewSessionSummaryModel.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Failed to load sessions';
      throw Exception(detail.toString());
    }
  }

  Future<InterviewSessionModel> getSession(String sessionId) async {
    try {
      final response = await _apiClient.client.get(
        '${ApiConstants.interviewsPrefix}/$sessionId',
      );
      return InterviewSessionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Failed to load session details';
      throw Exception(detail.toString());
    }
  }

  Future<InterviewSessionModel> startSession(String sessionId) async {
    try {
      final response = await _apiClient.client.post(
        '${ApiConstants.interviewsPrefix}/$sessionId/start',
      );
      return InterviewSessionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Failed to start interview session';
      throw Exception(detail.toString());
    }
  }

  Future<InterviewQuestionModel> getCurrentQuestion(String sessionId) async {
    try {
      final response = await _apiClient.client.get(
        '${ApiConstants.interviewsPrefix}/$sessionId/questions/current',
      );
      return InterviewQuestionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Failed to retrieve current question';
      throw Exception(detail.toString());
    }
  }

  Future<InterviewAnswerModel> submitAnswer({
    required String sessionId,
    required String answerText,
  }) async {
    try {
      final response = await _apiClient.client.post(
        '${ApiConstants.interviewsPrefix}/$sessionId/answers',
        data: {'answer_text': answerText},
      );
      return InterviewAnswerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Failed to submit answer';
      throw Exception(detail.toString());
    }
  }

  Future<InterviewNextResultModel> advanceNext(String sessionId) async {
    try {
      final response = await _apiClient.client.post(
        '${ApiConstants.interviewsPrefix}/$sessionId/next',
      );
      return InterviewNextResultModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Failed to advance to next question';
      throw Exception(detail.toString());
    }
  }

  Future<void> abandonSession(String sessionId) async {
    try {
      await _apiClient.client.post(
        '${ApiConstants.interviewsPrefix}/$sessionId/abandon',
      );
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Failed to abandon session';
      throw Exception(detail.toString());
    }
  }
}
