import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Localization/app_language_service.dart';
import 'package:turqappv2/Modules/Profile/LangSelector/lang_selector.dart';
import 'package:turqappv2/Modules/Profile/Settings/language_settings_view.dart';

import '../../helpers/test_helper.dart';

class _LanguageTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'tr': {
          'legacy_language.title': 'Dil',
          'language.title': 'Dil',
          'language.subtitle': 'Uygulama dili',
          'language.note': 'Dili istedigin zaman degistirebilirsin.',
          'language.option.tr': 'Turkce',
          'language.option.en': 'English',
          'language.option.de': 'Deutsch',
          'language.option.fr': 'Francais',
          'language.option.it': 'Italiano',
          'language.option.ru': 'Russkiy',
          'language.option.ar': 'Arabic',
        },
      };
}

class _FakeAppLanguageService extends AppLanguageService {
  final RxString _fakeCurrentCode = 'tr_TR'.obs;

  @override
  String get currentCode => _fakeCurrentCode.value;

  @override
  Locale get currentLocale => switch (_fakeCurrentCode.value) {
        'en_US' => const Locale('en', 'US'),
        'de_DE' => const Locale('de', 'DE'),
        'fr_FR' => const Locale('fr', 'FR'),
        'it_IT' => const Locale('it', 'IT'),
        'ru_RU' => const Locale('ru', 'RU'),
        _ => const Locale('tr', 'TR'),
      };

  @override
  Future<void> changeLanguage(String code) async {
    _fakeCurrentCode.value = code;
  }
}

Future<void> _pumpLanguageHarness(
  WidgetTester tester,
  Widget child, {
  WidgetHarnessVariant variant = WidgetHarnessVariants.phoneAndroid,
}) async {
  await configureHarnessSurface(tester, variant: variant);
  await tester.pumpWidget(
    GetMaterialApp(
      locale: const Locale('tr'),
      translations: _LanguageTranslations(),
      theme: ThemeData(
        platform: variant.platform,
        useMaterial3: false,
      ),
      home: MediaQuery(
        data: MediaQueryData(
          size: variant.size,
          devicePixelRatio: variant.devicePixelRatio,
          textScaler: TextScaler.linear(variant.textScale),
        ),
        child: child,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    Get.reset();
    Get.put<AppLanguageService>(_FakeAppLanguageService(), permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  group('Language selector surfaces', () {
    testWidgets(
      'LangSelector renders all language options and pops via back button',
      (tester) async {
        await _pumpLanguageHarness(
          tester,
          Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LangSelector(),
                        ),
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              );
            },
          ),
          variant: WidgetHarnessVariants.phoneLargeText,
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('Dil'), findsOneWidget);
        expect(find.text('Turkce'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
        expect(find.text('Deutsch'), findsOneWidget);
        expect(find.text('Francais'), findsOneWidget);
        expect(find.text('Russkiy'), findsOneWidget);
        expect(find.text('Arabic'), findsOneWidget);

        await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
        await tester.pumpAndSettle();

        expect(find.text('open'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'LanguageSettingsView updates selected language on tap',
      (tester) async {
        await _pumpLanguageHarness(
          tester,
          const LanguageSettingsView(),
          variant: WidgetHarnessVariants.phoneIos,
        );

        expect(find.text('Uygulama dili'), findsOneWidget);
        expect(find.text('Turkce'), findsOneWidget);
        expect(
          find.byIcon(CupertinoIcons.check_mark_circled_solid),
          findsOneWidget,
        );

        await tester.tap(find.text('English').first);
        await tester.pumpAndSettle();

        final languageService = AppLanguageService.maybeFind();
        expect(languageService, isNotNull);
        expect(languageService!.currentCode, 'en_US');
        expect(
          find.byIcon(CupertinoIcons.check_mark_circled_solid),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'LanguageSettingsView stays scrollable under large text',
      (tester) async {
        await _pumpLanguageHarness(
          tester,
          const LanguageSettingsView(),
          variant: WidgetHarnessVariants.phoneLargeText,
        );

        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();

        expect(find.text('English'), findsWidgets);
        expect(find.text('Italiano'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
