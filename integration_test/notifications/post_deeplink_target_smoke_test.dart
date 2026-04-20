import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/deep_link_service.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/FloodListing/flood_listing.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/photo_shorts.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/smoke_artifact_collector.dart';

const String _kDefaultPostShortId = 'ZFBUjTe';
const String _kConfiguredPostShortId =
    String.fromEnvironment('INTEGRATION_POST_SHORT_ID', defaultValue: _kDefaultPostShortId);

enum _PostDeepLinkTargetSurface {
  singleShort,
  floodListing,
  photoShorts,
  singlePost,
}

_PostDeepLinkTargetSurface _expectedSurfaceForPost(PostsModel model) {
  if (model.video.trim().isNotEmpty) {
    return _PostDeepLinkTargetSurface.singleShort;
  }
  if (model.floodCount > 1) {
    return _PostDeepLinkTargetSurface.floodListing;
  }
  if (model.img.isNotEmpty) {
    return _PostDeepLinkTargetSurface.photoShorts;
  }
  return _PostDeepLinkTargetSurface.singlePost;
}

Future<void> _expectPostSurface(
  WidgetTester tester,
  _PostDeepLinkTargetSurface surface,
) async {
  switch (surface) {
    case _PostDeepLinkTargetSurface.singleShort:
      await pumpUntilVisible(
        tester,
        byItKey(IntegrationTestKeys.screenSingleShort),
        maxPumps: 24,
      );
      expect(byItKey(IntegrationTestKeys.screenSingleShort), findsOneWidget);
      return;
    case _PostDeepLinkTargetSurface.floodListing:
      await pumpUntilVisible(
        tester,
        find.byType(FloodListing),
        maxPumps: 24,
      );
      expect(find.byType(FloodListing), findsOneWidget);
      return;
    case _PostDeepLinkTargetSurface.photoShorts:
      await pumpUntilVisible(
        tester,
        find.byType(PhotoShorts),
        maxPumps: 24,
      );
      expect(find.byType(PhotoShorts), findsOneWidget);
      return;
    case _PostDeepLinkTargetSurface.singlePost:
      await pumpUntilVisible(
        tester,
        byItKey(IntegrationTestKeys.screenSinglePost),
        maxPumps: 24,
      );
      expect(byItKey(IntegrationTestKeys.screenSinglePost), findsOneWidget);
      return;
  }
}

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Post deeplink opens the configured target post route',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'post_deeplink_target_smoke',
        tester,
        () async {
          await launchTurqApp(
            tester,
            relaxFeedFixtureDocRequirement: true,
          );
          await expectFeedScreen(tester);

          final shortId = _kConfiguredPostShortId.trim();
          expect(
            shortId,
            isNotEmpty,
            reason: 'INTEGRATION_POST_SHORT_ID must not be empty.',
          );

          final resolved = await ShortLinkService().resolve(
            type: 'post',
            id: shortId,
          );
          final data = Map<String, dynamic>.from(
            (resolved['data'] as Map? ?? const <String, dynamic>{}).map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          );
          final entityId = (data['entityId'] ?? '').toString().trim();
          expect(
            entityId,
            isNotEmpty,
            reason: 'Short link $shortId did not resolve to a post entity.',
          );

          final model = await PostRepository.ensure().fetchPostById(
            entityId,
            preferCache: false,
          );
          expect(
            model,
            isNotNull,
            reason: 'Resolved post entity $entityId could not be fetched.',
          );

          final expectedSurface = _expectedSurfaceForPost(model!);
          await ensureDeepLinkServiceStarted().handle(
            Uri.parse('https://turqapp.com/p/$shortId'),
          );
          await _expectPostSurface(tester, expectedSurface);
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
