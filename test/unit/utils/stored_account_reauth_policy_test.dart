import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Utils/stored_account_reauth_policy.dart';
import 'package:turqappv2/Models/stored_account.dart';

void main() {
  StoredAccount buildAccount(List<String> providers) => StoredAccount(
        uid: 'user_1',
        email: 'user_1@mail.com',
        username: 'user_1',
        displayName: 'User One',
        rozet: '',
        avatarUrl: '',
        providers: providers,
        lastUsedAt: 1,
        isSessionValid: true,
        requiresReauth: false,
        accountState: 'active',
        isPinned: false,
        sortOrder: 1,
        lastSuccessfulSignInAt: 10,
      );

  test('password provider hesaplar manuel reauth ister', () {
    expect(
      requiresManualStoredAccountReauth(
        buildAccount(const <String>['password']),
      ),
      isTrue,
    );
  });

  test('sifre disi provider hesaplar manuel reauth istemez', () {
    expect(
      requiresManualStoredAccountReauth(
        buildAccount(const <String>['google.com']),
      ),
      isFalse,
    );
  });
}
