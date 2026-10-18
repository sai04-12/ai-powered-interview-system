import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/auth_tokens.dart';
import '../models/user_model.dart';

class AuthService {
  final Dio _dio;
  final TokenStorage _storage;

  AuthService({Dio? dio, TokenStorage? storage})
      : _dio = dio ?? ApiClient().dio,
        _storage = storage ?? TokenStorage();

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.loginEndpoint,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final tokens = AuthTokens.fromJson(response.data as Map<String, dynamic>);
        _storage.saveTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        );
        return tokens;
      }
      throw Exception('Login failed with status: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final data = e.response?.data as Map;
        final detail = data['detail'];
        if (detail != null) {
          throw Exception(detail.toString());
        }
      }
      throw Exception('Network or server error during login: ${e.message}');
    }
  }

  Future<UserModel> register({
    required String email,
    required String password,
    String? fullName,
    String role = 'candidate',
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.registerEndpoint,
        data: {
          'email': email.trim(),
          'password': password,
          if (fullName != null && fullName.isNotEmpty) 'full_name': fullName.trim(),
          'role': role,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Registration failed with status: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final data = e.response?.data as Map;
        final detail = data['detail'];
        if (detail != null) {
          throw Exception(detail.toString());
        }
      }
      throw Exception('Registration error: ${e.message}');
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get(ApiConstants.meEndpoint);
      if (response.statusCode == 200 && response.data != null) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to fetch profile: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final detail = (e.response?.data as Map)['detail'];
        if (detail != null) throw Exception(detail.toString());
      }
      throw Exception('Error loading profile: ${e.message}');
    }
  }

  Future<void> logout() async {
    final refreshToken = _storage.refreshToken;
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _dio.post(
          ApiConstants.logoutEndpoint,
          data: {'refresh_token': refreshToken},
        );
      }
    } catch (_) {
      // Best-effort remote revocation
    } finally {
      _storage.clearTokens();
    }
  }
}
