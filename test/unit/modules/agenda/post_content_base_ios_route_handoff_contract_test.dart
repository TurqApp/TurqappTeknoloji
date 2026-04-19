import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'iOS route push stops primary feed playback instead of leaving pause-only handoff',
      () async {
    final source = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/Common/post_content_base_lifecycle_part.dart',
    ).readAsString();

    expect(
      source,
      contains("source: 'did_push_next'"),
    );
    expect(
      source,
      contains('defaultTargetPlatform == TargetPlatform.iOS'),
    );
    expect(
      source,
      contains('_isPrimaryFeedSurfaceInstance'),
    );
    expect(
      source,
      contains('_playbackRuntimeService.requestStop(playbackHandleKey);'),
    );
    expect(
      source,
      contains('_stopPlaybackForSurfaceLoss();'),
    );
  });

  test('iOS primary feed can restart a stopped inline owner after route return',
      () async {
    final source = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/Common/post_content_base_playback_part.dart',
    ).readAsString();

    expect(source, contains('feed_card_resume_stopped_restart'));
    expect(source, contains('adapter.isStopped'));
    expect(
      source,
      contains('defaultTargetPlatform == TargetPlatform.iOS'),
    );
    expect(
      source,
      contains('_isPrimaryFeedSurfaceInstance'),
    );
    expect(
      source,
      contains(
          "_startPlaybackWhenReady(source: '\$source:resume_stopped_restart');"),
    );
  });
}
