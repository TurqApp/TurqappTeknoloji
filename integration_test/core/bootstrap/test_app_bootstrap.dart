import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:turqappv2/Core/Repositories/feed_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/market_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/integration_test_fixture_contract.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Repositories/notifications_snapshot_repository.dart';
import 'package:turqappv2/Models/stored_account.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_view.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/account_session_vault.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/device_session_service.dart';
import 'package:turqappv2/main.dart' as app;

import '../helpers/transient_error_policy.dart';

const bool kRunIntegrationSmoke =
    bool.fromEnvironment('RUN_INTEGRATION_SMOKE', defaultValue: false);
const String kIntegrationLoginEmail =
    String.fromEnvironment('INTEGRATION_LOGIN_EMAIL', defaultValue: '');
const String kIntegrationLoginPassword =
    String.fromEnvironment('INTEGRATION_LOGIN_PASSWORD', defaultValue: '');

AccountSessionCredential? _cachedIntegrationCredential;

String _redactEmail(String email) {
  final normalized = email.trim();
  final atIndex = normalized.indexOf('@');
  if (atIndex <= 1) return '<redacted>';
  return '${normalized.substring(0, 1)}***${normalized.substring(atIndex)}';
}

IntegrationTestWidgetsFlutterBinding ensureIntegrationBinding() {
  Get.testMode = true;
  return IntegrationTestWidgetsFlutterBinding.ensureInitialized();
}

Future<void> launchTurqApp(WidgetTester tester) async {
  debugPrint('[integration-smoke] launch: app.main start');
  final originalFlutterOnError = FlutterError.onError;
  final originalErrorWidgetBuilder = ErrorWidget.builder;
  await app.main();
  FlutterError.onError = originalFlutterOnError;
  ErrorWidget.builder = originalErrorWidgetBuilder;
  debugPrint('[integration-smoke] launch: app.main done');
  await pumpForAppStartup(tester);
  debugPrint('[integration-smoke] launch: startup pumped');
  await ensureSignedInForSmoke(tester);
  debugPrint('[integration-smoke] launch: signed-in gate passed');
}

Future<void> pumpForAppStartup(
  WidgetTester tester, {
  Duration step = const Duration(milliseconds: 250),
  int maxPumps = 24,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(step);
    drainExpectedTesterExceptions(tester, context: 'app bootstrap');
  }
}

Future<void> pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 250),
  int maxPumps = 40,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(step);
    drainExpectedTesterExceptions(tester, context: 'visibility wait');
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  throw TestFailure('Widget not visible after ${step * maxPumps}: $finder');
}

Future<void> expectNoFlutterException(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  drainExpectedTesterExceptions(tester, context: 'expectNoFlutterException');
}

Future<void> ensureSignedInForSmoke(WidgetTester tester) async {
  if (!kRunIntegrationSmoke) return;
  final credentials =
      _cachedIntegrationCredential ??= await _resolveIntegrationCredentials();
  final explicitEnvCredentials = kIntegrationLoginEmail.trim().isNotEmpty &&
      kIntegrationLoginPassword.isNotEmpty;
  if (explicitEnvCredentials) {
    await _resetSmokeSessionForDeterministicSignIn(tester);
  }

  var signedInThisRun = false;
  if (FirebaseAuth.instance.currentUser == null) {
    if (credentials == null) {
      throw TestFailure(
        'Integration smoke requires an authenticated session. '
        'Provide INTEGRATION_LOGIN_EMAIL/INTEGRATION_LOGIN_PASSWORD.',
      );
    }

    try {
      debugPrint(
        '[integration-smoke] auth: sign-in start for ${_redactEmail(credentials.email)}',
      );
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );
      final signedUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (signedUid.isNotEmpty) {
        DeviceSessionService.instance.beginSessionClaim(signedUid);
      }
      debugPrint('[integration-smoke] auth: sign-in success');
      signedInThisRun = true;
    } on FirebaseAuthException catch (error) {
      throw TestFailure(
        'Integration smoke sign-in failed for ${_redactEmail(credentials.email)}: ${error.code}',
      );
    }
  } else {
    debugPrint('[integration-smoke] auth: already signed in');
  }

  await tester.pump(const Duration(milliseconds: 300));
  drainExpectedTesterExceptions(tester, context: 'post sign-in');
  debugPrint(
    signedInThisRun
        ? '[integration-smoke] auth: immediate post-sign-in pump complete'
        : '[integration-smoke] auth: existing session pump complete',
  );

  await CurrentUserService.instance.initialize();
  debugPrint('[integration-smoke] auth: current user initialized');

  final accountCenter = ensureAccountCenterService();
  await accountCenter.init();
  final firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser != null) {
    await _refreshAccountCenterMetadataForSmoke(
      accountCenter,
      firebaseUser,
    );
  }
  final signedUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  if (signedUid.isNotEmpty) {
    try {
      await accountCenter.registerCurrentDeviceSessionIfEnabled();
    } catch (error) {
      debugPrint(
        '[integration-smoke] auth: session register skipped: $error',
      );
    }
  }
  debugPrint('[integration-smoke] auth: account center synced');
  await _primeNotificationsForSmoke(tester);
  await _primeFeedSnapshotForSmoke(tester);
  await _primeMarketForSmoke(tester);

  if (Get.currentRoute != '/NavBarView') {
    await _routeToNavBarForSmoke(tester);
  }

  await _primeFeedForSmoke(tester);
}

Future<void> performSmokeSignOut(WidgetTester tester) async {
  final currentUid = CurrentUserService.instance.effectiveUserId.trim();
  final accountCenter = ensureAccountCenterService();

  if (currentUid.isNotEmpty) {
    try {
      await accountCenter.markSessionState(
        uid: currentUid,
        isSessionValid: false,
      );
    } catch (error) {
      debugPrint(
        '[integration-smoke] auth: markSessionState skipped during sign-out: $error',
      );
    }
  }

  await CurrentUserService.instance.logout();
  await FirebaseAuth.instance.signOut();

  try {
    await accountCenter.reconcileWithAuthSession();
  } catch (error) {
    debugPrint(
      '[integration-smoke] auth: reconcileWithAuthSession skipped during sign-out: $error',
    );
  }

  await tester.pump(const Duration(milliseconds: 300));
  drainExpectedTesterExceptions(tester, context: 'smoke sign-out');
}

Future<void> performSmokeReauth(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
  await tester.pump(const Duration(milliseconds: 300));
  drainExpectedTesterExceptions(tester, context: 'smoke reauth login');

  await CurrentUserService.instance.initialize();
  await tester.pump(const Duration(milliseconds: 300));
  drainExpectedTesterExceptions(tester, context: 'smoke reauth init');

  final accountCenter = ensureAccountCenterService();
  await accountCenter.init();
  final firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser != null) {
    await _refreshAccountCenterMetadataForSmoke(
      accountCenter,
      firebaseUser,
    );
    try {
      await accountCenter.registerCurrentDeviceSessionIfEnabled();
    } catch (error) {
      debugPrint(
        '[integration-smoke] auth: session register skipped after reauth: $error',
      );
    }
  }

  await tester.pump(const Duration(milliseconds: 300));
  drainExpectedTesterExceptions(tester, context: 'smoke reauth settle');
}

Future<void> _resetSmokeSessionForDeterministicSignIn(
  WidgetTester tester,
) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  debugPrint(
    '[integration-smoke] auth: clearing existing session for deterministic sign-in '
    '(${_redactEmail(currentUser.email ?? '')})',
  );
  try {
    await FirebaseAuth.instance.signOut();
  } catch (error) {
    debugPrint(
        '[integration-smoke] auth: FirebaseAuth sign-out skipped: $error');
  }

  try {
    await ensureAccountCenterService().signOutAllLocal();
  } catch (error) {
    debugPrint('[integration-smoke] auth: AccountCenter reset skipped: $error');
  }

  await tester.pump(const Duration(milliseconds: 250));
  drainExpectedTesterExceptions(tester, context: 'sign-out reset');
}

Future<void> _refreshAccountCenterMetadataForSmoke(
  AccountCenterService accountCenter,
  User firebaseUser,
) async {
  const retryDelays = <Duration>[
    Duration.zero,
    Duration(milliseconds: 350),
    Duration(milliseconds: 750),
  ];
  Object? lastError;
  StackTrace? lastStackTrace;

  for (var attempt = 0; attempt < retryDelays.length; attempt++) {
    final delay = retryDelays[attempt];
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    try {
      await accountCenter.refreshCurrentAccountMetadata(
        markSuccessfulSignIn: true,
      );
      return;
    } catch (error, stackTrace) {
      if (!isTransientFirestoreUnavailable(error)) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      lastError = error;
      lastStackTrace = stackTrace;
      debugPrint(
        '[integration-smoke] auth: account center metadata transient failure '
        '${attempt + 1}/${retryDelays.length}: $error',
      );
    }
  }

  if (lastError != null) {
    debugPrint(
      '[integration-smoke] auth: account center metadata fallback to firebase user '
      'after transient Firestore failures: $lastError',
    );
  }
  try {
    await accountCenter.addOrUpdateAccount(
      StoredAccount.fromFirebaseUser(firebaseUser),
      markSuccessfulSignIn: true,
    );
  } catch (error, stackTrace) {
    if (lastError != null && lastStackTrace != null) {
      Error.throwWithStackTrace(lastError, lastStackTrace);
    }
    Error.throwWithStackTrace(error, stackTrace);
  }
}

Future<void> _primeFeedForSmoke(WidgetTester tester) async {
  final agendaController =
      maybeFindAgendaController() ?? ensureAgendaController();
  agendaController.setFeedViewMode(FeedViewMode.forYou);
  if (_feedSatisfiesFixtureContract(agendaController)) {
    debugPrint(
      '[integration-smoke] feed: already primed '
      '(count=${agendaController.agendaList.length})',
    );
    return;
  }

  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    drainExpectedTesterExceptions(tester, context: 'feed settle');
    if (_feedSatisfiesFixtureContract(agendaController)) {
      debugPrint(
        '[integration-smoke] feed: primed after settle '
        '(count=${agendaController.agendaList.length})',
      );
      return;
    }
  }

  try {
    await Future.any([
      agendaController.refreshAgenda(),
      Future<void>.delayed(const Duration(seconds: 4)),
    ]);
  } catch (error) {
    debugPrint('[integration-smoke] feed: refresh warmup skipped: $error');
  }

  int retries = 0;
  while (!_feedSatisfiesFixtureContract(agendaController) && retries < 5) {
    try {
      if (retries == 0) {
        await agendaController.refreshAgenda();
      } else {
        await agendaController.fetchAgendaBigData(initial: true);
      }
    } catch (error) {
      debugPrint(
        '[integration-smoke] feed: fetch retry ${retries + 1}/5 failed: $error',
      );
    }
    await tester.pump(const Duration(milliseconds: 300));
    drainExpectedTesterExceptions(tester, context: 'feed prime');
    if (_feedSatisfiesFixtureContract(agendaController)) {
      break;
    }
    retries++;
    if (retries < 5) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }
  }

  debugPrint(
    '[integration-smoke] feed: primed count=${agendaController.agendaList.length}',
  );

  if (!_feedSatisfiesFixtureContract(agendaController)) {
    final contract = IntegrationTestFixtureContract.current.surface('feed');
    final requiredDocIds = contract?.requiredDocIds ?? const <String>[];
    final actualDocIds = agendaController.agendaList
        .take(24)
        .map((post) => post.docID)
        .toList(growable: false);
    throw TestFailure(
      'Feed prime did not satisfy fixture contract '
      '(count=${agendaController.agendaList.length}, '
      'requiredDocIds=$requiredDocIds, actualDocIds=$actualDocIds).',
    );
  }
}

bool _feedSatisfiesFixtureContract(AgendaController controller) {
  final posts = controller.agendaList;
  final contract = IntegrationTestFixtureContract.current.surface('feed');
  if (contract == null || !contract.isConfigured) {
    return posts.isNotEmpty;
  }

  if (contract.minCount != null && posts.length < contract.minCount!) {
    return false;
  }

  if (contract.requiredDocIds.isEmpty) {
    return posts.isNotEmpty;
  }

  final docIds = posts.map((post) => post.docID).toSet();
  for (final docId in contract.requiredDocIds) {
    if (!docIds.contains(docId)) {
      return false;
    }
  }
  return true;
}

Future<void> _primeNotificationsForSmoke(WidgetTester tester) async {
  final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  if (uid.isEmpty) return;

  final repository = ensureNotificationsSnapshotRepository();
  try {
    await repository.loadInbox(
      userId: uid,
      forceSync: true,
    );
    await repository.bootstrapInbox(userId: uid);
    await tester.pump(const Duration(milliseconds: 250));
    drainExpectedTesterExceptions(tester, context: 'notifications prime');
  } catch (error) {
    debugPrint('[integration-smoke] notifications prime skipped: $error');
  }
}

Future<void> _primeFeedSnapshotForSmoke(WidgetTester tester) async {
  final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  if (uid.isEmpty) return;

  final repository = ensureFeedSnapshotRepository();
  try {
    await repository.loadHome(
      userId: uid,
      forceSync: true,
    );
    await repository.bootstrapHome(userId: uid);
    await tester.pump(const Duration(milliseconds: 250));
    drainExpectedTesterExceptions(tester, context: 'feed snapshot prime');
  } catch (error) {
    debugPrint('[integration-smoke] feed snapshot prime skipped: $error');
  }
}

Future<void> _primeMarketForSmoke(WidgetTester tester) async {
  final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  if (uid.isEmpty) return;

  final repository = MarketSnapshotRepository.ensure();
  try {
    await repository.loadHome(
      userId: uid,
      forceSync: true,
    );
    await tester.pump(const Duration(milliseconds: 250));
    drainExpectedTesterExceptions(tester, context: 'market snapshot prime');
  } catch (error) {
    debugPrint('[integration-smoke] market snapshot prime skipped: $error');
  }
}

Future<void> _routeToNavBarForSmoke(WidgetTester tester) async {
  try {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute == '/NavBarView') return;
      maybeFindNavBarController()?.selectedIndex.value = 0;
      Get.offAll(() => NavBarView());
    });
    await pumpForAppStartup(
      tester,
      step: const Duration(milliseconds: 250),
      maxPumps: 12,
    );
    await pumpUntilVisible(
      tester,
      byItKey(IntegrationTestKeys.navBarRoot),
      step: const Duration(milliseconds: 250),
      maxPumps: 12,
    );
    debugPrint('[integration-smoke] auth: routed to NavBar');
  } catch (error) {
    debugPrint('[integration-smoke] auth: route to NavBar skipped: $error');
  }
}

Future<AccountSessionCredential?> _resolveIntegrationCredentials() async {
  final envEmail = kIntegrationLoginEmail.trim().toLowerCase();
  final envPassword = kIntegrationLoginPassword;
  if (envEmail.isNotEmpty && envPassword.isNotEmpty) {
    return AccountSessionCredential(email: envEmail, password: envPassword);
  }
  return null;
}

Finder byItKey(String key) => find.byKey(ValueKey<String>(key));

Future<void> tapItKey(
  WidgetTester tester,
  String key, {
  int settlePumps = 8,
}) async {
  final finder = byItKey(key);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 100));
  FocusManager.instance.primaryFocus?.unfocus();
  for (var i = 0; i < settlePumps; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  await expectNoFlutterException(tester);
}

Future<void> expectFeedScreen(WidgetTester tester) async {
  drainExpectedTesterExceptions(tester, context: 'expectFeedScreen');
  expect(byItKey(IntegrationTestKeys.screenFeed), findsOneWidget);
  await expectNoFlutterException(tester);
}

Future<void> pageBackAndSettle(
  WidgetTester tester, {
  int settlePumps = 8,
}) async {
  await tester.pageBack();
  for (var i = 0; i < settlePumps; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  await expectNoFlutterException(tester);
}

Future<void> popRouteAndSettle(
  WidgetTester tester, {
  int settlePumps = 8,
}) async {
  await tester.binding.handlePopRoute();
  for (var i = 0; i < settlePumps; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  await expectNoFlutterException(tester);
}
