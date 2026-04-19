import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Runtime/startup_session_failure.dart';
import 'package:turqappv2/Services/current_user_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('current user service library declares explicit role parts', () async {
    final source = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Services/current_user_service.dart',
    ).readAsString();

    expect(
        source, contains("part 'current_user_service_auth_role_part.dart';"));
    expect(
        source, contains("part 'current_user_service_cache_role_part.dart';"));
    expect(
        source, contains("part 'current_user_service_sync_role_part.dart';"));
    expect(
      source,
      contains("part 'current_user_service_account_center_role_part.dart';"),
    );
  });

  test('auth and cache roles expose stable signed-out defaults', () async {
    final service = CurrentUserService.instance;
    await service.logout();

    final authRole = CurrentUserAuthRole(
      service,
      currentAuthUserProvider: () => null,
      authStateChangesProvider: () => const Stream<User?>.empty(),
    );
    final cacheRole = CurrentUserCacheStore(service);

    expect(authRole.hasAuthUser(), isFalse);
    expect(authRole.authUserId(), isEmpty);
    expect(authRole.effectiveUserId(), isEmpty);
    expect(cacheRole.cacheKey('uid-1'), 'cached_current_user_uid-1');
    expect(
      cacheRole.cacheTimestampKey('uid-1'),
      'cached_current_user_timestamp_uid-1',
    );
    expect(cacheRole.resolveCacheUid('uid-1'), 'uid-1');
  });

  test('sync and account-center roles are constructible from service',
      () async {
    final service = CurrentUserService.instance;

    final syncRole = CurrentUserSyncRole(service);
    final accountCenterRole = CurrentUserAccountCenterRole(service);

    expect(syncRole, isA<CurrentUserSyncRole>());
    expect(accountCenterRole, isA<CurrentUserAccountCenterRole>());
  });

  test('auth role records classified auth-state restore failures', () async {
    final failures = <StartupSessionFailure>[];
    final service = CurrentUserService.instance;
    final authRole = CurrentUserAuthRole(
      service,
      currentAuthUserProvider: () => null,
      authStateChangesProvider: () =>
          Stream<User?>.error(StateError('auth-stream-failed')),
      failureReporter: StartupSessionFailureReporter(onFailure: failures.add),
    );

    final resolved = await authRole.resolveAuthUser(
      waitForAuthState: true,
      timeout: const Duration(milliseconds: 10),
    );

    expect(resolved, isNull);
    expect(failures, isNotEmpty);
    expect(
      failures.first.kind,
      StartupSessionFailureKind.authStateRestore,
    );
  });

  test('auth role can suppress expected auth-state timeout noise', () async {
    final failures = <StartupSessionFailure>[];
    final service = CurrentUserService.instance;
    final authRole = CurrentUserAuthRole(
      service,
      currentAuthUserProvider: () => null,
      authStateChangesProvider: () =>
          Stream<User?>.periodic(const Duration(seconds: 1), (_) => null),
      failureReporter: StartupSessionFailureReporter(onFailure: failures.add),
    );

    final resolved = await authRole.resolveAuthUser(
      waitForAuthState: true,
      timeout: const Duration(milliseconds: 10),
      recordTimeoutFailure: false,
    );

    expect(resolved, isNull);
    expect(failures, isEmpty);
  });
}
