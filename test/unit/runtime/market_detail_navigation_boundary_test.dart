import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('market detail opens stay behind navigation service', () async {
    final serviceSource = await File(
      'lib/Core/Services/market_detail_navigation_service.dart',
    ).readAsString();
    final checkedSources = <String, String>{
      'market controller':
          'lib/Modules/Market/market_controller_actions_part.dart',
      'market offers':
          'lib/Modules/Market/market_offers_view_actions_part.dart',
      'market saved': 'lib/Modules/Market/market_saved_view_actions_part.dart',
      'market my items':
          'lib/Modules/Market/market_my_items_view_actions_part.dart',
      'deep link': 'lib/Core/Services/deep_link_service_open_part.dart',
      'education feed cta':
          'lib/Core/Services/education_feed_cta_navigation_service.dart',
      'notify reader':
          'lib/Core/NotifyReader/notify_reader_controller_navigation_part.dart',
      'profile market':
          'lib/Modules/Profile/MyProfile/profile_view_market_part.dart',
      'social profile market':
          'lib/Modules/SocialProfile/social_profile_sections_actions_part.dart',
      'saved posts market': 'lib/Modules/Profile/SavedPosts/saved_posts.dart',
    };

    expect(serviceSource, contains('openMarketDetail'));
    expect(serviceSource, contains('MarketDetailView(item: item)'));

    for (final entry in checkedSources.entries) {
      final source = await File(entry.value).readAsString();

      expect(
        source,
        contains('openMarketDetail('),
        reason: '${entry.key} should delegate market detail opening.',
      );
      expect(
        source,
        isNot(contains('Get.to(() => MarketDetailView')),
        reason: '${entry.key} should not open MarketDetailView directly.',
      );
    }
  });

  test('feature code does not open market detail outside approved boundaries',
      () async {
    const approvedFiles = <String>{
      'lib/Core/Services/market_detail_navigation_service.dart',
      'lib/Modules/Market/market_detail_view_ui_part.dart',
    };
    final violations = <String>[];

    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (approvedFiles.contains(normalizedPath)) continue;

      final source = await file.readAsString();
      if (!source.contains('MarketDetailView(item:')) continue;
      violations.add(normalizedPath);
    }

    expect(
      violations,
      isEmpty,
      reason: 'Market detail route creation should stay behind '
          'MarketDetailNavigationService; the detail page owns its related-card '
          'self-navigation until that local flow gets a separate wrapper.',
    );
  });

  test('market entry opens stay behind navigation service', () async {
    final serviceSource = await File(
      'lib/Core/Services/market_detail_navigation_service.dart',
    ).readAsString();
    final educationActionsSource = await File(
      'lib/Modules/Education/education_view_actions_part.dart',
    ).readAsString();
    final educationBodySource = await File(
      'lib/Modules/Education/education_view_body_part.dart',
    ).readAsString();
    final marketControllerSource = await File(
      'lib/Modules/Market/market_controller_actions_part.dart',
    ).readAsString();
    final marketMyItemsSource = await File(
      'lib/Modules/Market/market_my_items_view_actions_part.dart',
    ).readAsString();
    final marketDetailActionsSource = await File(
      'lib/Modules/Market/market_detail_view_actions_part.dart',
    ).readAsString();
    final marketDetailContentSource = await File(
      'lib/Modules/Market/market_detail_view_content_part.dart',
    ).readAsString();

    expect(serviceSource, contains('openMarketCreate'));
    expect(serviceSource, contains('openMarketMyItems'));
    expect(serviceSource, contains('openMarketOffers'));
    expect(serviceSource, contains('openMarketSaved'));
    expect(serviceSource, contains('openMarketSearch'));

    expect(educationActionsSource, contains('openMarketSearch()'));
    expect(educationActionsSource, contains('openMarketCreate()'));
    expect(educationBodySource, contains('openMarketSearch()'));
    expect(marketControllerSource, contains('openMarketCreate()'));
    expect(marketControllerSource, contains('openMarketMyItems()'));
    expect(marketControllerSource, contains('openMarketSaved()'));
    expect(marketControllerSource, contains('openMarketOffers()'));
    expect(marketMyItemsSource, contains('openMarketCreate(initialItem:'));
    expect(
        marketDetailActionsSource, contains('openMarketCreate(initialItem:'));
    expect(marketDetailContentSource, contains('openMarketOffers()'));

    final outsideNavigationService = [
      educationActionsSource,
      educationBodySource,
      marketControllerSource,
      marketMyItemsSource,
      marketDetailActionsSource,
      marketDetailContentSource,
    ].join('\n');

    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => const MarketSearchView')),
    );
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => const MarketCreateView')),
    );
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => MarketCreateView')),
    );
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => const MarketMyItemsView')),
    );
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => const MarketSavedView')),
    );
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => const MarketOffersView')),
    );
  });
}
