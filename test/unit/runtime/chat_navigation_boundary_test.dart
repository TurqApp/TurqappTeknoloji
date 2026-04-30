import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tutoring chat listing opens stay behind navigation service', () async {
    final serviceSource = await File(
      'lib/Core/Services/chat_navigation_service.dart',
    ).readAsString();
    final tutoringDetailSource = await File(
      'lib/Modules/Education/Tutoring/TutoringDetail/'
      'tutoring_detail_body_part.dart',
    ).readAsString();

    expect(serviceSource, contains('openChatListing'));
    expect(serviceSource, contains('ChatListing()'));
    expect(tutoringDetailSource, contains('openChatListing()'));
    expect(
      tutoringDetailSource,
      isNot(contains('Get.to(() => ChatListing')),
    );
  });
}
