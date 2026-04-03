import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('story viewer and widget keep video prefetch hooks in place', () async {
    final viewerSource = await File(
      '/Users/turqapp/Documents/Turqapp/repo/lib/Modules/Story/StoryViewer/story_viewer_story_part.dart',
    ).readAsString();
    final storyContentSource = await File(
      '/Users/turqapp/Documents/Turqapp/repo/lib/Modules/Story/StoryViewer/user_story_content_playback_part.dart',
    ).readAsString();
    final storyVideoSource = await File(
      '/Users/turqapp/Documents/Turqapp/repo/lib/Modules/Story/StoryViewer/story_video_widget.dart',
    ).readAsString();

    expect(viewerSource, contains('cacheHlsEntry('));
    expect(viewerSource, contains('boostDoc('));
    expect(
      storyContentSource,
      contains('_prefetchNextStoryVideoWithinCurrentUser'),
    );
    expect(storyContentSource, contains('boostDoc('));
    expect(storyVideoSource, contains('claimExternalOnDemandFetch('));
    expect(storyVideoSource, contains('releaseExternalOnDemandFetch('));
    expect(storyVideoSource, contains('resolveUrl('));
  });
}
