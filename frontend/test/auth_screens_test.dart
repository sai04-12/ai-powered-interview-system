import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/app_theme.dart';
import 'package:frontend/features/authentication/screens/login_screen.dart';
import 'package:frontend/features/authentication/screens/register_screen.dart';

void main() {
  group('Authentication Screens UI Tests', () {
    testWidgets('LoginScreen renders inputs and validates empty submissions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProviderScope(
            child: LoginScreen(),
          ),
        ),
      );

      // Verify header and fields exist
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Sign In'), findsOneWidget);

      // Tap Sign In button without entering text
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      // Verify form validation error messages
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders inputs and validates password length', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProviderScope(
            child: RegisterScreen(),
          ),
        ),
      );

      // Verify inputs and account type options exist
      expect(find.text('Join the Platform'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3)); // Name, Email, Password
      expect(find.text('Candidate'), findsOneWidget);
      expect(find.text('Recruiter'), findsOneWidget);

      // Enter short password and tap submit
      await tester.enterText(find.byType(TextFormField).at(0), 'Alice Candidate');
      await tester.enterText(find.byType(TextFormField).at(1), 'alice@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'short');

      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 8 characters long'), findsOneWidget);
    });
  });
}
