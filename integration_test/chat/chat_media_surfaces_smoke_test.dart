import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Chat/chat_controller.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Chat media surfaces stay visible and synthetic media sends work',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'chat_media_surfaces_smoke',
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
            reason:
                'Chat media smoke requires at least one seeded conversation.',
          );
          final chatIds = (chatListing['chatIds'] as List<dynamic>)
              .map((item) => item?.toString() ?? '')
              .where((item) => item.isNotEmpty)
              .toList(growable: false);
          final userIds = (chatListing['userIds'] as List<dynamic>)
              .map((item) => item?.toString() ?? '')
              .where((item) => item.isNotEmpty)
              .toList(growable: false);
          final firstChatId = chatIds.first;
          final firstUserId = userIds.isNotEmpty
              ? userIds.first
              : chatListing['userId'] as String? ?? '';

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

          final controller = ChatController.maybeFind(tag: firstChatId) ??
              ChatController.ensure(
                chatID: firstChatId,
                userID: firstUserId,
                tag: firstChatId,
              );

          controller.seedSelectedGifForTesting(
            'https://example.test/turqapp-smoke.gif',
          );
          await tester.pump(const Duration(milliseconds: 250));
          expect(byItKey(IntegrationTestKeys.actionChatSend), findsOneWidget);

          await tapItKey(
            tester,
            IntegrationTestKeys.actionChatSend,
            settlePumps: 10,
          );

          final afterGif = await waitForSurfaceProbe(
            tester,
            'chatConversation',
            (payload) =>
                payload['registered'] == true &&
                payload['chatId'] == firstChatId &&
                payload['lastSentType'] == 'gif',
            reason: 'Synthetic GIF send did not reach chat conversation.',
          );
          expect(afterGif['selectedGifUrl'], isEmpty);

          await controller.sendSyntheticAudioForTesting(
            audioUrl: 'https://example.test/turqapp-smoke.m4a',
            audioDurationMs: 1400,
          );
          await tester.pump(const Duration(milliseconds: 300));

          final afterAudio = await waitForSurfaceProbe(
            tester,
            'chatConversation',
            (payload) =>
                payload['registered'] == true &&
                payload['chatId'] == firstChatId &&
                payload['lastSentType'] == 'audio' &&
                payload['latestMessageType'] == 'audio',
            reason: 'Synthetic audio send did not reach chat conversation.',
          );

          expect(
            (afterAudio['lastSentMessageId'] as String?)?.trim().isNotEmpty,
            isTrue,
          );
          expect(
            (afterAudio['lastSentAudioUrl'] as String?)?.contains('.m4a'),
            isTrue,
          );

          await controller.sendSyntheticImagesForTesting(const [
            'https://example.test/turqapp-smoke-1.webp',
            'https://example.test/turqapp-smoke-2.webp',
          ]);
          await tester.pump(const Duration(milliseconds: 300));

          final afterImages = await waitForSurfaceProbe(
            tester,
            'chatConversation',
            (payload) =>
                payload['registered'] == true &&
                payload['chatId'] == firstChatId &&
                payload['lastSentType'] == 'media' &&
                payload['latestMessageType'] == 'media' &&
                (payload['lastSentMediaCount'] as num? ?? 0) == 2 &&
                (payload['latestMessageMediaCount'] as num? ?? 0) == 2,
            reason: 'Synthetic image send did not reach chat conversation.',
          );

          expect(
            (afterImages['lastSentPrimaryMediaUrl'] as String?)
                ?.contains('turqapp-smoke-1.webp'),
            isTrue,
          );

          await controller.sendSyntheticVideoForTesting(
            videoUrl: 'https://example.test/turqapp-smoke-video.mp4',
            thumbnailUrl: 'https://example.test/turqapp-smoke-video.webp',
          );
          await tester.pump(const Duration(milliseconds: 300));

          final afterVideo = await waitForSurfaceProbe(
            tester,
            'chatConversation',
            (payload) =>
                payload['registered'] == true &&
                payload['chatId'] == firstChatId &&
                payload['lastSentType'] == 'video' &&
                payload['latestMessageType'] == 'video',
            reason: 'Synthetic video send did not reach chat conversation.',
          );

          expect(
            (afterVideo['lastSentVideoUrl'] as String?)
                ?.contains('turqapp-smoke-video.mp4'),
            isTrue,
          );
          expect(
            (afterVideo['latestMessageVideoUrl'] as String?)
                ?.contains('turqapp-smoke-video.mp4'),
            isTrue,
          );
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
