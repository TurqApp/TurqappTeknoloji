import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('direct AppFirebaseStorage use stays in approved upload owners',
      () async {
    const approvedOwners = <String>{
      'lib/Core/Slider/slider_admin_view_actions_part.dart',
      'lib/Modules/Chat/chat_controller_media_part.dart',
      'lib/Modules/EditPost/edit_post_controller_actions_part.dart',
      'lib/Modules/PostCreator/post_creator_controller_publish_part.dart',
      'lib/Modules/PostCreator/post_creator_controller_publish_upload_part.dart',
      'lib/Modules/Profile/EditProfile/edit_profile_controller_actions_part.dart',
      'lib/Modules/Story/StoryMaker/story_maker_controller_save_part.dart',
    };

    final roots = <String>[
      'lib/Core/Slider',
      'lib/Modules',
    ];
    final violations = <String>[];

    for (final root in roots) {
      final files = Directory(root)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in files) {
        final normalizedPath = file.path.replaceAll('\\', '/');
        final source = await file.readAsString();
        if (!source.contains('AppFirebaseStorage.instance')) continue;
        if (approvedOwners.contains(normalizedPath)) continue;
        violations.add(normalizedPath);
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'New direct module/Core Slider storage ownership should go '
          'through WebpUploadService, repositories, or an approved upload '
          'boundary instead of spreading AppFirebaseStorage.instance.',
    );
  });
}
