import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_media_test_harness.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';

File _tempMediaFile(String name, List<int> bytes) {
  final file = File('${Directory.systemTemp.path}/$name');
  file.writeAsBytesSync(bytes, flush: true);
  return file;
}

Future<File> _tempPngImageFile(String name) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint()..color = const ui.Color(0xFF4CAF50);
  canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 12, 12), paint);
  final picture = recorder.endRecording();
  final image = await picture.toImage(12, 12);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (byteData == null) {
    throw StateError('Failed to encode integration chat image fixture.');
  }
  return _tempMediaFile(name, byteData.buffer.asUint8List());
}

Future<void> _openFirstConversation(WidgetTester tester) async {
  await tapItKey(tester, IntegrationTestKeys.navChat);
  expect(byItKey(IntegrationTestKeys.screenChat), findsOneWidget);

  final chatListing = await waitForSurfaceProbe(
    tester,
    'chat',
    (payload) =>
        payload['registered'] == true &&
        (payload['filteredCount'] as num? ?? 0) > 0,
    reason:
        'Chat media upload failure smoke requires at least one conversation.',
  );
  final chatIds = (chatListing['chatIds'] as List<dynamic>)
      .map((item) => item?.toString() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  await tapItKey(
    tester,
    IntegrationTestKeys.chatTile(chatIds.first),
    settlePumps: 10,
  );
  expect(byItKey(IntegrationTestKeys.screenChatConversation), findsOneWidget);
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
    'Chat media picker and upload failures are surfaced deterministically',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'chat_media_picker_upload_failure_e2e',
        tester,
        () async {
          IntegrationMediaTestHarness.reset();

          await launchTurqApp(tester);
          await expectFeedScreen(tester);
          await _openFirstConversation(tester);

          final imageFile = await _tempPngImageFile(
            'turqapp_media_failure_image.png',
          );
          final videoFile = _tempMediaFile(
            'turqapp_media_failure_video.mp4',
            const <int>[11, 12, 13, 14, 15],
          );

          IntegrationMediaTestHarness.queueFailure(
            IntegrationMediaFailureKind.pickerCancelled,
          );
          await _openAttachmentAction(
            tester,
            IntegrationTestKeys.actionChatAttachPhotos,
          );
          await waitForSurfaceProbe(
            tester,
            'chatConversation',
            (payload) => payload['lastMediaFailureCode'] == 'picker_cancelled',
            reason: 'Picker cancel did not surface picker_cancelled.',
          );

          IntegrationMediaTestHarness.queueFailure(
            IntegrationMediaFailureKind.pickerFailed,
          );
          await _openAttachmentAction(
            tester,
            IntegrationTestKeys.actionChatAttachVideos,
          );
          await waitForSurfaceProbe(
            tester,
            'chatConversation',
            (payload) => payload['lastMediaFailureCode'] == 'picker_failed',
            reason: 'Picker failure did not surface picker_failed.',
          );

          IntegrationMediaTestHarness.queueGalleryImageSelection([imageFile]);
          await _openAttachmentAction(
            tester,
            IntegrationTestKeys.actionChatAttachPhotos,
          );
          await waitForSurfaceProbe(
            tester,
            'chatConversation',
            (payload) => (payload['selectedImageCount'] as num? ?? 0) == 1,
            reason: 'Image selection was not queued before upload failure.',
          );

          IntegrationMediaTestHarness.queueFailure(
            IntegrationMediaFailureKind.imageUploadFailed,
          );
          await tapItKey(
            tester,
            IntegrationTestKeys.actionChatSend,
            settlePumps: 8,
          );
          await waitForSurfaceProbe(
            tester,
            'chatConversation',
            (payload) =>
                payload['lastMediaAction'] == 'upload_image' &&
                payload['lastMediaFailureCode'] == 'image_upload_failed' &&
                (payload['selectedImageCount'] as num? ?? 0) == 0,
            reason: 'Image upload failure did not clear selection cleanly.',
          );

          IntegrationMediaTestHarness.queueGalleryVideo(videoFile);
          await _openAttachmentAction(
            tester,
            IntegrationTestKeys.actionChatAttachVideos,
          );
          await waitForSurfaceProbe(
            tester,
            'chatConversation',
            (payload) => payload['hasPendingVideo'] == true,
            reason: 'Video selection was not queued before upload failure.',
          );

          IntegrationMediaTestHarness.queueFailure(
            IntegrationMediaFailureKind.videoUploadFailed,
          );
          await tapItKey(
            tester,
            IntegrationTestKeys.actionChatSend,
            settlePumps: 8,
          );
          await waitForSurfaceProbe(
            tester,
            'chatConversation',
            (payload) =>
                payload['lastMediaAction'] == 'upload_video' &&
                payload['lastMediaFailureCode'] == 'video_upload_failed' &&
                payload['hasPendingVideo'] == false,
            reason: 'Video upload failure did not clear pending video cleanly.',
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
            (payload) => payload['isRecording'] == true,
            reason: 'Voice recording did not start before upload failure.',
          );

          IntegrationMediaTestHarness.queueFailure(
            IntegrationMediaFailureKind.audioUploadFailed,
          );
          await tapItKey(
            tester,
            IntegrationTestKeys.actionChatRecordingSend,
            settlePumps: 8,
          );
          await waitForSurfaceProbe(
            tester,
            'chatConversation',
            (payload) =>
                payload['lastMediaAction'] == 'upload_audio' &&
                payload['lastMediaFailureCode'] == 'audio_upload_failed' &&
                payload['isRecording'] == false,
            reason: 'Audio upload failure did not stop recording cleanly.',
          );
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
