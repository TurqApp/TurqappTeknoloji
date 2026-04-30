import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile and agenda chat listing opens stay behind navigation service',
      () async {
    final checkedSources = <String, String>{
      'profile shell':
          'lib/Modules/Profile/MyProfile/profile_view_shell_content_part.dart',
      'profile view': 'lib/Modules/Profile/MyProfile/profile_view.dart',
      'agenda header': 'lib/Modules/Agenda/agenda_view_header_part.dart',
      'agenda view': 'lib/Modules/Agenda/agenda_view.dart',
    };

    final combinedSources = StringBuffer();
    for (final entry in checkedSources.entries) {
      final source = await File(entry.value).readAsString();
      combinedSources.writeln(source);
      if (entry.key.endsWith('shell') || entry.key.endsWith('header')) {
        expect(
          source,
          contains('openChatListing()'),
          reason: '${entry.key} should delegate chat listing navigation.',
        );
      }
    }

    final source = combinedSources.toString();
    expect(source, contains('ChatNavigationService'));
    expect(source, isNot(contains('Get.to(() => ChatListing')));
    expect(
      source,
      isNot(contains('Modules/Chat/ChatListing/chat_listing.dart')),
    );
  });
}
