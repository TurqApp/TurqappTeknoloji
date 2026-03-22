import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Models/stored_account.dart';

void main() {
  test('StoredAccount.fromJson parses session flags and normalizes email', () {
    final account = StoredAccount.fromJson(<String, dynamic>{
      'uid': 'user_1',
      'email': '  TEST@MAIL.COM ',
      'providers': <String>['google.com', 'password'],
      'isSessionValid': false,
      'requiresReauth': true,
      'accountState': 'reauth_required',
    });

    expect(account.uid, 'user_1');
    expect(account.email, 'test@mail.com');
    expect(account.hasPasswordProvider, isTrue);
    expect(account.isSessionValid, isFalse);
    expect(account.requiresReauth, isTrue);
    expect(account.accountState, 'reauth_required');
  });

  test('StoredAccount encode/decode round-trip preserves valid entries only',
      () {
    final encoded = StoredAccount.encodeList([
      const StoredAccount(
        uid: 'user_1',
        email: 'user_1@mail.com',
        username: 'user_1',
        displayName: 'User One',
        rozet: '',
        avatarUrl: '',
        providers: <String>['password'],
        lastUsedAt: 1,
        isSessionValid: true,
        requiresReauth: false,
        accountState: 'active',
        isPinned: false,
        sortOrder: 1,
        lastSuccessfulSignInAt: 10,
      ),
      const StoredAccount(
        uid: '',
        email: '',
        username: '',
        displayName: '',
        rozet: '',
        avatarUrl: '',
        providers: <String>[],
        lastUsedAt: 0,
        isSessionValid: false,
        requiresReauth: false,
        accountState: 'active',
        isPinned: false,
        sortOrder: 0,
        lastSuccessfulSignInAt: 0,
      ),
    ]);

    final decoded = StoredAccount.decodeList(encoded);

    expect(decoded, hasLength(1));
    expect(decoded.single.uid, 'user_1');
    expect(decoded.single.primaryProvider, 'password');
  });
}
