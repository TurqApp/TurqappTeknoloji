import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Chat conversation opens and sends a real text message',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'chat_send_message_e2e',
        tester,
        () async {
          await launchTurqApp(tester);
          await expectFeedScreen(tester);

          await tapItKey(tester, IntegrationTestKeys.navChat);
          expect(byItKey(IntegrationTestKeys.screenChat), findsOneWidget);

          final chatListing = await waitForSurfaceProbe(
            tester,
            'chat',
            (payload) =>
                payload['registered'] == true &&
                (payload['filteredCount'] as num? ?? 0) > 0,
            reason: 'Chat send flow requires at least one seeded conversation.',
          );
          final chatIds = (chatListing['chatIds'] as List<dynamic>)
              .map((item) => item?.toString() ?? '')
              .where((item) => item.isNotEmpty)
              .toList(growable: false);
          final firstChatId = chatIds.first;

          await tapItKey(
            tester,
            IntegrationTestKeys.chatTile(firstChatId),
            settlePumps: 10,
          );
          expect(
            byItKey(IntegrationTestKeys.screenChatConversation),
            findsOneWidget,
          );

          expect(byItKey(IntegrationTestKeys.actionChatAttach), findsOneWidget);
          expect(
            byItKey(IntegrationTestKeys.actionChatGifPicker),
            findsOneWidget,
          );
          expect(byItKey(IntegrationTestKeys.actionChatCamera), findsOneWidget);
          expect(byItKey(IntegrationTestKeys.actionChatMic), findsOneWidget);

          final messageText = uniqueTestText('turqapp chat e2e');
          await tester.enterText(
            byItKey(IntegrationTestKeys.inputChatComposer),
            messageText,
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(byItKey(IntegrationTestKeys.actionChatSend), findsOneWidget);
          await tapItKey(
            tester,
            IntegrationTestKeys.actionChatSend,
            settlePumps: 10,
          );

          final conversation = await waitForSurfaceProbe(
            tester,
            'chatConversation',
            (payload) =>
                payload['registered'] == true &&
                payload['chatId'] == firstChatId &&
                payload['lastSentText'] == messageText &&
                payload['lastSentType'] == 'text',
            reason: 'Chat send did not complete with a real text payload.',
          );

          expect(conversation['draftText'], isEmpty);
          final latestMessageText =
              (conversation['latestMessageText'] as String?)?.trim() ?? '';
          if (latestMessageText.isNotEmpty) {
            expect(latestMessageText, messageText);
          }
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
