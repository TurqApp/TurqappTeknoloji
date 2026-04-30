import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Runtime/session_exit_coordinator.dart';

void main() {
  group('SessionExitCoordinator', () {
    test('clears local session, signs out auth, then navigates to sign in',
        () async {
      final events = <String>[];
      final coordinator = SessionExitCoordinator(
        clearLocalSession: () async {
          events.add('local');
        },
        signOutAuth: () async {
          events.add('auth');
        },
        navigateToSignIn: ({
          String initialIdentifier = '',
          String storedAccountUid = '',
        }) async {
          events.add('nav:$initialIdentifier:$storedAccountUid');
        },
      );

      final result = await coordinator.exitToSignIn(
        reason: SessionExitReason.accountDeleted,
        initialIdentifier: 'mail@example.com',
        storedAccountUid: 'uid-1',
      );

      expect(events, <String>[
        'local',
        'auth',
        'nav:mail@example.com:uid-1',
      ]);
      expect(result.reason, SessionExitReason.accountDeleted);
      expect(result.localSessionCleared, isTrue);
      expect(result.authSignedOut, isTrue);
      expect(result.navigatedToSignIn, isTrue);
    });

    test('can navigate without repeating local cleanup or auth sign out',
        () async {
      final events = <String>[];
      final coordinator = SessionExitCoordinator(
        clearLocalSession: () async {
          events.add('local');
        },
        signOutAuth: () async {
          events.add('auth');
        },
        navigateToSignIn: ({
          String initialIdentifier = '',
          String storedAccountUid = '',
        }) async {
          events.add('nav');
        },
      );

      final result = await coordinator.exitToSignIn(
        clearLocalSession: false,
        signOutAuth: false,
      );

      expect(events, <String>['nav']);
      expect(result.localSessionCleared, isFalse);
      expect(result.authSignedOut, isFalse);
      expect(result.navigatedToSignIn, isTrue);
    });

    test('passes sign-in navigation identifiers through unchanged', () async {
      var receivedIdentifier = '';
      var receivedStoredAccountUid = '';
      final coordinator = SessionExitCoordinator(
        clearLocalSession: () async {},
        signOutAuth: () async {},
        navigateToSignIn: ({
          String initialIdentifier = '',
          String storedAccountUid = '',
        }) async {
          receivedIdentifier = initialIdentifier;
          receivedStoredAccountUid = storedAccountUid;
        },
      );

      final result = await coordinator.exitToSignIn(
        reason: SessionExitReason.accountSwitched,
        initialIdentifier: ' mail@example.com ',
        storedAccountUid: ' uid-2 ',
        clearLocalSession: false,
        signOutAuth: false,
      );

      expect(receivedIdentifier, ' mail@example.com ');
      expect(receivedStoredAccountUid, ' uid-2 ');
      expect(result.reason, SessionExitReason.accountSwitched);
      expect(result.navigatedToSignIn, isTrue);
    });

    test('profile settings exit flows stay behind coordinator boundary', () {
      final settingsSource = File(
        'lib/Modules/Profile/Settings/settings_sections_tasks_part.dart',
      ).readAsStringSync();
      final accountCenterSource = File(
        'lib/Modules/Profile/Settings/account_center_view_accounts_part.dart',
      ).readAsStringSync();
      final deleteAccountSource = File(
        'lib/Modules/Profile/DeleteAccount/delete_account_actions_part.dart',
      ).readAsStringSync();

      expect(settingsSource, contains('SessionExitCoordinator'));
      expect(settingsSource, isNot(contains('AppRootNavigationService')));
      expect(accountCenterSource, contains('SessionExitCoordinator'));
      expect(
        accountCenterSource,
        contains('_accountSwitchExitCoordinator().exitToSignIn'),
      );
      expect(accountCenterSource, isNot(contains('AppRootNavigationService')));
      expect(deleteAccountSource, contains('SessionExitCoordinator'));
      expect(deleteAccountSource, isNot(contains('AppRootNavigationService')));
    });

    test('feature code does not navigate to sign in outside exit coordinator',
        () async {
      const approvedDirectNavigationFiles = <String>{
        'lib/Runtime/session_exit_coordinator.dart',
        'lib/Modules/Splash/splash_view_startup_part.dart',
        'lib/Services/current_user_service_lifecycle_part.dart',
      };
      final violations = <String>[];

      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final normalizedPath = file.path.replaceAll('\\', '/');
        if (approvedDirectNavigationFiles.contains(normalizedPath)) continue;
        final source = await file.readAsString();
        if (source.contains('AppRootNavigationService.offAllToSignIn')) {
          violations.add(normalizedPath);
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Feature/session exit flows should use SessionExitCoordinator; '
            'Splash and CurrentUserService lifecycle are approved low-level '
            'startup/session boundaries.',
      );
    });
  });
}
