import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/theme/app_theme.dart';
import 'package:medicine_app/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyState shows title and subtitle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: EmptyState(
            icon: Icons.inbox_outlined,
            title: 'Nothing here',
            subtitle: 'Add items to get started.',
          ),
        ),
      ),
    );

    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Add items to get started.'), findsOneWidget);
  });
}
