import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Models/stored_account.dart';
import 'package:turqappv2/Modules/SignIn/sign_in.dart';

import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestFirebaseCoreHostApi.setUp(_StorageBucketFirebaseApp());
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'test',
          appId: 'test',
          messagingSenderId: 'test',
          projectId: 'test',
          storageBucket: 'test.appspot.com',
        ),
      );
    } on FirebaseException catch (error) {
      if (error.code != 'duplicate-app') {
        rethrow;
      }
    }
  });

  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('real sign-in screen opens login form from start screen', (
    tester,
  ) async {
    await pumpApp(tester, const SignIn());
    _discardExpectedAuthEntryWarmException(tester);

    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.screenSignIn)),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('login_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('email')), findsNothing);
    expect(find.byKey(const ValueKey('password')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('login_button')));
    await tester.pump();
    _discardExpectedAuthEntryWarmException(tester);

    expect(find.byKey(const ValueKey('email')), findsOneWidget);
    expect(find.byKey(const ValueKey('password')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_submit_button')), findsOneWidget);
  });

  testWidgets('real sign-in screen keeps initial identifier in login form', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const SignIn(initialIdentifier: 'test@mail.com'),
    );
    _discardExpectedAuthEntryWarmException(tester);

    expect(find.byKey(const ValueKey('login_button')), findsNothing);
    expect(find.byKey(const ValueKey('email')), findsOneWidget);
    expect(find.byKey(const ValueKey('password')), findsOneWidget);

    final emailField = tester.widget<TextField>(
      find.byKey(const ValueKey('email')),
    );

    expect(emailField.controller?.text, 'test@mail.com');
    expect(find.byKey(const ValueKey('login_submit_button')), findsOneWidget);
  });

  testWidgets('stored account route opens login form after account center init',
      (
    tester,
  ) async {
    final account = StoredAccount(
      uid: 'stored-1',
      email: 'osman@example.com',
      username: 'osman',
      displayName: 'Osman',
      rozet: '',
      avatarUrl: '',
      providers: <String>['password'],
      lastUsedAt: 0,
      isSessionValid: false,
      requiresReauth: true,
      accountState: 'reauth_required',
      isPinned: false,
      sortOrder: 1,
      lastSuccessfulSignInAt: 0,
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'account_center.accounts': StoredAccount.encodeList(<StoredAccount>[
        account,
      ]),
    });

    await pumpApp(
      tester,
      const SignIn(storedAccountUid: 'stored-1'),
    );
    _discardExpectedAuthEntryWarmException(tester);
    await tester.pump();
    _discardExpectedAuthEntryWarmException(tester);
    await tester.pump(const Duration(milliseconds: 250));
    _discardExpectedAuthEntryWarmException(tester);

    expect(find.byKey(const ValueKey('login_button')), findsNothing);
    expect(find.byKey(const ValueKey('email')), findsOneWidget);
    expect(find.byKey(const ValueKey('password')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_submit_button')), findsOneWidget);
  });
}

class _StorageBucketFirebaseApp implements TestFirebaseCoreHostApi {
  @override
  Future<CoreInitializeResponse> initializeApp(
    String appName,
    CoreFirebaseOptions initializeAppRequest,
  ) async {
    return CoreInitializeResponse(
      name: appName,
      options: _options(),
      pluginConstants: <String, Object?>{},
    );
  }

  @override
  Future<List<CoreInitializeResponse>> initializeCore() async {
    return <CoreInitializeResponse>[
      CoreInitializeResponse(
        name: defaultFirebaseAppName,
        options: _options(),
        pluginConstants: <String, Object?>{},
      ),
    ];
  }

  @override
  Future<CoreFirebaseOptions> optionsFromResource() async => _options();

  CoreFirebaseOptions _options() {
    return CoreFirebaseOptions(
      apiKey: 'test',
      appId: 'test',
      messagingSenderId: 'test',
      projectId: 'test',
      storageBucket: 'test.appspot.com',
    );
  }
}

void _discardExpectedAuthEntryWarmException(WidgetTester tester) {
  final error = tester.takeException();
  if (error == null) return;
  expect(
    error.toString(),
    anyOf(
      contains('firebase_storage/no-bucket'),
      contains('core/no-app'),
      contains('MissingPluginException'),
    ),
  );
}
