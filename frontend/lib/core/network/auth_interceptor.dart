import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio _dio;
  final TokenStorage _storage;

  AuthInterceptor({required Dio dio, TokenStorage? storage})
      : _dio = dio,
        _storage = storage ?? TokenStorage();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _storage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshEndpoint = err.requestOptions.path.contains(ApiConstants.refreshEndpoint);
    final hasRefreshToken = _storage.refreshToken != null && _storage.refreshToken!.isNotEmpty;

    if (isUnauthorized && !isRefreshEndpoint && hasRefreshToken) {
      try {
        final refreshResponse = await _dio.post(
          ApiConstants.refreshEndpoint,
          data: {'refresh_token': _storage.refreshToken},
          options: Options(headers: {'Authorization': null}),
        );

        if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
          final newAccessToken = refreshResponse.data['access_token'] as String;
          final newRefreshToken = refreshResponse.data['refresh_token'] as String;
          _storage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );

          // Retry the original failed request
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final cloneReq = await _dio.fetch(retryOptions);
          return handler.resolve(cloneReq);
        }
      } catch (refreshErr) {
        // Refresh token failed or revoked
        _storage.clearTokens();
      }
    }

    handler.next(err);
  }
}
