import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('story viewer and widget keep video prefetch hooks in place', () async {
    final root = Directory.current.path;
    final viewerSource = await File(
      '$root/lib/Modules/Story/StoryViewer/story_viewer_story_part.dart',
    ).readAsString();
    final storyContentSource = await File(
      '$root/lib/Modules/Story/StoryViewer/user_story_content_playback_part.dart',
    ).readAsString();
    final storyVideoSource = await File(
      '$root/lib/Modules/Story/StoryViewer/story_video_widget.dart',
    ).readAsString();

    expect(viewerSource, contains('cacheHlsEntry('));
    expect(viewerSource, contains('boostDoc('));
    expect(
      storyContentSource,
      contains('_prefetchNextStoryVideoWithinCurrentUser'),
    );
    expect(storyContentSource, contains('boostDoc('));
    expect(storyVideoSource, contains('claimExternalOnDemandFetchForDoc('));
    expect(
      storyVideoSource,
      contains('releaseExternalOnDemandFetchForDoc('),
    );
    expect(storyVideoSource, contains('canonicalizeHlsCdnUrl('));
  });
}
