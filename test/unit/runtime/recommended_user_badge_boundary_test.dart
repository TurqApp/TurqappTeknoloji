import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recommended user cards render only sanitized badge values', () async {
    final source = await File(
      '/Users/turqapp/Documents/Turqapp/repo/lib/Modules/RecommendedUserList/RecommendedUserContent/recommended_user_content.dart',
    ).readAsString();

    expect(source, contains('userID: model.userID'));
    expect(source, contains('rozetValue: model.rozet'));
  });
}
