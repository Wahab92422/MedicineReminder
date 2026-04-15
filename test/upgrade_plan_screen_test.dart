import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicine_app/screens/upgrade_plan_screen.dart';
import 'package:medicine_app/theme/app_theme.dart';

void main() {
  testWidgets('UpgradePlanScreen shows upgrade CTA', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const UpgradePlanScreen(),
        ),
      ),
    );

    expect(find.text('Medicine Premium'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Subscribe with Google Play'),
      findsOneWidget,
    );
  });
}
