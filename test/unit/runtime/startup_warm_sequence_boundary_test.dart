import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auth-entry warm keeps manifest, quota, flood, pasaj order stable',
      () async {
    final source = await File(
      'lib/Modules/SignIn/sign_in_entry_warm_service.dart',
    ).readAsString();

    final feedIndex =
        source.indexOf("await runStep(\n          'feed_manifest'");
    final shortIndex =
        source.indexOf("await runStep(\n          'short_manifest'");
    final quotaIndex =
        source.indexOf('await _startQuotaFillAfterShortReady();');
    final floodIndex = source.indexOf('final floodFuture = runFloodStep()');
    final pasajIndex = source.indexOf('await runPasajStep();');
    final floodAwaitIndex = source.indexOf('await floodFuture;');

    expect(feedIndex, greaterThanOrEqualTo(0));
    expect(shortIndex, greaterThan(feedIndex));
    expect(quotaIndex, greaterThan(shortIndex));
    expect(floodIndex, greaterThan(quotaIndex));
    expect(pasajIndex, greaterThan(floodIndex));
    expect(floodAwaitIndex, greaterThan(pasajIndex));
    expect(
      source.contains("await runStep(\n          'quota_fill',"),
      isFalse,
      reason: 'quota fill must stay on dedicated helper after short manifest',
    );
  });

  test('post-auth warm keeps quota fill after short and before flood',
      () async {
    final source = await File(
      'lib/Modules/SignIn/sign_in_application_service.dart',
    ).readAsString();

    final feedIndex = source.indexOf(
      "await runStep('feed_manifest', _warmFeedManifestAfterAuth);",
    );
    final shortIndex = source
        .indexOf("await runStep('short_manifest', _warmShortsAfterAuth);");
    final quotaIndex = source.indexOf(
      "await runStep('quota_fill', _startQuotaFillAfterShortReady);",
    );
    final floodIndex = source.indexOf(
      "await runStep('flood_manifest', _warmFloodManifestAfterAuth);",
    );

    expect(feedIndex, greaterThanOrEqualTo(0));
    expect(shortIndex, greaterThan(feedIndex));
    expect(quotaIndex, greaterThan(shortIndex));
    expect(floodIndex, greaterThan(quotaIndex));
  });

  test('guest startup warm keeps feed, short, flood manifest order stable',
      () async {
    final source = await File(
      'lib/Modules/Splash/splash_post_login_warmup.dart',
    ).readAsString();

    final feedIndex = source.indexOf(
      "await runStep(\n        'feed_manifest',",
    );
    final shortIndex = source.indexOf(
      "await runStep(\n        'short_manifest',",
    );
    final floodIndex = source.indexOf('await runFloodStep();');

    expect(feedIndex, greaterThanOrEqualTo(0));
    expect(shortIndex, greaterThan(feedIndex));
    expect(floodIndex, greaterThan(shortIndex));
  });

  test('auth-entry warm keeps exact required labels wired in order', () async {
    final source = await File(
      'lib/Modules/SignIn/sign_in_entry_warm_service.dart',
    ).readAsString();

    expect(source.contains("'feed_manifest'"), isTrue);
    expect(source.contains("'short_manifest'"), isTrue);
    expect(source.contains('label=flood_manifest'), isTrue);
    expect(source.contains('label=pasaj_tabs'), isTrue);
    expect(source.contains('PasajTabIds.market'), isTrue);
    expect(source.contains('PasajTabIds.jobFinder'), isTrue);
    expect(source.contains('PasajTabIds.scholarships'), isTrue);
    expect(source.contains('PasajTabIds.tutoring'), isTrue);
    expect(source.contains("label=pasaj_\$tabId"), isTrue);
    expect(
      source.indexOf('await _startQuotaFillAfterShortReady();'),
      greaterThan(source.indexOf("'short_manifest'")),
    );
    expect(
      source.indexOf("final floodFuture = runFloodStep()"),
      greaterThan(source.indexOf('await _startQuotaFillAfterShortReady();')),
    );
  });

  test('sign-in route forwards first-launch state into auth-entry warm', () async {
    final splashSource = await File(
      'lib/Modules/Splash/splash_view_startup_part.dart',
    ).readAsString();
    final navigationSource = await File(
      'lib/Runtime/app_root_navigation_service.dart',
    ).readAsString();
    final signInSource = await File(
      'lib/Modules/SignIn/sign_in.dart',
    ).readAsString();

    expect(
      splashSource.contains('isFirstLaunch: _startupIsFirstLaunch,'),
      isTrue,
    );
    expect(
      navigationSource.contains('bool isFirstLaunch = false,'),
      isTrue,
    );
    expect(
      navigationSource.contains("isFirstLaunch: isFirstLaunch,"),
      isTrue,
    );
    expect(signInSource.contains('this.isFirstLaunch = false,'), isTrue);
    expect(
      signInSource.contains(
        'controller.setAuthEntryIsFirstLaunch(widget.isFirstLaunch);',
      ),
      isTrue,
    );
  });
}
