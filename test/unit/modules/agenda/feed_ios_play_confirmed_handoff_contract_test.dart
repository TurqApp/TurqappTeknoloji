import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'iOS feed finalizes owner handoff when the target actually starts playing',
      () async {
    final source = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/Common/post_content_base_lifecycle_part.dart',
    ).readAsString();

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
      contains('(v.isPlaying || v.hasVisibleVideoFrame)'),
    );
    expect(
      source,
      contains('_playbackRuntimeService.playOnlyThis(playbackHandleKey);'),
    );
  });
}
