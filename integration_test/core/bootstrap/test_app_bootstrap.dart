import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:turqappv2/Core/Repositories/feed_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/market_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/integration_test_fixture_contract.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/integration_test_state_probe.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Repositories/notifications_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Models/posts_model.dart';
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

Future<void> launchTurqApp(
  WidgetTester tester, {
  bool forceFeedTab = true,
  int? restoredNavIndex,
}) async {
  debugPrint('[integration-smoke] launch: app.main start');
  final originalFlutterOnError = FlutterError.onError;
  final originalErrorWidgetBuilder = ErrorWidget.builder;
  await app.main();
  FlutterError.onError = originalFlutterOnError;
  ErrorWidget.builder = originalErrorWidgetBuilder;
  debugPrint('[integration-smoke] launch: app.main done');
  await pumpForAppStartup(tester);
  debugPrint('[integration-smoke] launch: startup pumped');
  await ensureSignedInForSmoke(
    tester,
    forceFeedTab: forceFeedTab,
    restoredNavIndex: restoredNavIndex,
  );
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

Future<void> ensureSignedInForSmoke(
  WidgetTester tester, {
  bool forceFeedTab = true,
  int? restoredNavIndex,
}) async {
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
    await _routeToNavBarForSmoke(
      tester,
      resetNavIndex: forceFeedTab,
    );
  }

  if (restoredNavIndex != null) {
    _seedRestoredNavStateForSmoke(restoredNavIndex);
  }

  if (forceFeedTab) {
    await _ensureFeedTabForSmoke(tester);
    await _primeFeedForSmoke(tester);
  }
}

void _seedRestoredNavStateForSmoke(int index) {
  final normalizedIndex = index == 2 ? 0 : index.clamp(0, 4);
  final navBar = maybeFindNavBarController() ?? ensureNavBarController();
  if (navBar.selectedIndex.value == normalizedIndex) {
    return;
  }
  navBar.changeIndex(normalizedIndex);
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

  await _waitForFeedPrimeToSettleForSmoke(tester, agendaController);
  debugPrint(
    '[integration-smoke] feed: primed count=${agendaController.agendaList.length}',
  );

  if (!_feedSatisfiesFixtureContract(agendaController)) {
    for (var attempt = 0;
        attempt < 3 && !_feedSatisfiesFixtureContract(agendaController);
        attempt++) {
      await _waitForFeedPrimeToSettleForSmoke(tester, agendaController);
      await _backfillRequiredFeedDocsForSmoke(agendaController);
      await tester.pump(const Duration(milliseconds: 160));
      drainExpectedTesterExceptions(
        tester,
        context: 'feed contract backfill apply',
      );
      if (_feedSatisfiesFixtureContract(agendaController)) {
        break;
      }
      agendaController.primeInitialCenteredPost();
      await tester.pump(const Duration(milliseconds: 100));
      agendaController.resumeFeedPlayback();
      await _waitForFeedPrimeToSettleForSmoke(tester, agendaController);
      debugPrint(
        '[integration-smoke] feed: fixture contract retry ${attempt + 1}/3 '
        'count=${agendaController.agendaList.length}',
      );
    }
  }

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

Future<void> _waitForFeedPrimeToSettleForSmoke(
  WidgetTester tester,
  AgendaController agendaController, {
  int maxPumps = 16,
}) async {
  var stableTicks = 0;
  var previousSignature = _feedPrimeSignatureForSmoke(agendaController);
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 180));
    drainExpectedTesterExceptions(tester, context: 'feed prime settle');
    final currentSignature = _feedPrimeSignatureForSmoke(agendaController);
    final isIdle = !agendaController.isLoading.value;
    if (isIdle && currentSignature == previousSignature) {
      stableTicks++;
      if (stableTicks >= 2) {
        return;
      }
    } else {
      stableTicks = 0;
    }
    previousSignature = currentSignature;
  }
}

String _feedPrimeSignatureForSmoke(AgendaController agendaController) {
  final headDocIds = agendaController.agendaList
      .take(8)
      .map((post) => post.docID.trim())
      .where((docId) => docId.isNotEmpty)
      .join('|');
  return '${agendaController.isLoading.value}:'
      '${agendaController.agendaList.length}:$headDocIds';
}

Future<void> _backfillRequiredFeedDocsForSmoke(
  AgendaController agendaController,
) async {
  final contract = IntegrationTestFixtureContract.current.surface('feed');
  if (contract == null || contract.requiredDocIds.isEmpty) {
    return;
  }

  final existingDocIds = agendaController.agendaList
      .map((post) => post.docID.trim())
      .where((docId) => docId.isNotEmpty)
      .toSet();
  final missingDocIds = contract.requiredDocIds
      .map((docId) => docId.trim())
      .where((docId) => docId.isNotEmpty && !existingDocIds.contains(docId))
      .toList(growable: false);
  if (missingDocIds.isEmpty) {
    return;
  }

  final seededPosts = await _fetchRequiredFeedPostsForSmoke(missingDocIds);
  if (seededPosts.isEmpty) {
    debugPrint(
      '[integration-smoke] feed: required doc backfill fetch returned empty '
      'missing=$missingDocIds',
    );
    return;
  }

  // Keep the live feed order stable for playback-focused smoke suites.
  // Required fixture docs only need to exist in the surface contract; they
  // should not outrank the real top-of-feed items during test backfill.
  final merged = <PostsModel>[
    ...agendaController.agendaList.where(
      (post) => !missingDocIds.contains(post.docID.trim()),
    ),
    ...seededPosts,
  ];

  agendaController.agendaList.assignAll(merged);
  debugPrint(
    '[integration-smoke] feed: backfilled required docs '
    'missing=$missingDocIds added=${seededPosts.map((post) => post.docID).join(',')}',
  );
}

Future<List<PostsModel>> _fetchRequiredFeedPostsForSmoke(
  List<String> docIds,
) async {
  final normalized = docIds
      .map((docId) => docId.trim())
      .where((docId) => docId.isNotEmpty)
      .toList(growable: false);
  if (normalized.isEmpty) {
    return const <PostsModel>[];
  }

  final fetchedById = await PostRepository.ensure().fetchPostCardsByIds(
    normalized,
    preferCache: false,
    cacheOnly: false,
  );
  final seededPosts = <PostsModel>[];
  final unresolved = <String>[];

  for (final docId in normalized) {
    final post = fetchedById[docId];
    if (post != null) {
      seededPosts.add(post);
    } else {
      unresolved.add(docId);
    }
  }

  if (unresolved.isNotEmpty) {
    final posts = FirebaseFirestore.instance.collection('Posts');
    for (final docId in unresolved) {
      try {
        final snap = await posts.doc(docId).get();
        if (!snap.exists) continue;
        final data = snap.data();
        if (data == null) continue;
        seededPosts.add(PostsModel.fromMap(data, snap.id));
      } catch (error) {
        debugPrint(
          '[integration-smoke] feed: direct post fetch failed '
          'docId=$docId error=$error',
        );
      }
    }
  }

  final uniqueById = <String, PostsModel>{};
  for (final post in seededPosts) {
    final docId = post.docID.trim();
    if (docId.isEmpty) continue;
    uniqueById[docId] = post;
  }
  if (uniqueById.isEmpty && unresolved.isNotEmpty) {
    debugPrint(
      '[integration-smoke] feed: required doc fetch unresolved '
      'docIds=$unresolved',
    );
  }
  return uniqueById.values.toList(growable: false);
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

Future<void> _routeToNavBarForSmoke(
  WidgetTester tester, {
  bool resetNavIndex = true,
}) async {
  try {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute == '/NavBarView') return;
      if (resetNavIndex) {
        maybeFindNavBarController()?.selectedIndex.value = 0;
      }
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

Future<void> _ensureFeedTabForSmoke(WidgetTester tester) async {
  try {
    await pumpUntilVisible(
      tester,
      byItKey(IntegrationTestKeys.navBarRoot),
      step: const Duration(milliseconds: 250),
      maxPumps: 12,
    );
    final navBar = maybeFindNavBarController() ?? ensureNavBarController();
    if (navBar.selectedIndex.value != 0) {
      navBar.changeIndex(0);
      await settleSmokeShell(
        tester,
        context: 'smoke force feed tab',
      );
    }
    await pumpUntilVisible(
      tester,
      byItKey(IntegrationTestKeys.screenFeed),
      step: const Duration(milliseconds: 250),
      maxPumps: 12,
    );
  } catch (error) {
    debugPrint('[integration-smoke] auth: ensure feed tab skipped: $error');
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

Finder firstInteractable(Finder finder) {
  final hitTestable = finder.hitTestable();
  if (hitTestable.evaluate().isNotEmpty) {
    return hitTestable.first;
  }
  return finder.first;
}

bool _isNavItKey(String key) {
  return key == IntegrationTestKeys.navFeed ||
      key == IntegrationTestKeys.navExplore ||
      key == IntegrationTestKeys.navShort ||
      key == IntegrationTestKeys.navChat ||
      key == IntegrationTestKeys.navEducation ||
      key == IntegrationTestKeys.navProfile;
}

void _safeUnfocusPrimaryFocus() {
  final primaryFocus = FocusManager.instance.primaryFocus;
  if (primaryFocus == null) return;
  try {
    primaryFocus.unfocus();
  } catch (error) {
    debugPrint('[integration-smoke] safe unfocus skipped: $error');
  }
}

Future<void> _pumpUntilProbeRegistered(
  WidgetTester tester,
  String surface, {
  Duration step = const Duration(milliseconds: 250),
  int maxPumps = 12,
}) async {
  Map<String, dynamic> snapshot = IntegrationTestStateProbe.snapshot();
  Map<String, dynamic> payload = Map<String, dynamic>.from(
    snapshot[surface] as Map? ?? const <String, dynamic>{},
  );

  for (var i = 0; i < maxPumps && payload['registered'] != true; i++) {
    await tester.pump(step);
    snapshot = IntegrationTestStateProbe.snapshot();
    payload = Map<String, dynamic>.from(
      snapshot[surface] as Map? ?? const <String, dynamic>{},
    );
  }

  expect(payload['registered'], isTrue,
      reason: '$surface controller not registered');
}

Future<void> tapItKey(
  WidgetTester tester,
  String key, {
  int settlePumps = 8,
  bool dismissKeyboard = true,
}) async {
  final finder = byItKey(key);
  expect(finder, findsWidgets);
  final target = firstInteractable(finder);
  await tester.ensureVisible(target);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(target);
  await tester.pump(const Duration(milliseconds: 100));
  if (dismissKeyboard) {
    _safeUnfocusPrimaryFocus();
  }
  for (var i = 0; i < settlePumps; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  await expectNoFlutterException(tester);
}

Future<void> pressItKey(
  WidgetTester tester,
  String key, {
  int settlePumps = 8,
}) async {
  if (_isNavItKey(key)) {
    final navBar = maybeFindNavBarController();
    if (navBar != null && !navBar.showBar.value) {
      navBar.showBar.value = true;
      await settleSmokeShell(
        tester,
        context: 'show hidden nav bar for $key',
        maxPumps: 4,
      );
    }
  }

  final finder = byItKey(key);
  expect(finder, findsWidgets);
  final target = firstInteractable(finder);
  await tester.ensureVisible(target);
  await tester.pump(const Duration(milliseconds: 100));

  final widget = tester.widget(target);
  var handled = false;
  if (widget is TextButton && widget.onPressed != null) {
    widget.onPressed!.call();
    handled = true;
  } else if (widget is IconButton && widget.onPressed != null) {
    widget.onPressed!.call();
    handled = true;
  } else if (widget is FloatingActionButton && widget.onPressed != null) {
    widget.onPressed!.call();
    handled = true;
  } else if (widget is AppHeaderActionButton && widget.onTap != null) {
    widget.onTap!.call();
    handled = true;
  }

  if (!handled) {
    if (widget is GestureDetector && widget.onTap != null) {
      widget.onTap!.call();
      handled = true;
    } else if (widget is InkWell && widget.onTap != null) {
      widget.onTap!.call();
      handled = true;
    }
  }

  if (!handled) {
    await tester.tap(target);
  }

  await tester.pump(const Duration(milliseconds: 100));
  for (var i = 0; i < settlePumps; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  await expectNoFlutterException(tester);
}

Future<void> expectFeedScreen(WidgetTester tester) async {
  drainExpectedTesterExceptions(tester, context: 'expectFeedScreen');
  expect(byItKey(IntegrationTestKeys.screenFeed), findsOneWidget);
  await _pumpUntilProbeRegistered(tester, 'feed');
  await expectNoFlutterException(tester);
}

Future<void> ensureFeedTabVisibleForSmoke(WidgetTester tester) async {
  await _ensureFeedTabForSmoke(tester);
  await expectFeedScreen(tester);
}

Future<void> settleSmokeShell(
  WidgetTester tester, {
  Duration step = const Duration(milliseconds: 250),
  int maxPumps = 8,
  String context = 'smoke shell settle',
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(step);
    drainExpectedTesterExceptions(tester, context: context);
  }
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
  drainExpectedTesterExceptions(tester, context: 'pre popRouteAndSettle');
  await tester.pump(const Duration(milliseconds: 16));
  await tester.idle();
  await tester.binding.handlePopRoute();
  await tester.pump(const Duration(milliseconds: 16));
  for (var i = 0; i < settlePumps; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  await expectNoFlutterException(tester);
}
