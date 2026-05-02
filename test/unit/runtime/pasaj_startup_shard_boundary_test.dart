import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auth-entry warm persists pasaj startup shards for all listing tabs',
      () async {
    final source = await File(
      'lib/Modules/SignIn/sign_in_entry_warm_service.dart',
    ).readAsString();

    expect(source.contains("_saveMarketStartupShard("), isTrue);
    expect(source.contains("_saveJobStartupShard("), isTrue);
    expect(source.contains("_saveScholarshipStartupShard("), isTrue);
    expect(source.contains("_saveTutoringStartupShard("), isTrue);

    expect(source.contains("surface: 'market'"), isTrue);
    expect(source.contains("surface: 'jobs'"), isTrue);
    expect(source.contains("surface: 'scholarships'"), isTrue);
    expect(source.contains("surface: 'tutoring'"), isTrue);
    expect(source.contains('ensureStartupSnapshotSeedPool().save('), isTrue);
    expect(source.contains('await _primePasajListingController(tabId);'), isTrue);
    expect(
      source.contains(
        'unawaited(_primePasajListingController(PasajTabIds.market));',
      ),
      isTrue,
    );
    expect(
      source.contains(
        'unawaited(_primePasajListingController(PasajTabIds.jobFinder));',
      ),
      isTrue,
    );
    expect(
      source.contains(
        'unawaited(_primePasajListingController(PasajTabIds.scholarships));',
      ),
      isTrue,
    );
    expect(
      source.contains(
        'unawaited(_primePasajListingController(PasajTabIds.tutoring));',
      ),
      isTrue,
    );
    expect(source.contains("PasajTabIds.market: 'market'"), isTrue);
    expect(source.contains("PasajTabIds.jobFinder: 'is_bul'"), isTrue);
    expect(source.contains("PasajTabIds.tutoring: 'ozel_ders'"), isTrue);
    expect(source.contains("'cevap_anahtari'"), isTrue);
    expect(source.contains("'online_sinav'"), isTrue);
    expect(source.contains("'denemeler'"), isTrue);
    expect(source.contains('await _warmPasajSlider(tabId);'), isTrue);
    expect(source.contains('_warmStandaloneEducationSliders()'), isTrue);
    expect(source.contains('if (isFirstLaunch) {'), isTrue);
  });

  test('first-launch pasaj warm fans out tabs and standalone sliders in parallel',
      () async {
    final source = await File(
      'lib/Modules/SignIn/sign_in_entry_warm_service.dart',
    ).readAsString();

    expect(
      source.contains('await Future.wait(<Future<void>>['),
      isTrue,
    );
    expect(
      source.contains("for (final sliderId in _authEntryStandaloneSliderIds)"),
      isTrue,
    );
    expect(
      source.contains('for (final tabId in tabs) warmTab(tabId),'),
      isTrue,
    );
  });

  test('pasaj controllers hydrate in-memory startup seed before async bootstrap',
      () async {
    final educationPasaj = await File(
      'lib/Modules/Education/education_controller_pasaj_part.dart',
    ).readAsString();
    final marketLifecycle = await File(
      'lib/Modules/Market/market_controller_lifecycle_part.dart',
    ).readAsString();
    final jobLifecycle = await File(
      'lib/Modules/JobFinder/job_finder_controller_lifecycle_part.dart',
    ).readAsString();
    final tutoringRuntime = await File(
      'lib/Modules/Education/Tutoring/tutoring_controller_runtime_part.dart',
    ).readAsString();
    final scholarshipsRuntime = await File(
      'lib/Modules/Education/Scholarships/scholarships_controller_runtime_part.dart',
    ).readAsString();

    expect(
      marketLifecycle.contains('_performHydrateMarketStartupSeedPoolSync();'),
      isTrue,
    );
    final jobSeedIndex = jobLifecycle.indexOf(
      '_performHydrateJobFinderStartupSeedPoolSync();',
    );
    final jobPrepareIndex = jobLifecycle.indexOf(
      'unawaited(_performPrepareStartupSurface());',
    );
    expect(jobSeedIndex, greaterThanOrEqualTo(0));
    expect(jobPrepareIndex, greaterThan(jobSeedIndex));

    final tutoringSeedIndex = tutoringRuntime.indexOf(
      'controller._performHydrateTutoringStartupSeedPoolSync();',
    );
    final tutoringBootstrapIndex = tutoringRuntime.indexOf(
      'unawaited(_bootstrapTutoringDataImpl(controller));',
    );
    expect(tutoringSeedIndex, greaterThanOrEqualTo(0));
    expect(tutoringBootstrapIndex, greaterThan(tutoringSeedIndex));

    final scholarshipsSeedIndex = scholarshipsRuntime.indexOf(
      '_performHydrateScholarshipsStartupSeedPoolSync();',
    );
    final scholarshipsBootstrapIndex = scholarshipsRuntime.indexOf(
      'unawaited(_bootstrapScholarships());',
    );
    expect(scholarshipsSeedIndex, greaterThanOrEqualTo(0));
    expect(scholarshipsBootstrapIndex, greaterThan(scholarshipsSeedIndex));
    expect(
      educationPasaj.contains('_ensurePasajListingControllersReady(nextVisible);'),
      isTrue,
    );
  });

  test('embedded pasaj surfaces prime all four listing controllers', () async {
    final educationPasaj = await File(
      'lib/Modules/Education/education_controller_pasaj_part.dart',
    ).readAsString();
    final marketView = await File(
      'lib/Modules/Market/market_view.dart',
    ).readAsString();
    final scholarshipsView = await File(
      'lib/Modules/Education/Scholarships/scholarships_view.dart',
    ).readAsString();
    final tutoringView = await File(
      'lib/Modules/Education/Tutoring/tutoring_view.dart',
    ).readAsString();
    final scholarshipsSupport = await File(
      'lib/Modules/Education/Scholarships/scholarships_controller_support_part.dart',
    ).readAsString();
    final tutoringSupport = await File(
      'lib/Modules/Education/Tutoring/tutoring_controller_support_part.dart',
    ).readAsString();

    expect(
      educationPasaj.contains(
        "maybeFindScholarshipsController()?.onPrimarySurfaceVisible()",
      ),
      isTrue,
    );
    expect(
      educationPasaj.contains(
        "maybeFindTutoringController()?.onPrimarySurfaceVisible()",
      ),
      isTrue,
    );
    expect(marketView.contains('controller.primePrimarySurfaceOnce();'), isTrue);
    expect(
      scholarshipsView.contains('controller.primePrimarySurfaceOnce();'),
      isTrue,
    );
    expect(
      tutoringView.contains('tutoringController.primePrimarySurfaceOnce();'),
      isTrue,
    );
    expect(
      scholarshipsSupport.contains(
        'Future<void> onPrimarySurfaceVisible() => prepareStartupSurface();',
      ),
      isTrue,
    );
    expect(
      tutoringSupport.contains(
        'Future<void> onPrimarySurfaceVisible() => prepareStartupSurface();',
      ),
      isTrue,
    );
  });

  test('sign-in selection 1 starts pasaj fastlane before global warm finishes',
      () async {
    final source = await File(
      'lib/Modules/SignIn/sign_in_controller_support_part.dart',
    ).readAsString();

    final selectionGateIndex = source.indexOf('if (currentSelection == 1)');
    final pasajFastlaneIndex = source.indexOf(
      'SignInEntryWarmService.ensurePasajStarted(',
    );
    final globalWarmIndex = source.indexOf(
      'await SignInEntryWarmService.ensureStarted(',
    );

    expect(selectionGateIndex, greaterThanOrEqualTo(0));
    expect(pasajFastlaneIndex, greaterThan(selectionGateIndex));
    expect(globalWarmIndex, greaterThan(pasajFastlaneIndex));
    expect(source.contains('isFirstLaunch: authEntryIsFirstLaunch,'), isTrue);
  });

  test('tutoring startup hydrates shard before opening snapshot stream',
      () async {
    final runtimeSource = await File(
      'lib/Modules/Education/Tutoring/tutoring_controller_runtime_part.dart',
    ).readAsString();
    final dataSource = await File(
      'lib/Modules/Education/Tutoring/tutoring_controller_data_part.dart',
    ).readAsString();

    final hydrateIndex =
        runtimeSource.indexOf('await controller._performHydrateTutoringStartupShard();');
    final openIndex = runtimeSource.indexOf('controller._tutoringSnapshotRepository');

    expect(hydrateIndex, greaterThanOrEqualTo(0));
    expect(openIndex, greaterThan(hydrateIndex));
    expect(dataSource.contains("surface: 'tutoring'"), isTrue);
    expect(dataSource.contains('_persistTutoringStartupShard()'), isTrue);
  });

  test('scholarships startup hydrates shard before opening snapshot stream',
      () async {
    final runtimeSource = await File(
      'lib/Modules/Education/Scholarships/scholarships_controller_runtime_part.dart',
    ).readAsString();
    final dataSource = await File(
      'lib/Modules/Education/Scholarships/scholarships_controller_data_part.dart',
    ).readAsString();

    final hydrateIndex =
        runtimeSource.indexOf('await _performHydrateScholarshipsStartupShard();');
    final openIndex = runtimeSource.indexOf('_scholarshipSnapshotRepository');

    expect(hydrateIndex, greaterThanOrEqualTo(0));
    expect(openIndex, greaterThan(hydrateIndex));
    expect(dataSource.contains("surface: 'scholarships'"), isTrue);
    expect(dataSource.contains('_persistScholarshipsStartupShard()'), isTrue);
  });
}
