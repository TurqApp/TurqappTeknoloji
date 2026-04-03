import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';

String _read(String relativePath) {
  return File(relativePath).readAsStringSync();
}

void main() {
  test('critical first-open read budgets stay bounded', () {
    expect(ReadBudgetRegistry.savedPostRefsInitialLimit, 20);
    expect(ReadBudgetRegistry.savedMarketRefsInitialLimit, 20);
    expect(ReadBudgetRegistry.followRelationPreviewInitialLimit, 30);
    expect(
      ReadBudgetRegistry.notificationsInboxInitialLimit,
      lessThanOrEqualTo(80),
    );
    expect(
      ReadBudgetRegistry.notificationsDeltaFetchLimit,
      lessThanOrEqualTo(40),
    );
    expect(
      ReadBudgetRegistry.userReshareMapInitialLimit,
      lessThanOrEqualTo(60),
    );
    expect(
      ReadBudgetRegistry.reshareUserPreviewInitialLimit,
      lessThanOrEqualTo(30),
    );
    expect(
      ReadBudgetRegistry.reshareFeedWarmupInitialLimit,
      lessThanOrEqualTo(60),
    );
    expect(
      ReadBudgetRegistry.antremanCategoryPoolInitialLimit,
      lessThanOrEqualTo(60),
    );
    expect(
      ReadBudgetRegistry.antremanSavedQuestionInitialLimit,
      lessThanOrEqualTo(60),
    );
    expect(ReadBudgetRegistry.marketHomeInitialLimit, lessThanOrEqualTo(40));
    expect(ReadBudgetRegistry.jobHomeInitialLimit, lessThanOrEqualTo(40));
    expect(
      ReadBudgetRegistry.scholarshipHomeInitialLimit,
      lessThanOrEqualTo(30),
    );
    expect(
      ReadBudgetRegistry.scholarshipRepositoryLatestLimit,
      lessThanOrEqualTo(40),
    );
    expect(
      ReadBudgetRegistry.scholarshipProviderSeedLimit,
      lessThanOrEqualTo(80),
    );
    expect(
      ReadBudgetRegistry.practiceExamHomeInitialLimit,
      lessThanOrEqualTo(30),
    );
    expect(
      ReadBudgetRegistry.practiceExamTypeInitialLimit,
      lessThanOrEqualTo(30),
    );
  });

  test('critical surfaces use shared read-budget contracts', () {
    final savedPostsSource = _read('lib/Services/user_post_link_service.dart');
    final followRepositorySource =
        _read('lib/Core/Repositories/follow_repository_query_part.dart');
    final notificationsRepositorySource = _read(
        'lib/Core/Repositories/notifications_repository_runtime_part.dart');
    final notificationsSnapshotSource = _read(
        'lib/Core/Repositories/notifications_snapshot_repository_query_part.dart');
    final marketSnapshotSource = _read(
        'lib/Core/Repositories/market_snapshot_repository_facade_part.dart');
    final marketHomeSource =
        _read('lib/Modules/Market/market_controller_home_part.dart');
    final jobHomeSource = _read(
        'lib/Core/Repositories/job_home_snapshot_repository_facade_part.dart');
    final jobFinderSource =
        _read('lib/Modules/JobFinder/job_finder_controller_support_part.dart');
    final scholarshipRepoSource =
        _read('lib/Core/Repositories/scholarship_repository_query_part.dart');
    final scholarshipProviderSource = _read(
      'lib/Modules/Education/Scholarships/ScholarshipProviders/scholarship_providers_controller_runtime_part.dart',
    );
    final practiceExamRepoSource =
        _read(
            'lib/Core/Repositories/practice_exam_snapshot_repository_runtime_part.dart');
    final postRepositorySharingSource =
        _read('lib/Core/Repositories/post_repository_sharing_part.dart');
    final reshareControllerSource =
        _read('lib/Modules/Agenda/agenda_controller_reshare_part.dart');
    final postContentControllerSource = _read(
        'lib/Modules/Agenda/Common/post_content_controller_profile_part.dart');
    final antremanRepositorySource =
        _read('lib/Core/Repositories/antreman_repository_query_part.dart');
    final antremanControllerSource = _read(
        'lib/Modules/Education/Antreman3/antreman_controller_actions_part.dart');

    expect(
      savedPostsSource,
      contains('ReadBudgetRegistry.savedPostRefsInitialLimit'),
    );
    expect(savedPostsSource, isNot(contains('_maxRefsPerFetch = 240')));

    expect(
      followRepositorySource,
      contains('ReadBudgetRegistry.followRelationPreviewInitialLimit'),
    );
    expect(followRepositorySource, contains('getRelationPreviewIds'));
    expect(followRepositorySource, contains('.limit(fetchLimit)'));

    expect(
      notificationsRepositorySource,
      contains('ReadBudgetRegistry.notificationsInboxInitialLimit'),
    );
    expect(
      notificationsRepositorySource,
      contains('ReadBudgetRegistry.notificationsDeltaFetchLimit'),
    );
    expect(notificationsRepositorySource, isNot(contains('int limit = 300')));
    expect(notificationsSnapshotSource,
        contains('ReadBudgetRegistry.notificationsInboxInitialLimit'));

    expect(
      marketSnapshotSource,
      contains('ReadBudgetRegistry.marketHomeInitialLimit'),
    );
    expect(marketHomeSource,
        contains('ReadBudgetRegistry.marketHomeInitialLimit'));
    expect(marketHomeSource, isNot(contains('limit: 120')));

    expect(jobHomeSource, contains('ReadBudgetRegistry.jobHomeInitialLimit'));
    expect(jobFinderSource, contains('ReadBudgetRegistry.jobHomeInitialLimit'));
    expect(jobFinderSource, isNot(contains('_fullBootstrapLimit = 150')));

    expect(
      scholarshipRepoSource,
      contains('ReadBudgetRegistry.scholarshipRepositoryLatestLimit'),
    );
    expect(
      scholarshipProviderSource,
      contains('ReadBudgetRegistry.scholarshipProviderSeedLimit'),
    );
    expect(scholarshipProviderSource, isNot(contains('limit: 200')));

    expect(
      practiceExamRepoSource,
      contains('ReadBudgetRegistry.practiceExamTypeInitialLimit'),
    );
    expect(
      practiceExamRepoSource,
      contains('.limit(ReadBudgetRegistry.practiceExamTypeInitialLimit)'),
    );

    expect(
      postRepositorySharingSource,
      contains('ReadBudgetRegistry.userReshareMapInitialLimit'),
    );
    expect(
      postRepositorySharingSource,
      contains('ReadBudgetRegistry.reshareUserPreviewInitialLimit'),
    );
    expect(postRepositorySharingSource, contains('limit: limit'));
    expect(reshareControllerSource,
        contains('ReadBudgetRegistry.reshareFeedWarmupInitialLimit'));
    expect(postContentControllerSource,
        contains('ReadBudgetRegistry.reshareUserPreviewInitialLimit'));
    expect(postContentControllerSource, isNot(contains('limit: 200')));

    expect(
      antremanRepositorySource,
      contains('ReadBudgetRegistry.antremanSavedQuestionInitialLimit'),
    );
    expect(
      antremanControllerSource,
      contains('ReadBudgetRegistry.antremanCategoryPoolInitialLimit'),
    );
    expect(antremanControllerSource,
        contains('ReadBudgetRegistry.antremanSavedQuestionInitialLimit'));
    expect(antremanControllerSource, isNot(contains('limit: 120')));
  });
}
