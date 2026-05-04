import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Modules/Splash/splash_post_login_warmup.dart';
import 'package:turqappv2/Modules/Splash/splash_session_bootstrap.dart';
import 'package:turqappv2/Modules/Splash/splash_startup_orchestrator.dart';
import 'package:turqappv2/Modules/Splash/splash_startup_bootstrap.dart';
import 'package:turqappv2/Runtime/startup_session_failure.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'StartupBootstrap runs core startup prerequisites and defers audio init',
    () async {
      final events = <String>[];
      SharedPreferences.setMockInitialValues(<String, Object>{'ready': true});

      final bootstrap = StartupBootstrap(
        firebaseStartupWait: Duration.zero,
        waitForFirebaseBootstrap: () async {
          events.add('firebase');
        },
        initializeFirestoreConfig: () async {
          events.add('firestore');
        },
        readPreferences: () async {
          events.add('prefs');
          return SharedPreferences.getInstance();
        },
        initializeAudioContext: () async {
          events.add('audio');
        },
      );

      final prefs = await bootstrap.run();

      expect(prefs.getBool('ready'), isTrue);
      expect(events, contains('firebase'));
      expect(events, contains('firestore'));
      expect(events, contains('prefs'));
      expect(events, isNot(contains('audio')));
      expect(
        events.indexOf('firebase'),
        lessThan(events.indexOf('firestore')),
      );

      await bootstrap.initializeDeferredAudioContext();

      expect(events, contains('audio'));
    },
  );

  test(
    'SessionBootstrap syncs account center for logged-in flow',
    () async {
      final events = <String>[];
      final prefs = await SharedPreferences.getInstance();

      final bootstrap = SessionBootstrap(
        initializeAccountCenter: () async {
          events.add('accountCenter.init');
        },
        initializeCurrentUser: () async {
          events.add('currentUser.init');
        },
        handleFirstLaunchCleanup: (_) async {
          events.add('cleanup');
          return true;
        },
        readEffectiveUserId: () => 'uid-1',
        syncCurrentAccountToAccountCenter: () async {
          events.add('accountCenter.sync');
        },
        isIOS: () => false,
      );

      final result = await bootstrap.run(prefs: prefs);

      expect(result.isFirstLaunch, isTrue);
      expect(result.loggedIn, isTrue);
      expect(events, contains('accountCenter.init'));
      expect(events, contains('cleanup'));
      expect(events, contains('currentUser.init'));
      expect(events, contains('accountCenter.sync'));
    },
  );

  test(
    'SessionBootstrap skips auth restore when no returning-session hint exists',
    () async {
      final events = <String>[];
      final prefs = await SharedPreferences.getInstance();
      var effectiveUserId = '';

      final bootstrap = SessionBootstrap(
        initializeAccountCenter: () async {
          events.add('accountCenter.init');
        },
        initializeCurrentUser: () async {
          events.add('currentUser.init');
        },
        handleFirstLaunchCleanup: (_) async {
          events.add('cleanup');
          return false;
        },
        readEffectiveUserId: () => effectiveUserId,
        ensureAuthReady: ({required timeout}) async {
          events.add('ensureAuthReady:${timeout.inMilliseconds}');
          effectiveUserId = 'uid-restored';
          return effectiveUserId;
        },
        syncCurrentAccountToAccountCenter: () async {
          events.add('accountCenter.sync');
        },
        isIOS: () => false,
      );

      final result = await bootstrap.run(prefs: prefs);

      expect(result.isFirstLaunch, isFalse);
      expect(result.loggedIn, isFalse);
      expect(
        events.where((event) => event == 'currentUser.init').length,
        1,
      );
      expect(
        events.any((event) => event.startsWith('ensureAuthReady:')),
        isFalse,
      );
      expect(events, isNot(contains('accountCenter.sync')));
    },
  );

  test(
    'SessionBootstrap extends auth restore wait for returning Android sessions',
    () async {
      final events = <String>[];
      SharedPreferences.setMockInitialValues(<String, Object>{
        'account_center.last_used_uid': 'uid-restored',
      });
      final prefs = await SharedPreferences.getInstance();
      var effectiveUserId = '';

      final bootstrap = SessionBootstrap(
        initializeAccountCenter: () async {
          events.add('accountCenter.init');
        },
        initializeCurrentUser: () async {
          events.add('currentUser.init');
        },
        handleFirstLaunchCleanup: (_) async => false,
        readEffectiveUserId: () => effectiveUserId,
        ensureAuthReady: ({required timeout}) async {
          events.add('ensureAuthReady:${timeout.inMilliseconds}');
          effectiveUserId = 'uid-restored';
          return effectiveUserId;
        },
        syncCurrentAccountToAccountCenter: () async {
          events.add('accountCenter.sync');
        },
        isIOS: () => false,
      );

      final result = await bootstrap.run(prefs: prefs);

      expect(result.loggedIn, isTrue);
      expect(events, contains('ensureAuthReady:1800'));
      expect(events, contains('accountCenter.sync'));
    },
  );

  test(
    'SessionBootstrap preserves returning-session auth wait even if init clears cache pointer',
    () async {
      final events = <String>[];
      SharedPreferences.setMockInitialValues(<String, Object>{
        'cached_current_user_active_uid': 'uid-restored',
      });
      final prefs = await SharedPreferences.getInstance();
      var effectiveUserId = '';

      final bootstrap = SessionBootstrap(
        initializeAccountCenter: () async {
          events.add('accountCenter.init');
        },
        initializeCurrentUser: () async {
          events.add('currentUser.init');
          await prefs.remove('cached_current_user_active_uid');
        },
        handleFirstLaunchCleanup: (_) async => false,
        readEffectiveUserId: () => effectiveUserId,
        ensureAuthReady: ({required timeout}) async {
          events.add('ensureAuthReady:${timeout.inMilliseconds}');
          effectiveUserId = 'uid-restored';
          return effectiveUserId;
        },
        syncCurrentAccountToAccountCenter: () async {
          events.add('accountCenter.sync');
        },
        isIOS: () => false,
      );

      final result = await bootstrap.run(prefs: prefs);

      expect(result.loggedIn, isTrue);
      expect(events, contains('ensureAuthReady:1800'));
      expect(events, contains('accountCenter.sync'));
    },
  );

  test('SplashStartupOrchestrator records startup failures and still navigates',
      () async {
    final failures = <StartupSessionFailure>[];
    var navigated = 0;

    final orchestrator = SplashStartupOrchestrator(
      firebaseStartupWait: Duration.zero,
      isMounted: () => true,
      navigateToPrimaryRoute: () async {
        navigated++;
      },
      prepareSynchronizedStartupBeforeNav: ({required isFirstLaunch}) async {},
      runCriticalWarmStartLoads: ({required isFirstLaunch}) async {},
      runWarmStartLoads: ({required isFirstLaunch}) async {},
      markMinimumStartupPrepared: (_) {},
      rememberIsFirstLaunch: (_) {},
      isMinimumStartupPrepared: () => false,
      hydrateStartupManifestContext: ({required loggedIn}) async {},
      startupBootstrap: StartupBootstrap(
        firebaseStartupWait: Duration.zero,
        waitForFirebaseBootstrap: () async {
          throw StateError('firebase-bootstrap-failed');
        },
        initializeFirestoreConfig: () async {},
        readPreferences: SharedPreferences.getInstance,
        initializeAudioContext: () async {},
      ),
      failureReporter: StartupSessionFailureReporter(onFailure: failures.add),
    );

    await orchestrator.initializeApp();

    expect(navigated, 1);
    expect(failures, hasLength(1));
    expect(
      failures.single.kind,
      StartupSessionFailureKind.startupOrchestration,
    );
  });

  test('PostLoginWarmup only enforces follow when a signed-in user exists',
      () async {
    final events = <String>[];
    final warmup = PostLoginWarmup(
      runCriticalWarmStartLoads: ({required isFirstLaunch}) async {},
      runWarmStartLoads: ({required isFirstLaunch}) async {},
      isMinimumStartupPrepared: () => true,
      initializeAdMob: ({required isFirstLaunch}) async {
        events.add('admob:$isFirstLaunch');
      },
      fetchTrendingTags: () async {
        events.add('tags');
      },
      enforceMandatoryFollow: () async {
        events.add('follow');
      },
      initializeNotifications: () async {},
      isOnWiFiNow: () => true,
      skipBackgroundStartupWork: () => false,
      isIOS: () => false,
    );

    warmup.startNonBlockingStartupWork(
      isFirstLaunch: true,
      effectiveUserId: '',
    );
    await Future<void>.delayed(Duration.zero);
    expect(events, contains('tags'));
    expect(events, isNot(contains('follow')));

    events.clear();

    warmup.startNonBlockingStartupWork(
      isFirstLaunch: false,
      effectiveUserId: 'uid-1',
    );
    await Future<void>.delayed(Duration.zero);
    expect(events, contains('tags'));
    expect(events, contains('follow'));
  });

  test('PostLoginWarmup records classified background warmup failures',
      () async {
    final failures = <StartupSessionFailure>[];
    final warmup = PostLoginWarmup(
      runCriticalWarmStartLoads: ({required isFirstLaunch}) async {},
      runWarmStartLoads: ({required isFirstLaunch}) async {},
      isMinimumStartupPrepared: () => false,
      initializeAdMob: ({required isFirstLaunch}) async {},
      fetchTrendingTags: () async {},
      enforceMandatoryFollow: () async {},
      initializeNotifications: () async {},
      isOnWiFiNow: () => throw StateError('wifi-state-failed'),
      currentSignedInUserId: () => 'uid-1',
      skipBackgroundStartupWork: () => false,
      isIOS: () => false,
      failureReporter: StartupSessionFailureReporter(onFailure: failures.add),
    );

    await warmup.runBackgroundInit(isFirstLaunch: false);

    expect(
      failures.any(
        (failure) => failure.kind == StartupSessionFailureKind.backgroundWarmup,
      ),
      isTrue,
    );
  });
}
