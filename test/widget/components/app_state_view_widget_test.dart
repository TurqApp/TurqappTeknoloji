import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';

void main() {
  testWidgets('AppStateView renders loading state', (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AppStateView.loading(title: 'Loading data'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading data'), findsOneWidget);
  });

  testWidgets('AppStateView renders empty state with message', (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AppStateView.empty(
            title: 'No items',
            message: 'Try changing filters',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(find.text('No items'), findsOneWidget);
    expect(find.text('Try changing filters'), findsOneWidget);
  });

  testWidgets('AppStateView renders retry action for errors', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: AppStateView.error(
            title: 'Could not load',
            retryLabel: 'Retry now',
            onRetry: () => retryCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Retry now'));
    await tester.pump();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(retryCount, 1);
  });
}
