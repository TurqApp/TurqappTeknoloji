import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('market detail seller and chat opens stay behind navigation services',
      () async {
    final source = await File(
      'lib/Modules/Market/market_detail_view_content_part.dart',
    ).readAsString();
    final marketDetailSource = await File(
      'lib/Modules/Market/market_detail_view.dart',
    ).readAsString();

    expect(source, contains('ProfileNavigationService'));
    expect(source, contains('ChatNavigationService'));
    expect(source, contains('openSocialProfile(item.userId)'));
    expect(source, contains('openChatListing()'));
    expect(source, isNot(contains('Get.to(() => SocialProfile')));
    expect(source, isNot(contains('Get.to(() => ChatListing')));
    expect(
      marketDetailSource,
      isNot(contains('Modules/SocialProfile/social_profile.dart')),
    );
    expect(
      marketDetailSource,
      isNot(contains('Modules/Chat/ChatListing/chat_listing.dart')),
    );
  });
}
