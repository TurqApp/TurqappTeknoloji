import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Models/current_user_model.dart';

void main() {
  test('fromJson parses nickname field', () {
    final json = {'nickname': 'Ali'};

    final user = CurrentUserModel.fromJson(json);

    expect(user.nickname, 'Ali');
  });

  test('toCacheJson strips device and token fields from local cache payload', () {
    final user = CurrentUserModel.fromJson(const {
      'userID': 'user-1',
      'nickname': 'turq',
      'email': 'turq@example.com',
      'token': 'fcm-token',
      'device': 'ios',
      'deviceID': 'device-123',
      'deviceVersion': '18.0',
      'bio': 'Merhaba',
    });

    final cacheJson = user.toCacheJson();

    expect(cacheJson['userID'], 'user-1');
    expect(cacheJson['nickname'], 'turq');
    expect(cacheJson['email'], 'turq@example.com');
    expect(cacheJson['bio'], 'Merhaba');
    expect(cacheJson.containsKey('token'), isFalse);
    expect(cacheJson.containsKey('device'), isFalse);
    expect(cacheJson.containsKey('deviceID'), isFalse);
    expect(cacheJson.containsKey('deviceVersion'), isFalse);
  });

  test('fromJson tolerates redacted cache payloads', () {
    final user = CurrentUserModel.fromJson(const {
      'userID': 'user-2',
      'nickname': 'turqapp',
      'email': 'hello@example.com',
    });

    final cachedUser = CurrentUserModel.fromJson(user.toCacheJson());

    expect(cachedUser.userID, 'user-2');
    expect(cachedUser.nickname, 'turqapp');
    expect(cachedUser.email, 'hello@example.com');
    expect(cachedUser.token, isEmpty);
    expect(cachedUser.device, isEmpty);
    expect(cachedUser.deviceID, isEmpty);
    expect(cachedUser.deviceVersion, isEmpty);
  });

  test('fromJson ignores legacy cached password values', () {
    final user = CurrentUserModel.fromJson(const {
      'userID': 'user-3',
      'nickname': 'legacy-user',
      'sifre': 'plaintext-should-not-load',
    });

    expect(user.userID, 'user-3');
    expect(user.nickname, 'legacy-user');
    expect(user.sifre, isEmpty);
  });
}
