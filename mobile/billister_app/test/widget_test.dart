// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:billister_app/app.dart';

void main() {
  testWidgets('App renders shell', (WidgetTester tester) async {
    // Setup mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(BillisterApp(sharedPreferences: prefs));

    // Bottom navigation is the main shell.
    expect(find.text('Hjem'), findsWidgets);
    expect(find.text('Favoritter'), findsWidgets);
    expect(find.text('Søg'), findsWidgets);
    expect(find.text('Søgeagent'), findsWidgets);
    expect(find.text('Menu'), findsWidgets);
  });
}
