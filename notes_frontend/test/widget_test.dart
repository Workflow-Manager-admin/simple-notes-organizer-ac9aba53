import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_frontend/main.dart';

void main() {
  testWidgets('Minimal NotesApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());

    // The NotesApp main list should have an AppBar with 'All Notes' as title.
    expect(find.text('All Notes'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('App bar has correct title', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());

    expect(find.text('All Notes'), findsOneWidget);
  });
}
