import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat profile opens stay behind ProfileNavigationService', () async {
    final checkedSources = <String, String>{
      'chat listing content':
          'lib/Modules/Chat/ChatListingContent/chat_listing_content.dart',
      'chat listing avatar':
          'lib/Modules/Chat/ChatListingContent/chat_listing_content_view_part.dart',
      'chat view': 'lib/Modules/Chat/chat.dart',
      'chat header': 'lib/Modules/Chat/chat_body_part.dart',
      'message content': 'lib/Modules/Chat/MessageContent/message_content.dart',
      'message mentions':
          'lib/Modules/Chat/MessageContent/message_content_text_part.dart',
    };

    final combinedSources = StringBuffer();
    for (final sourcePath in checkedSources.values) {
      combinedSources.writeln(await File(sourcePath).readAsString());
    }
    final source = combinedSources.toString();

    expect(source, contains('ProfileNavigationService'));
    expect(source, contains('openSocialProfile'));
    expect(source, contains('UsernameLookupRepository.ensure()'));
    expect(source, isNot(contains('Get.to(() => SocialProfile')));
    expect(
      source,
      isNot(contains('Modules/SocialProfile/social_profile.dart')),
    );
    expect(source, isNot(contains('../../SocialProfile/social_profile.dart')));
  });
}
