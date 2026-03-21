import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';

import 'helpers/smoke_artifact_collector.dart';
import 'helpers/test_app_bootstrap.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Chat listing opens cleanly and keeps tabs usable',
    (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.exceptionAsString();
        if (text.contains('cloud_firestore/permission-denied')) {
          debugPrint('Suppressed non-fatal: $text');
          return;
        }
        originalOnError?.call(details);
      };

      try {
        await SmokeArtifactCollector.runScenario(
          'chat_listing_smoke',
          tester,
          () async {
            await launchTurqApp(tester);
            await expectFeedScreen(tester);

            await tester.tap(byItKey(IntegrationTestKeys.navChat));
            await tester.pumpAndSettle(const Duration(seconds: 2));
            await expectNoFlutterException(tester);

            expect(find.text('Sohbetler'), findsOneWidget);
            expect(find.text('Tümü'), findsOneWidget);
            expect(find.text('Okunmamış'), findsOneWidget);
            expect(find.text('Arşiv'), findsOneWidget);
            expect(find.text('Henüz sohbetin yok'), findsOneWidget);

            final controller = ChatListingController.ensure();
            expect(controller.waiting.value, isFalse);

            await tester.tap(find.text('Okunmamış'));
            await tester.pumpAndSettle(const Duration(milliseconds: 500));
            expect(controller.selectedTab.value, 'unread');
            await expectNoFlutterException(tester);

            await tester.tap(find.text('Arşiv'));
            await tester.pumpAndSettle(const Duration(milliseconds: 500));
            expect(controller.selectedTab.value, 'archive');
            await expectNoFlutterException(tester);

            await tester.tap(find.text('Tümü'));
            await tester.pumpAndSettle(const Duration(milliseconds: 500));
            expect(controller.selectedTab.value, 'all');
            await expectNoFlutterException(tester);

            final searchField = find.byType(TextField).first;
            await tester.enterText(searchField, 'olmayan sohbet');
            await tester.pumpAndSettle(const Duration(milliseconds: 600));
            expect(controller.search.text, 'olmayan sohbet');
            await expectNoFlutterException(tester);

            await tester.enterText(searchField, '');
            await tester.pumpAndSettle(const Duration(milliseconds: 400));
            expect(controller.search.text, isEmpty);

            await tester.drag(
              find.byType(RefreshIndicator),
              const Offset(0, 260),
            );
            await tester.pump(const Duration(milliseconds: 300));
            await tester.pumpAndSettle(const Duration(seconds: 2));
            await expectNoFlutterException(tester);
          },
        );
      } finally {
        FlutterError.onError = originalOnError;
      }
    },
    skip: !kRunIntegrationSmoke,
  );
}
