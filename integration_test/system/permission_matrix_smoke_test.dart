import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_media_test_harness.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Chat/chat_controller.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';

File _tempMediaFile(String name, List<int> bytes) {
  final file = File('${Directory.systemTemp.path}/$name');
  file.writeAsBytesSync(bytes, flush: true);
  return file;
}

Future<ChatController> _openFirstConversation(WidgetTester tester) async {
  await tapItKey(tester, IntegrationTestKeys.navChat);
  expect(byItKey(IntegrationTestKeys.screenChat), findsOneWidget);

  final chatListing = await waitForSurfaceProbe(
    tester,
    'chat',
    (payload) =>
        payload['registered'] == true &&
        (payload['filteredCount'] as num? ?? 0) > 0,
    reason: 'Permission matrix requires at least one seeded conversation.',
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
  final firstUserId = userIds.isNotEmpty ? userIds.first : '';

  await tapItKey(
    tester,
    IntegrationTestKeys.chatTile(firstChatId),
    settlePumps: 10,
  );
  expect(byItKey(IntegrationTestKeys.screenChatConversation), findsOneWidget);

  return ChatController.maybeFind(tag: firstChatId) ??
      ChatController.ensure(
        chatID: firstChatId,
        userID: firstUserId,
        tag: firstChatId,
      );
}

Future<void> _openAttachmentAction(
  WidgetTester tester,
  String actionKey,
) async {
  await tapItKey(tester, IntegrationTestKeys.actionChatAttach, settlePumps: 3);
  await pumpUntilVisible(tester, byItKey(actionKey), maxPumps: 20);
  await tapItKey(tester, actionKey, settlePumps: 8);
}

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Permission matrix covers deny and retry for photos, camera, and microphone',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'permission_matrix_smoke',
        tester,
        () async {
          IntegrationMediaTestHarness.reset();

          await launchTurqApp(tester);
          await expectFeedScreen(tester);

          final controller = await _openFirstConversation(tester);
          final imageFile = _tempMediaFile(
            'turqapp_permission_retry_image.jpg',
            const <int>[1, 2, 3, 4, 5],
          );

          IntegrationMediaTestHarness.queueFailure(
            IntegrationMediaFailureKind.cameraDenied,
          );
          await tapItKey(
            tester,
            IntegrationTestKeys.actionChatCamera,
            settlePumps: 8,
          );
          await waitForSurfaceProbe(
            tester,
            'chatConversation',
            (payload) => payload['lastMediaFailureCode'] == 'camera_denied',
            reason: 'Camera deny path did not surface camera_denied.',
          );

          IntegrationMediaTestHarness.queueCameraCaptureResult(imageFile);
          await tapItKey(
            tester,
            IntegrationTestKeys.actionChatCamera,
            settlePumps: 8,
          );
          await waitForSurfaceProbe(
            tester,
            'chatConversation',
            (payload) =>
                payload['lastMediaAction'] == 'open_custom_camera_capture' &&
                (payload['selectedImageCount'] as num? ?? 0) == 1,
            reason: 'Camera retry did not select an image successfully.',
          );
          controller.clearPendingMedia();
          await tester.pump(const Duration(milliseconds: 250));

          IntegrationMediaTestHarness.queueFailure(
            IntegrationMediaFailureKind.photosDenied,
          );
          await _openAttachmentAction(
            tester,
            IntegrationTestKeys.actionChatAttachPhotos,
          );
          await waitForSurfaceProbe(
            tester,
            'chatConversation',
            (payload) => payload['lastMediaFailureCode'] == 'photos_denied',
            reason: 'Photos deny path did not surface photos_denied.',
          );

          IntegrationMediaTestHarness.queueGalleryImageSelection([imageFile]);
          await _openAttachmentAction(
            tester,
            IntegrationTestKeys.actionChatAttachPhotos,
          );
          await waitForSurfaceProbe(
            tester,
            'chatConversation',
            (payload) =>
                payload['lastMediaAction'] == 'pick_image' &&
                (payload['selectedImageCount'] as num? ?? 0) == 1,
            reason: 'Photos retry did not select an image successfully.',
          );
          controller.clearPendingMedia();
          await tester.pump(const Duration(milliseconds: 250));

          IntegrationMediaTestHarness.queueVoicePermission(false);
          await tapItKey(
            tester,
            IntegrationTestKeys.actionChatMic,
            settlePumps: 8,
          );
          await waitForSurfaceProbe(
            tester,
            'chatConversation',
            (payload) => payload['lastMediaFailureCode'] == 'microphone_denied',
            reason: 'Microphone deny path did not surface microphone_denied.',
          );

          IntegrationMediaTestHarness.queueVoicePermission(true);
          await tapItKey(
            tester,
            IntegrationTestKeys.actionChatMic,
            settlePumps: 6,
          );
          await waitForSurfaceProbe(
            tester,
            'chatConversation',
            (payload) =>
                payload['lastMediaAction'] == 'start_voice_recording' &&
                payload['isRecording'] == true,
            reason: 'Microphone retry did not start recording.',
          );
          await tapItKey(
            tester,
            IntegrationTestKeys.actionChatRecordingCancel,
            settlePumps: 6,
          );
          await waitForSurfaceProbe(
            tester,
            'chatConversation',
            (payload) => payload['isRecording'] == false,
            reason: 'Recording cancel did not stop the recording state.',
          );
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
