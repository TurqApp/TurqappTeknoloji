import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('post sharer, like, and reshare profile opens stay behind service',
      () async {
    final checkedSources = <String, String>{
      'post sharers': 'lib/Modules/Social/PostSharers/post_sharers.dart',
      'post sharer tile':
          'lib/Modules/Social/PostSharers/post_sharers_tile_part.dart',
      'post like':
          'lib/Modules/Agenda/PostLikeListing/PostLikeContent/post_like_content.dart',
      'post reshare':
          'lib/Modules/Agenda/PostReshareListing/PostReshareContent/post_reshare_content.dart',
    };

    final combinedSources = StringBuffer();
    for (final sourcePath in checkedSources.values) {
      combinedSources.writeln(await File(sourcePath).readAsString());
    }
    final source = combinedSources.toString();

    expect(source, contains('ProfileNavigationService'));
    expect(source, contains('openSocialProfile'));
    expect(source, contains('openMyProfile'));
    expect(source, contains('_refreshFollowState()'));
    expect(source, isNot(contains('Get.to(() => SocialProfile')));
    expect(source, isNot(contains('Get.to(() => const ProfileView')));
    expect(
      source,
      isNot(contains('Modules/SocialProfile/social_profile.dart')),
    );
    expect(
      source,
      isNot(contains('Modules/Profile/MyProfile/profile_view.dart')),
    );
  });
}
