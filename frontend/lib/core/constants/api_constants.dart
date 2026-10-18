class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  static const String apiVersion = '/api/v1';
  static const String healthEndpoint = '$apiVersion/health';
  static const String rootHealthEndpoint = '/health';

  // Authentication endpoints
  static const String authPrefix = '$apiVersion/auth';
  static const String registerEndpoint = '$authPrefix/register';
  static const String loginEndpoint = '$authPrefix/login';
  static const String refreshEndpoint = '$authPrefix/refresh';
  static const String logoutEndpoint = '$authPrefix/logout';
  static const String meEndpoint = '$authPrefix/me';
  
  // Resumes endpoints
  static const String resumesPrefix = '$apiVersion/resumes';
  static const String resumeUploadEndpoint = '$resumesPrefix/upload';

  // Jobs endpoints
  static const String jobsPrefix = '$apiVersion/jobs';
  
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
