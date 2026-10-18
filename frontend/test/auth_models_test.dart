import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/auth_tokens.dart';
import 'package:frontend/models/user_model.dart';

void main() {
  group('Auth Model Tests', () {
    test('UserModel.fromJson parses complete user data correctly', () {
      final json = {
        'id': 'user-uuid-1234',
        'email': 'candidate@example.com',
        'full_name': 'Jane Doe',
        'role': 'candidate',
        'is_active': true,
        'created_at': '2026-10-18T10:00:00Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'user-uuid-1234');
      expect(user.email, 'candidate@example.com');
      expect(user.fullName, 'Jane Doe');
      expect(user.role, 'candidate');
      expect(user.isActive, isTrue);
      expect(user.isCandidate, isTrue);
      expect(user.isRecruiter, isFalse);
      expect(user.isAdmin, isFalse);
    });

    test('UserModel.toJson serializes model accurately', () {
      final user = UserModel(
        id: 'recruiter-id-5678',
        email: 'recruiter@company.com',
        fullName: 'John Hiring',
        role: 'recruiter',
        isActive: true,
        createdAt: DateTime.parse('2026-10-18T11:00:00Z'),
      );

      final json = user.toJson();

      expect(json['id'], 'recruiter-id-5678');
      expect(json['email'], 'recruiter@company.com');
      expect(json['full_name'], 'John Hiring');
      expect(json['role'], 'recruiter');
      expect(user.isRecruiter, isTrue);
    });

    test('AuthTokens.fromJson parses token payloads properly', () {
      final json = {
        'access_token': 'test_jwt_access_token',
        'refresh_token': 'test_refresh_token_string',
        'token_type': 'bearer',
        'expires_in': 3600,
      };

      final tokens = AuthTokens.fromJson(json);

      expect(tokens.accessToken, 'test_jwt_access_token');
      expect(tokens.refreshToken, 'test_refresh_token_string');
      expect(tokens.tokenType, 'bearer');
      expect(tokens.expiresIn, 3600);
    });
  });
}
