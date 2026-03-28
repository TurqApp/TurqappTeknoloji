import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Models/stored_account.dart';
import 'package:turqappv2/Modules/SignIn/sign_in_application_service.dart';
import 'package:turqappv2/Services/account_session_vault.dart';

void main() {
  group('SignInApplicationService', () {
    const passwordAccount = StoredAccount(
      uid: 'user-1',
      email: '',
      username: 'osman',
      displayName: 'Osman',
      rozet: '',
      avatarUrl: '',
      providers: <String>['password'],
      lastUsedAt: 0,
      isSessionValid: true,
      requiresReauth: false,
      accountState: 'active',
      isPinned: false,
      sortOrder: 0,
      lastSuccessfulSignInAt: 0,
    );

    test('preferredIdentifierForStoredAccount uses stored email hint', () async {
      final service = SignInApplicationService(
        readStoredCredential: (_) async => const AccountSessionCredential(
          email: 'osman@example.com',
          password: '',
        ),
      );

      final identifier =
          await service.preferredIdentifierForStoredAccount(passwordAccount);

      expect(identifier, 'osman@example.com');
    });

    test('continueWithStoredAccount returns selected account context', () async {
      final account = passwordAccount.copyWith(email: 'dev@turq.app');
      final service = SignInApplicationService();

      final context = await service.continueWithStoredAccount(account);

      expect(context.account.uid, account.uid);
      expect(context.identifier, 'dev@turq.app');
    });

    test('signInWithStoredAccount marks reauth requirement', () async {
      String? capturedUid;
      bool? capturedSessionValid;
      bool? capturedRequiresReauth;
      final service = SignInApplicationService(
        markSessionState: ({
          required String uid,
          required bool isSessionValid,
          bool? requiresReauth,
        }) async {
          capturedUid = uid;
          capturedSessionValid = isSessionValid;
          capturedRequiresReauth = requiresReauth;
        },
      );

      final result = await service.signInWithStoredAccount(passwordAccount);

      expect(result, isFalse);
      expect(capturedUid, 'user-1');
      expect(capturedSessionValid, isFalse);
      expect(capturedRequiresReauth, isTrue);
    });

    test('signInWithPassword delegates orchestration to application service', () async {
      final steps = <String>[];
      final service = SignInApplicationService(
        passwordSignIn: ({
          required String email,
          required String password,
        }) async {
          steps.add('auth:$email:$password');
        },
        authUserIdProvider: () => 'uid-123',
        beginSessionClaim: (uid) => steps.add('claim:$uid'),
        registerCurrentDeviceSession: () async {
          steps.add('register-device');
        },
        schedulePostAuthTasks: (email) async {
          steps.add('post-auth:$email');
        },
      );

      final result = await service.signInWithPassword(
        email: 'osman@example.com',
        password: 'secret',
      );

      expect(result.isSuccess, isTrue);
      expect(
        steps,
        <String>[
          'auth:osman@example.com:secret',
          'claim:uid-123',
          'register-device',
          'post-auth:osman@example.com',
        ],
      );
    });

    test('controller sign-in methods delegate to application service layer', () {
      final authSource = File(
        '/Users/turqapp/Desktop/TurqApp/lib/Modules/SignIn/sign_in_controller_auth_part.dart',
      ).readAsStringSync();
      final accountSource = File(
        '/Users/turqapp/Desktop/TurqApp/lib/Modules/SignIn/sign_in_controller_account_part.dart',
      ).readAsStringSync();

      expect(
        authSource,
        contains('_signInApplicationService.signInWithPassword'),
      );
      expect(
        authSource,
        contains('_signInApplicationService.signInWithStoredAccount'),
      );
      expect(
        accountSource,
        contains('_signInApplicationService.continueWithStoredAccount'),
      );
      expect(
        accountSource,
        contains('_signInApplicationService.preferredIdentifierForStoredAccount'),
      );
    });
  });
}
