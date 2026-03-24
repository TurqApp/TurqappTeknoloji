import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/full_screen_image_viewer.dart';

import '../../helpers/test_helper.dart';

class _ViewerRouteHarness extends StatelessWidget {
  const _ViewerRouteHarness();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Get.to(
              () => const FullScreenImageViewer(
                imageUrl: 'https://example.com/test.jpg',
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    );
  }
}

void main() {
  Future<void> pumpRouteTransition(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  group('FullScreenImageViewer', () {
    testWidgets(
      'opens and closes via close button on iOS harness',
      (tester) async {
        await pumpApp(
          tester,
          const _ViewerRouteHarness(),
          variant: WidgetHarnessVariants.phoneIos,
        );

        await tester.tap(find.text('open'));
        await pumpRouteTransition(tester);

        expect(find.byType(FullScreenImageViewer), findsOneWidget);
        expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
        expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);

        await tester.tap(find.byIcon(CupertinoIcons.xmark));
        await pumpRouteTransition(tester);

        expect(find.byType(FullScreenImageViewer), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'opens under tablet harness and survives drag gesture updates',
      (tester) async {
        await pumpApp(
          tester,
          const _ViewerRouteHarness(),
          variant: WidgetHarnessVariants.tabletAndroid,
        );

        await tester.tap(find.text('open'));
        await pumpRouteTransition(tester);

        expect(find.byType(FullScreenImageViewer), findsOneWidget);

        final center = tester.getCenter(find.byType(FullScreenImageViewer));
        final gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(0, 90));
        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        expect(find.byType(FullScreenImageViewer), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
