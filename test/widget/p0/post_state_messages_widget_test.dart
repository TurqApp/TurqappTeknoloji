import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Modules/Agenda/Components/post_state_messages.dart';

import '../../helpers/test_helper.dart';

void main() {
  group('Post state message widgets', () {
    testWidgets(
      'PostHiddenMessage renders and undo action fires',
      (tester) async {
        var undoCount = 0;

        await pumpApp(
          tester,
          PostHiddenMessage(
            onUndo: () => undoCount++,
          ),
          wrapInScaffold: true,
          variant: WidgetHarnessVariants.phoneAndroid,
        );

        expect(find.text('post_state.hidden_title'), findsOneWidget);
        expect(find.text('post_state.hidden_body'), findsOneWidget);
        expect(find.text('common.undo'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNothing);
        expect(find.byIcon(Icons.error), findsNothing);

        await tester.tap(find.text('common.undo'));
        await tester.pump();

        expect(undoCount, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'PostArchivedMessage renders on iOS harness and undo action fires',
      (tester) async {
        var undoCount = 0;

        await pumpApp(
          tester,
          PostArchivedMessage(
            onUndo: () => undoCount++,
          ),
          wrapInScaffold: true,
          variant: WidgetHarnessVariants.phoneIos,
        );

        expect(find.text('post_state.archived_title'), findsOneWidget);
        expect(find.text('post_state.archived_body'), findsOneWidget);
        expect(find.text('common.undo'), findsOneWidget);

        await tester.tap(find.text('common.undo'));
        await tester.pump();

        expect(undoCount, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'PostDeletedMessage renders under large text without undo affordance',
      (tester) async {
        await pumpApp(
          tester,
          const PostDeletedMessage(),
          wrapInScaffold: true,
          variant: WidgetHarnessVariants.phoneLargeText,
        );

        expect(find.text('post_state.deleted_title'), findsOneWidget);
        expect(find.text('post_state.deleted_body'), findsOneWidget);
        expect(find.text('common.undo'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
