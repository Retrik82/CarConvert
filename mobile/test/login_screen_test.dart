import 'package:carconvert/screens/login_screen.dart';
import 'package:carconvert/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LoginScreen shows validation errors on empty submit', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: LoginScreen(onLoggedIn: () {}),
      ),
    );

    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('LoginScreen navigates to register screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: LoginScreen(onLoggedIn: () {}),
      ),
    );

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Register'), findsOneWidget);
  });

  testWidgets('LoginScreen navigates to forgot password screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: LoginScreen(onLoggedIn: () {}),
      ),
    );

    await tester.tap(find.text('Forgot Password'));
    await tester.pumpAndSettle();

    expect(find.text('Send reset link'), findsOneWidget);
  });
}
