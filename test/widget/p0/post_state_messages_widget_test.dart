import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Agenda/Components/post_state_messages.dart';

import '../../helpers/test_helper.dart';

class _PostStateTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'tr': {
          'post_state.hidden_title': 'Gonderi gizlendi',
          'post_state.hidden_body': 'Bu gonderi gizli durumda.',
          'post_state.archived_title': 'Gonderi arsivlendi',
          'post_state.archived_body': 'Bu gonderi arsivde tutuluyor.',
          'post_state.deleted_title': 'Gonderi silindi',
          'post_state.deleted_body': 'Bu gonderi kalici olarak silindi.',
          'common.undo': 'Geri al',
        },
      };
}

Future<void> _pumpPostStateHarness(
  WidgetTester tester,
  Widget child, {
  WidgetHarnessVariant variant = WidgetHarnessVariants.phoneAndroid,
}) async {
  await configureHarnessSurface(tester, variant: variant);
  await tester.pumpWidget(
    GetMaterialApp(
      locale: const Locale('tr'),
      translations: _PostStateTranslations(),
      theme: ThemeData(platform: variant.platform, useMaterial3: false),
      home: MediaQuery(
        data: MediaQueryData(
          size: variant.size,
          devicePixelRatio: variant.devicePixelRatio,
          textScaler: TextScaler.linear(variant.textScale),
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('Post state message widgets', () {
    testWidgets(
      'PostHiddenMessage renders and undo action fires',
      (tester) async {
        var undoCount = 0;

        await _pumpPostStateHarness(
          tester,
          PostHiddenMessage(
            onUndo: () => undoCount++,
          ),
          variant: WidgetHarnessVariants.phoneAndroid,
        );

        expect(find.text('Gonderi gizlendi'), findsOneWidget);
        expect(find.text('Bu gonderi gizli durumda.'), findsOneWidget);
        expect(find.text('Geri al'), findsOneWidget);
        expect(find.byIcon(CupertinoIcons.checkmark_seal), findsOneWidget);

        await tester.tap(find.text('Geri al'));
        await tester.pump();

        expect(undoCount, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'PostArchivedMessage renders on iOS harness and undo action fires',
      (tester) async {
        var undoCount = 0;

        await _pumpPostStateHarness(
          tester,
          PostArchivedMessage(
            onUndo: () => undoCount++,
          ),
          variant: WidgetHarnessVariants.phoneIos,
        );

        expect(find.text('Gonderi arsivlendi'), findsOneWidget);
        expect(find.text('Bu gonderi arsivde tutuluyor.'), findsOneWidget);
        expect(find.text('Geri al'), findsOneWidget);
        expect(find.byIcon(CupertinoIcons.checkmark_seal), findsOneWidget);

        await tester.tap(find.text('Geri al'));
        await tester.pump();

        expect(undoCount, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'PostDeletedMessage renders under large text without undo affordance',
      (tester) async {
        await _pumpPostStateHarness(
          tester,
          const PostDeletedMessage(),
          variant: WidgetHarnessVariants.phoneLargeText,
        );

        expect(find.text('Gonderi silindi'), findsOneWidget);
        expect(find.text('Bu gonderi kalici olarak silindi.'), findsOneWidget);
        expect(find.text('Geri al'), findsNothing);
        expect(find.byIcon(CupertinoIcons.checkmark_seal), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
