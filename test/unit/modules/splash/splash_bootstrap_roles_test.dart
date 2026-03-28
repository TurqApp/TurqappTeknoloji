import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Modules/Splash/splash_post_login_warmup.dart';
import 'package:turqappv2/Modules/Splash/splash_session_bootstrap.dart';
import 'package:turqappv2/Modules/Splash/splash_startup_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('StartupBootstrap runs core startup prerequisites and returns prefs', () async {
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
    expect(events, contains('audio'));
    expect(
      events.indexOf('firebase'),
      lessThan(events.indexOf('firestore')),
    );
  });

  test(
    'SessionBootstrap marks minimum startup prepared for deterministic logged-in flow',
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
        prepareSynchronizedStartupBeforeNav: ({required isFirstLaunch}) async {
          events.add('prepareSync:$isFirstLaunch');
        },
        markMinimumStartupPrepared: (value) {
          events.add('markMin:$value');
        },
        deterministicStartup: () => true,
        isIOS: () => false,
      );

      final result = await bootstrap.run(prefs: prefs);

      expect(result.isFirstLaunch, isTrue);
      expect(result.loggedIn, isTrue);
      expect(events, contains('accountCenter.init'));
      expect(events, contains('cleanup'));
      expect(events, contains('currentUser.init'));
      expect(events, contains('accountCenter.sync'));
      expect(events, contains('markMin:true'));
      expect(events, isNot(contains('prepareSync:true')));
    },
  );

  test('PostLoginWarmup only enforces follow when a signed-in user exists', () async {
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
    expect(events, contains('admob:true'));
    expect(events, contains('tags'));
    expect(events, isNot(contains('follow')));

    events.clear();

    warmup.startNonBlockingStartupWork(
      isFirstLaunch: false,
      effectiveUserId: 'uid-1',
    );
    await Future<void>.delayed(Duration.zero);
    expect(events, contains('admob:false'));
    expect(events, contains('tags'));
    expect(events, contains('follow'));
  });
}
