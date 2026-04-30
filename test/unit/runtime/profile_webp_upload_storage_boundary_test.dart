import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile image upload surfaces delegate storage to WebpUploadService',
      () async {
    final checkedSources = <String, String>{
      'edit profile controller':
          'lib/Modules/Profile/EditProfile/edit_profile_controller.dart',
      'edit profile actions':
          'lib/Modules/Profile/EditProfile/edit_profile_controller_actions_part.dart',
      'cv controller': 'lib/Modules/Profile/Cv/cv_controller.dart',
      'cv profile': 'lib/Modules/Profile/Cv/cv_controller_profile_part.dart',
      'social media links controller':
          'lib/Modules/Profile/SocialMediaLinks/social_media_links_controller_library.dart',
      'social media links runtime':
          'lib/Modules/Profile/SocialMediaLinks/social_media_links_controller_runtime_part.dart',
      'story music admin':
          'lib/Modules/Profile/Settings/story_music_admin_view.dart',
      'story music admin actions':
          'lib/Modules/Profile/Settings/story_music_admin_view_actions_part.dart',
    };

    final combinedSources = StringBuffer();
    for (final sourcePath in checkedSources.values) {
      combinedSources.writeln(await File(sourcePath).readAsString());
    }
    final source = combinedSources.toString();

    expect(source, contains('WebpUploadService.upload'));
    expect(source, contains('users/\$uid/\$fileBase'));
    expect(source, contains('users/\$uid/cv/profile_photo'));
    expect(source, contains('users/\$currentUid/social_links/\$docID'));
    expect(source, contains('storyMusic/\$itemId/cover'));
    expect(source, isNot(contains('storage: AppFirebaseStorage.instance')));
    expect(
      source,
      isNot(contains('AppFirebaseStorage.instance,\n')),
    );
  });
}
