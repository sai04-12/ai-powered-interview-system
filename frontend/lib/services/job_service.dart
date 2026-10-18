import 'package:dio/dio.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/models/job_model.dart';

class JobService {
  final ApiClient _apiClient;

  JobService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<JobModel>> getJobs() async {
    try {
      final response = await _apiClient.client.get(
        '${ApiConstants.jobsPrefix}/',
      );
      final list = response.data as List<dynamic>? ?? [];
      return list.map((item) => JobModel.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Failed to load jobs';
      throw Exception(detail.toString());
    }
  }

  Future<JobModel> getJob(String id) async {
    try {
      final response = await _apiClient.client.get(
        '${ApiConstants.jobsPrefix}/$id',
      );
      return JobModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Failed to load job details';
      throw Exception(detail.toString());
    }
  }

  Future<JobModel> createJob({
    required String title,
    String? company,
    required String description,
    required List<String> requiredSkills,
    List<String> preferredSkills = const [],
    int? minExperienceYears,
    String? educationRequirements,
  }) async {
    try {
      final response = await _apiClient.client.post(
        '${ApiConstants.jobsPrefix}/',
        data: {
          'title': title,
          'company': company,
          'description': description,
          'required_skills': requiredSkills,
          'preferred_skills': preferredSkills,
          'min_experience_years': minExperienceYears,
          'education_requirements': educationRequirements,
        },
      );
      return JobModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Failed to create job';
      throw Exception(detail.toString());
    }
  }

  Future<void> deleteJob(String id) async {
    try {
      await _apiClient.client.delete(
        '${ApiConstants.jobsPrefix}/$id',
      );
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message ?? 'Failed to delete job';
      throw Exception(detail.toString());
    }
  }
}
