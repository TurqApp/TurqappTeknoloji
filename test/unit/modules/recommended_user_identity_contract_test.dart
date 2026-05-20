import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recommended user cards keep tap and controller identity in sync',
      () async {
    final listSource = await File(
      'lib/Modules/RecommendedUserList/recommended_user_list.dart',
    ).readAsString();
    final cardSource = await File(
      'lib/Modules/RecommendedUserList/RecommendedUserContent/'
      'recommended_user_content.dart',
    ).readAsString();

    expect(
      listSource,
      contains("ValueKey('recommended_user_\${model.userID}')"),
    );
    expect(cardSource, contains('void didUpdateWidget'));
    expect(cardSource, contains('oldWidget.model.userID == model.userID'));
    expect(cardSource, contains('openSocialProfile(model.userID)'));
    expect(cardSource, isNot(contains('openSocialProfile(controller.userID)')));
  });
}
