import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_maker_controller.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_model.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_application_service.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_user_model.dart';

void main() {
  group('StoryRowApplicationService', () {
    test('buildBootstrapPlan refreshes when row is empty', () {
      final service = StoryRowApplicationService();
      final plan = service.buildBootstrapPlan(
        hasUsers: false,
        shouldSilentRefresh: false,
      );

      expect(plan.shouldSilentRefresh, isTrue);
    });

    test('shouldRunExpireCleanup respects interval', () {
      final service = StoryRowApplicationService();
      final now = DateTime(2026, 3, 28, 12);

      expect(
        service.shouldRunExpireCleanup(
          lastCleanupAt: now.subtract(const Duration(minutes: 20)),
          now: now,
          interval: const Duration(minutes: 15),
        ),
        isTrue,
      );
      expect(
        service.shouldRunExpireCleanup(
          lastCleanupAt: now.subtract(const Duration(minutes: 5)),
          now: now,
          interval: const Duration(minutes: 15),
        ),
        isFalse,
      );
    });

    test('buildOrderedUsers keeps self first and unseen stories ahead of seen',
        () {
      final service = StoryRowApplicationService();
      final ordered = service.buildOrderedUsers(
        fetchedUsers: <StoryUserModel>[
          _user('u2', minutesAgo: 20),
          _user('u3', minutesAgo: 10),
        ],
        currentUid: 'u1',
        currentUserStory: _user('u1', minutesAgo: 5),
        isAllSeen: (user) => user.userID == 'u2',
      );

      expect(ordered.map((user) => user.userID).toList(),
          <String>['u1', 'u3', 'u2']);
    });

    test(
        'story row controller delegates bootstrap and ordering to application service',
        () {
      final source = File(
        '/Users/turqapp/Desktop/TurqApp/lib/Modules/Story/StoryRow/story_row_controller_load_part.dart',
      ).readAsStringSync();

      expect(
          source, contains('_storyRowApplicationService.buildBootstrapPlan'));
      expect(source,
          contains('_storyRowApplicationService.shouldRunExpireCleanup'));
      expect(source, contains('_storyRowApplicationService.buildOrderedUsers'));
      expect(
          source,
          isNot(contains(
              'final unseen = tempList.where((u) => !allSeen(u)).toList()')));
    });
  });
}

StoryUserModel _user(
  String userId, {
  required int minutesAgo,
}) {
  return StoryUserModel(
    nickname: userId,
    avatarUrl: 'https://cdn.turq.app/$userId.webp',
    fullName: userId,
    userID: userId,
    stories: <StoryModel>[
      StoryModel(
        id: 'story-$userId',
        userId: userId,
        createdAt:
            DateTime(2026, 3, 28, 12).subtract(Duration(minutes: minutesAgo)),
        backgroundColor: const Color(0xFFFFFFFF),
        musicId: '',
        musicUrl: '',
        musicTitle: '',
        musicArtist: '',
        musicCoverUrl: '',
        hlsVideoUrl: '',
        elements: const <StoryElement>[],
      ),
    ],
  );
}
