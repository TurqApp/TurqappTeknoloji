import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Short/short_controller.dart';

import 'helpers/smoke_artifact_collector.dart';
import 'helpers/test_app_bootstrap.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Short excludes posts wider than 1.2 aspect ratio',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'short_landscape_filter',
        tester,
        () async {
          await launchTurqApp(tester);
          await tapItKey(
            tester,
            IntegrationTestKeys.navShort,
            settlePumps: 12,
          );
          expect(byItKey(IntegrationTestKeys.screenShort), findsOneWidget);

          final controller = ShortController.ensure();

          for (var i = 0; i < 20; i++) {
            await tester.pump(const Duration(milliseconds: 250));
            if (controller.shorts.length >= 10 || !controller.hasMore.value) {
              break;
            }
          }

          expect(
            controller.shorts.isNotEmpty,
            isTrue,
            reason: 'Short list should load before aspect ratio validation.',
          );

          final widePosts = controller.shorts
              .where((post) => post.aspectRatio.toDouble() > 1.2)
              .map((post) => '${post.docID}:${post.aspectRatio}')
              .toList(growable: false);

          expect(
            widePosts,
            isEmpty,
            reason: 'Short list should not include landscape posts wider than 1.2.',
          );
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
