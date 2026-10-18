import 'package:dio/dio.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/models/match_model.dart';
import 'package:frontend/models/resume_model.dart';

class ResumeService {
  final ApiClient _apiClient;

  ResumeService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<ResumeModel> uploadResume({
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });

      final response = await _apiClient.client.post(
        ApiConstants.resumeUploadEndpoint,
        data: formData,
      );

      return ResumeModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Resume upload failed';
      throw Exception(detail.toString());
    }
  }

  Future<List<ResumeModel>> getMyResumes() async {
    try {
      final response = await _apiClient.client.get(
        '${ApiConstants.resumesPrefix}/',
      );
      final list = response.data as List<dynamic>? ?? [];
      return list.map((item) => ResumeModel.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Failed to load resumes';
      throw Exception(detail.toString());
    }
  }

  Future<ResumeModel> getResume(String id) async {
    try {
      final response = await _apiClient.client.get(
        '${ApiConstants.resumesPrefix}/$id',
      );
      return ResumeModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Failed to fetch resume';
      throw Exception(detail.toString());
    }
  }

  Future<void> deleteResume(String id) async {
    try {
      await _apiClient.client.delete(
        '${ApiConstants.resumesPrefix}/$id',
      );
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Failed to delete resume';
      throw Exception(detail.toString());
    }
  }

  Future<MatchModel> matchResumeToJob({
    required String resumeId,
    required String jobId,
  }) async {
    try {
      final response = await _apiClient.client.post(
        '${ApiConstants.resumesPrefix}/$resumeId/match/$jobId',
      );
      return MatchModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Match calculation failed';
      throw Exception(detail.toString());
    }
  }
}
