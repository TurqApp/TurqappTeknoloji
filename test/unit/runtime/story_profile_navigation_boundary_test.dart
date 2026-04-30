import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Story profile opens stay behind profile navigation service', () async {
    final checkedSources = <String, String>{
      'story elements': 'lib/Modules/Story/StoryViewer/story_elements.dart',
      'user story content':
          'lib/Modules/Story/StoryViewer/user_story_content.dart',
      'user story content view':
          'lib/Modules/Story/StoryViewer/user_story_content_view_part.dart',
      'story comment user':
          'lib/Modules/Story/StoryViewer/StoryComments/StoryCommentUser/story_comment_user.dart',
      'story content profiles':
          'lib/Modules/Story/StoryViewer/StoryContentProfiles/story_content_profiles.dart',
    };

    final combinedSources = StringBuffer();
    for (final sourcePath in checkedSources.values) {
      combinedSources.writeln(await File(sourcePath).readAsString());
    }
    final source = combinedSources.toString();

    expect(source, contains('ProfileNavigationService'));
    expect(source, contains('openSocialProfile'));
    expect(source, contains('_pauseCurrentStoryPlayback()'));
    expect(source, contains('_resumeCurrentStoryPlayback()'));
    expect(source, contains('widget.model.userID != _currentUserId'));
    expect(source, contains('widget.userID != _currentUserId'));
    expect(source, isNot(contains('Get.to(() => SocialProfile')));
    expect(source, isNot(contains('Get.to(SocialProfile')));
    expect(
      source,
      isNot(contains('Modules/SocialProfile/social_profile.dart')),
    );
    expect(
      source,
      isNot(contains('../../../../SocialProfile/social_profile.dart')),
    );
  });
}
