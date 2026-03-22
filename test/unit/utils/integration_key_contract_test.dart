import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String relativePath) {
  return File(relativePath).readAsStringSync();
}

String _readAllDart(String rootPath) {
  final buffer = StringBuffer();
  for (final entity in Directory(rootPath).listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    buffer.writeln(entity.readAsStringSync());
  }
  return buffer.toString();
}

void main() {
  test('critical screen roots expose integration keys', () {
    final splashSource =
        _read('lib/Modules/Splash/splash_view_intro_part.dart');
    final signInSource = _read('lib/Modules/SignIn/sign_in.dart');

    expect(
      splashSource,
      contains('IntegrationTestKeys.screenSplash'),
    );
    expect(
      signInSource,
      contains('IntegrationTestKeys.screenSignIn'),
    );
  });

  test('market top actions use real widget keys, not semantics only', () {
    final source =
        _read('lib/Modules/Education/widgets/market_top_action_button.dart');

    expect(
      source,
      contains(
        "key: semanticsLabel == null ? null : ValueKey<String>(semanticsLabel)",
      ),
    );
  });

  test('deep integration key surfaces are exercised by tests', () {
    final integrationSources = _readAllDart('integration_test');

    for (final expected in <String>[
      'IntegrationTestKeys.profileFollowersCounter',
      'IntegrationTestKeys.profileFollowingCounter',
      'IntegrationTestKeys.screenFollowingFollowers',
      'IntegrationTestKeys.actionSettingsSignOut',
      'IntegrationTestKeys.actionPostCreatorPublish',
      'IntegrationTestKeys.screenSingleShort',
      'IntegrationTestKeys.screenSinglePost',
      'IntegrationTestKeys.screenChatConversation',
      'IntegrationTestKeys.screenSocialProfile',
      'IntegrationTestKeys.screenMarketDetail',
      'IntegrationTestKeys.screenJobDetail',
      'IntegrationTestKeys.screenScholarshipDetail',
      'IntegrationTestKeys.screenPracticeExamPreview',
      'IntegrationTestKeys.marketTopActionViewMode',
      'IntegrationTestKeys.marketTopActionSort',
      'IntegrationTestKeys.marketTopActionFilter',
      'IntegrationTestKeys.actionChatAttach',
      'IntegrationTestKeys.actionChatGifPicker',
      'IntegrationTestKeys.actionChatCamera',
      'IntegrationTestKeys.actionChatSend',
      'IntegrationTestKeys.actionChatMic',
      'IntegrationTestKeys.actionStoryOpenComments',
      'IntegrationTestKeys.inputStoryComment',
      'IntegrationTestKeys.actionStoryCommentSend',
      "it-comment-item-",
      "it-comment-reply-",
      "it-comment-delete-",
      "it-comment-like-",
      "it-chat-tile-",
      "it-notification-item-",
      "it-story-reaction-",
      "it-market-item-",
      "it-job-item-",
      "it-scholarship-item-",
      "it-practice-exam-open-",
      "it-question-bank-category-",
    ]) {
      expect(
        integrationSources,
        contains(expected),
        reason: 'Missing integration coverage marker for $expected',
      );
    }
  });

  test('feed smoke tests use shared screenFeed key contract', () {
    final blackFlashSource =
        _read('integration_test/feed/feed_black_flash_smoke_test.dart');
    final nativeTruthSource = _read(
      'integration_test/feed/feed_native_exoplayer_truth_smoke_test.dart',
    );

    expect(
      blackFlashSource,
      contains('IntegrationTestKeys.screenFeed'),
    );
    expect(
      nativeTruthSource,
      contains('IntegrationTestKeys.screenFeed'),
    );
    expect(blackFlashSource, isNot(contains("byItKey('it-screen-feed')")));
    expect(nativeTruthSource, isNot(contains("byItKey('it-screen-feed')")));
  });
}
