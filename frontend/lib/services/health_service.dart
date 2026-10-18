import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/health_status.dart';

class HealthService {
  final Dio _dio;

  HealthService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  Future<HealthStatus> checkHealth() async {
    try {
      final response = await _dio.get(ApiConstants.healthEndpoint);
      if (response.statusCode == 200 && response.data != null) {
        return HealthStatus.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Unexpected health status response: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout: Backend at ${ApiConstants.baseUrl} did not respond.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot reach backend at ${ApiConstants.baseUrl}. Ensure the FastAPI server is running.');
      } else if (e.response != null) {
        throw Exception('Backend returned HTTP ${e.response?.statusCode}: ${e.response?.statusMessage}');
      }
      throw Exception('Network error connecting to ${ApiConstants.baseUrl}: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error checking backend health: $e');
    }
  }
}
