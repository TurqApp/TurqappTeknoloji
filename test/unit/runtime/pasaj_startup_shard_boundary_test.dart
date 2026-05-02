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
  });

  test('pasaj controllers hydrate in-memory startup seed before async bootstrap',
      () async {
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
