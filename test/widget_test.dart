import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:school_mobile_app/main.dart';

void main() {
  testWidgets('shows role selection screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(SchoolMobileApp(prefs: prefs));
    await tester.pumpAndSettle();

    expect(find.text('Choose your portal'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });

  testWidgets('bottom bar navigates between admin pages', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    SharedPreferences.setMockInitialValues({
      'auth.token': 'test-token',
      'auth.role': 'admin',
      'auth.user': '{"name":"Admin","email":"admin@example.com"}',
      'name': 'Admin',
      'email': 'admin@example.com',
      'role': 'admin',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(SchoolMobileApp(prefs: prefs));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    await tester.tap(find.byIcon(Icons.school_rounded).last);
    await tester.pumpAndSettle();

    expect(find.text('Students'), findsWidgets);
    expect(find.textContaining('Search, filter, create'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('bottom bar navigates in Arabic RTL locale', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    SharedPreferences.setMockInitialValues({
      'auth.token': 'test-token',
      'auth.role': 'admin',
      'auth.user': '{"name":"Admin","email":"admin@example.com"}',
      'name': 'Admin',
      'email': 'admin@example.com',
      'role': 'admin',
      'locale': 'ar',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(SchoolMobileApp(prefs: prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.fact_check_rounded).last);
    await tester.pumpAndSettle();

    expect(find.text('الحضور'), findsWidgets);
    expect(find.textContaining('تسجيل ومراجعة الحضور'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('classrooms page opens in Arabic locale', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    SharedPreferences.setMockInitialValues({
      'auth.token': 'test-token',
      'auth.role': 'admin',
      'auth.user': '{"name":"Admin","email":"admin@example.com"}',
      'name': 'Admin',
      'email': 'admin@example.com',
      'role': 'admin',
      'locale': 'ar',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(SchoolMobileApp(prefs: prefs));
    await tester.pumpAndSettle();

    GoRouter.of(
      tester.element(find.byType(Scaffold).first),
    ).go('/admin/classrooms');
    await tester.pumpAndSettle();

    expect(
      GoRouter.of(
        tester.element(find.byType(Scaffold).first),
      ).routerDelegate.currentConfiguration.uri.path,
      '/admin/classrooms',
    );
    expect(find.byType(ListView), findsWidgets);
    await tester.binding.setSurfaceSize(null);
  });
}
