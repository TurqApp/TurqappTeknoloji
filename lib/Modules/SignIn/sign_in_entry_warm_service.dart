import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:turqappv2/Core/Slider/slider_catalog.dart';
import 'package:turqappv2/Core/Repositories/job_home_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Core/Repositories/market_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/scholarship_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/tutoring_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/explore_repository.dart';
import 'package:turqappv2/Core/Repositories/feed_manifest_repository.dart';
import 'package:turqappv2/Core/Repositories/short_manifest_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/startup_snapshot_shard_store.dart';
import 'package:turqappv2/Core/Services/CacheFirst/startup_snapshot_seed_pool.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/storage_budget_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/pasaj_feature_gate.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/slider_cache_service.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder_controller.dart';
import 'package:turqappv2/Modules/Market/market_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Themes/app_assets.dart';

const int _authEntryPasajWarmLimit = 6;
const List<String> _authEntryPasajListingTabs = <String>[
  PasajTabIds.market,
  PasajTabIds.jobFinder,
  PasajTabIds.scholarships,
  PasajTabIds.tutoring,
];

const Map<String, String> _authEntryPasajSliderIds = <String, String>{
  PasajTabIds.market: 'market',
  PasajTabIds.jobFinder: 'is_bul',
  PasajTabIds.tutoring: 'ozel_ders',
};

const List<String> _authEntryStandaloneSliderIds = <String>[
  'cevap_anahtari',
  'online_sinav',
  'denemeler',
];

const List<String> _authEntryStaticSliderAssets = <String>[
  AppAssets.test1,
  AppAssets.test2,
  AppAssets.test3,
  AppAssets.previous1,
  AppAssets.previous2,
  AppAssets.previous3,
  AppAssets.previous4,
];

class _PasajWarmResult {
  const _PasajWarmResult({
    required this.readyCount,
    required this.warmedImages,
  });

  final int readyCount;
  final int warmedImages;
}

class SignInEntryWarmService {
  SignInEntryWarmService._();

  static Future<void>? _inFlight;
  static Future<void>? _pasajInFlight;
  static Future<void>? _sliderAssetPrecacheInFlight;

  static Future<void> _startQuotaFillAfterShortReady() async {
    try {
      final preferences = ensureLocalPreferenceRepository();
      final quotaGb = normalizeStorageBudgetPlanGb(
        await preferences.getInt('offline_cache_quota_gb') ?? 3,
      );
      await StorageBudgetManager.maybeFind()?.applyPlanGb(quotaGb);
      await SegmentCacheManager.maybeFind()?.setUserLimitGB(quotaGb);
      final prefetch = maybeFindPrefetchScheduler();
      if (prefetch != null) {
        prefetch.resetWifiQuotaFillPlan();
        await prefetch.ensureWifiQuotaFillPlan();
      }
      debugPrint(
        '[AuthEntryWarm] status=refresh_ok label=quota_fill source=short_manifest quotaGb=$quotaGb',
      );
    } catch (error) {
      debugPrint(
        '[AuthEntryWarm] status=refresh_fail label=quota_fill source=short_manifest error=$error',
      );
    }
  }

  static Future<List<String>> _loadVisiblePasajListingTabs() async {
    final resolved = await loadEffectivePasajVisibility(
      preferCache: true,
      forceRefresh: false,
    );
    final snapshot = normalizePasajVisibilitySnapshot(
      resolved,
      defaultValue: false,
    );
    return _authEntryPasajListingTabs
        .where((tabId) => snapshot[tabId] ?? false)
        .toList(growable: false);
  }

  static Future<int> _warmPreviewImages(Iterable<String> urls) async {
    var warmed = 0;
    final seen = <String>{};
    for (final rawUrl in urls) {
      final url = rawUrl.trim();
      if (url.isEmpty || !seen.add(url)) {
        continue;
      }
      try {
        await TurqImageCacheManager.warmUrl(url);
        warmed++;
      } catch (_) {}
    }
    return warmed;
  }

  static Future<_PasajWarmResult> _warmMarketTab() async {
    final userId = CurrentUserService.instance.effectiveUserId;
    var resource = await MarketSnapshotRepository.ensure()
        .openHome(
          userId: userId,
          limit: _authEntryPasajWarmLimit,
        )
        .first;
    var items = (resource.data ?? const <MarketItemModel>[])
        .where((item) => item.status == 'active')
        .take(_authEntryPasajWarmLimit)
        .toList(growable: false);
    if (items.isNotEmpty) {
      await _saveMarketStartupShard(
        userId: userId,
        items: items,
      );
      unawaited(_primePasajListingController(PasajTabIds.market));
    }
    if (items.length < _authEntryPasajWarmLimit || resource.isStale) {
      resource = await MarketSnapshotRepository.ensure().loadHome(
        userId: userId,
        limit: _authEntryPasajWarmLimit,
        forceSync: true,
      );
      items = (resource.data ?? const <MarketItemModel>[])
          .where((item) => item.status == 'active')
          .take(_authEntryPasajWarmLimit)
          .toList(growable: false);
    }
    final warmedImages = await _warmPreviewImages(<String>[
      for (final item in items) item.coverImageUrl,
      for (final item in items) ...item.imageUrls.take(1),
      for (final item in items) item.sellerPhotoUrl,
    ]);
    await _saveMarketStartupShard(
      userId: userId,
      items: items,
    );
    return _PasajWarmResult(
      readyCount: items.length,
      warmedImages: warmedImages,
    );
  }

  static Future<_PasajWarmResult> _warmJobTab() async {
    final userId = CurrentUserService.instance.effectiveUserId;
    var resource = await ensureJobHomeSnapshotRepository()
        .openHome(
          userId: userId,
          limit: _authEntryPasajWarmLimit,
        )
        .first;
    var items = (resource.data ?? const <JobModel>[])
        .where((item) => !item.ended)
        .take(_authEntryPasajWarmLimit)
        .toList(growable: false);
    if (items.isNotEmpty) {
      await _saveJobStartupShard(
        userId: userId,
        items: items,
      );
      unawaited(_primePasajListingController(PasajTabIds.jobFinder));
    }
    if (items.length < _authEntryPasajWarmLimit || resource.isStale) {
      resource = await ensureJobHomeSnapshotRepository().loadHome(
        userId: userId,
        limit: _authEntryPasajWarmLimit,
        forceSync: true,
      );
      items = (resource.data ?? const <JobModel>[])
          .where((item) => !item.ended)
          .take(_authEntryPasajWarmLimit)
          .toList(growable: false);
    }
    final warmedImages = await _warmPreviewImages(<String>[
      for (final item in items) item.logo,
      for (final item in items) item.authorAvatarUrl,
    ]);
    await _saveJobStartupShard(
      userId: userId,
      items: items,
    );
    return _PasajWarmResult(
      readyCount: items.length,
      warmedImages: warmedImages,
    );
  }

  static Future<_PasajWarmResult> _warmScholarshipTab() async {
    final userId = CurrentUserService.instance.effectiveUserId;
    var resource = await ensureScholarshipSnapshotRepository()
        .openHome(
          userId: userId,
          limit: _authEntryPasajWarmLimit,
        )
        .first;
    var items = (resource.data?.items ?? const <Map<String, dynamic>>[])
        .take(_authEntryPasajWarmLimit)
        .toList(growable: false);
    if (items.isNotEmpty) {
      await _saveScholarshipStartupShard(
        userId: userId,
        items: items,
      );
      unawaited(_primePasajListingController(PasajTabIds.scholarships));
    }
    if (items.length < _authEntryPasajWarmLimit || resource.isStale) {
      resource = await ensureScholarshipSnapshotRepository().loadHome(
        userId: userId,
        limit: _authEntryPasajWarmLimit,
        forceSync: true,
      );
      items = (resource.data?.items ?? const <Map<String, dynamic>>[])
          .take(_authEntryPasajWarmLimit)
          .toList(growable: false);
    }
    final warmedImages = await _warmPreviewImages(<String>[
      for (final item in items)
        ...<String>[
          (((item['model'] as dynamic)?.img) ?? item['img'] ?? '').toString(),
          (((item['model'] as dynamic)?.img2) ?? item['img2'] ?? '').toString(),
          (((item['model'] as dynamic)?.logo) ?? item['logo'] ?? '').toString(),
          (item['avatarUrl'] ?? item['authorAvatarUrl'] ?? '').toString(),
        ],
    ]);
    await _saveScholarshipStartupShard(
      userId: userId,
      items: items,
    );
    return _PasajWarmResult(
      readyCount: items.length,
      warmedImages: warmedImages,
    );
  }

  static Future<_PasajWarmResult> _warmTutoringTab() async {
    final userId = CurrentUserService.instance.effectiveUserId;
    var resource = await ensureTutoringSnapshotRepository()
        .openHome(
          userId: userId,
          limit: _authEntryPasajWarmLimit,
        )
        .first;
    var items = (resource.data ?? const <TutoringModel>[])
        .take(_authEntryPasajWarmLimit)
        .toList(growable: false);
    if (items.isNotEmpty) {
      await _saveTutoringStartupShard(
        userId: userId,
        items: items,
      );
      unawaited(_primePasajListingController(PasajTabIds.tutoring));
    }
    if (items.length < _authEntryPasajWarmLimit || resource.isStale) {
      resource = await ensureTutoringSnapshotRepository().loadHome(
        userId: userId,
        limit: _authEntryPasajWarmLimit,
        forceSync: true,
      );
      items = (resource.data ?? const <TutoringModel>[])
          .take(_authEntryPasajWarmLimit)
          .toList(growable: false);
    }
    final warmedImages = await _warmPreviewImages(<String>[
      for (final item in items) ...(item.imgs ?? const <String>[]).take(1),
      for (final item in items) item.avatarUrl,
    ]);
    await _saveTutoringStartupShard(
      userId: userId,
      items: items,
    );
    return _PasajWarmResult(
      readyCount: items.length,
      warmedImages: warmedImages,
    );
  }

  static Future<void> _saveMarketStartupShard({
    required String userId,
    required List<MarketItemModel> items,
  }) async {
    final actorId = userId.trim();
    if (actorId.isEmpty) return;
    final startupItems = items
        .take(ReadBudgetRegistry.marketStartupShardLimit)
        .toList(growable: false);
    final store = ensureStartupSnapshotShardStore();
    if (startupItems.isEmpty) {
      ensureStartupSnapshotSeedPool().clear(surface: 'market', userId: actorId);
      await store.clear(surface: 'market', userId: actorId);
      return;
    }
    ensureStartupSnapshotSeedPool().save(
      surface: 'market',
      userId: actorId,
      itemCount: items.length,
      limit: ReadBudgetRegistry.marketStartupShardLimit,
      source: 'auth_entry_warm',
      payload: <String, dynamic>{
        'items':
            startupItems.map((item) => item.toJson()).toList(growable: false),
      },
    );
    await store.save(
      surface: 'market',
      userId: actorId,
      itemCount: items.length,
      limit: ReadBudgetRegistry.marketStartupShardLimit,
      source: 'auth_entry_warm',
      payload: <String, dynamic>{
        'items':
            startupItems.map((item) => item.toJson()).toList(growable: false),
      },
    );
  }

  static Future<void> _saveJobStartupShard({
    required String userId,
    required List<JobModel> items,
  }) async {
    final actorId = userId.trim();
    if (actorId.isEmpty) return;
    final startupItems = items
        .take(ReadBudgetRegistry.jobStartupShardLimit)
        .toList(growable: false);
    final store = ensureStartupSnapshotShardStore();
    if (startupItems.isEmpty) {
      ensureStartupSnapshotSeedPool().clear(surface: 'jobs', userId: actorId);
      await store.clear(surface: 'jobs', userId: actorId);
      return;
    }
    ensureStartupSnapshotSeedPool().save(
      surface: 'jobs',
      userId: actorId,
      itemCount: items.length,
      limit: ReadBudgetRegistry.jobStartupShardLimit,
      source: 'auth_entry_warm',
      payload: <String, dynamic>{
        'jobs': startupItems
            .map(
              (job) => <String, dynamic>{
                'docID': job.docID,
                'data': job.toMap(),
              },
            )
            .toList(growable: false),
      },
    );
    await store.save(
      surface: 'jobs',
      userId: actorId,
      itemCount: items.length,
      limit: ReadBudgetRegistry.jobStartupShardLimit,
      source: 'auth_entry_warm',
      payload: <String, dynamic>{
        'jobs': startupItems
            .map(
              (job) => <String, dynamic>{
                'docID': job.docID,
                'data': job.toMap(),
              },
            )
            .toList(growable: false),
      },
    );
  }

  static Future<void> _saveScholarshipStartupShard({
    required String userId,
    required List<Map<String, dynamic>> items,
  }) async {
    final actorId = userId.trim();
    if (actorId.isEmpty) return;
    final startupItems =
        items.take(_authEntryPasajWarmLimit).toList(growable: false);
    final store = ensureStartupSnapshotShardStore();
    if (startupItems.isEmpty) {
      ensureStartupSnapshotSeedPool().clear(
        surface: 'scholarships',
        userId: actorId,
      );
      await store.clear(surface: 'scholarships', userId: actorId);
      return;
    }
    ensureStartupSnapshotSeedPool().save(
      surface: 'scholarships',
      userId: actorId,
      itemCount: items.length,
      limit: _authEntryPasajWarmLimit,
      source: 'auth_entry_warm',
      payload: <String, dynamic>{
        'items': startupItems
            .map((item) {
              final model = item['model'];
              return <String, dynamic>{
                'docId': item['docId'] ?? '',
                'type': item['type'] ?? '',
                'model': model is IndividualScholarshipsModel
                    ? model.toJson()
                    : <String, dynamic>{},
                'userData': Map<String, dynamic>.from(
                  item['userData'] as Map? ?? const <String, dynamic>{},
                ),
                'likesCount': item['likesCount'] ?? 0,
                'bookmarksCount': item['bookmarksCount'] ?? 0,
                'timeStamp': item['timeStamp'] ?? 0,
                'isSummary': item['isSummary'] ?? false,
              };
            })
            .toList(growable: false),
      },
    );
    await store.save(
      surface: 'scholarships',
      userId: actorId,
      itemCount: items.length,
      limit: _authEntryPasajWarmLimit,
      source: 'auth_entry_warm',
      payload: <String, dynamic>{
        'items': startupItems
            .map((item) {
              final model = item['model'];
              return <String, dynamic>{
                'docId': item['docId'] ?? '',
                'type': item['type'] ?? '',
                'model': model is IndividualScholarshipsModel
                    ? model.toJson()
                    : <String, dynamic>{},
                'userData': Map<String, dynamic>.from(
                  item['userData'] as Map? ?? const <String, dynamic>{},
                ),
                'likesCount': item['likesCount'] ?? 0,
                'bookmarksCount': item['bookmarksCount'] ?? 0,
                'timeStamp': item['timeStamp'] ?? 0,
                'isSummary': item['isSummary'] ?? false,
              };
            })
            .toList(growable: false),
      },
    );
  }

  static Future<void> _saveTutoringStartupShard({
    required String userId,
    required List<TutoringModel> items,
  }) async {
    final actorId = userId.trim();
    if (actorId.isEmpty) return;
    final startupItems =
        items.take(_authEntryPasajWarmLimit).toList(growable: false);
    final store = ensureStartupSnapshotShardStore();
    if (startupItems.isEmpty) {
      ensureStartupSnapshotSeedPool().clear(
        surface: 'tutoring',
        userId: actorId,
      );
      await store.clear(surface: 'tutoring', userId: actorId);
      return;
    }
    ensureStartupSnapshotSeedPool().save(
      surface: 'tutoring',
      userId: actorId,
      itemCount: items.length,
      limit: _authEntryPasajWarmLimit,
      source: 'auth_entry_warm',
      payload: <String, dynamic>{
        'items': startupItems
            .map(
              (item) => <String, dynamic>{
                'docID': item.docID,
                'data': item.toJson(),
              },
            )
            .toList(growable: false),
      },
    );
    await store.save(
      surface: 'tutoring',
      userId: actorId,
      itemCount: items.length,
      limit: _authEntryPasajWarmLimit,
      source: 'auth_entry_warm',
      payload: <String, dynamic>{
        'items': startupItems
            .map(
              (item) => <String, dynamic>{
                'docID': item.docID,
                'data': item.toJson(),
              },
            )
            .toList(growable: false),
      },
    );
  }

  static Future<_PasajWarmResult> _warmPasajListingTab(String tabId) {
    switch (tabId) {
      case PasajTabIds.market:
        return _warmMarketTab();
      case PasajTabIds.jobFinder:
        return _warmJobTab();
      case PasajTabIds.scholarships:
        return _warmScholarshipTab();
      case PasajTabIds.tutoring:
        return _warmTutoringTab();
      default:
        return Future<_PasajWarmResult>.value(
          const _PasajWarmResult(readyCount: 0, warmedImages: 0),
        );
    }
  }

  static Future<void> _primePasajListingController(String tabId) async {
    debugPrint(
      '[AuthEntryWarm] status=controller_prime_start label=pasaj_$tabId',
    );
    switch (tabId) {
      case PasajTabIds.market:
        final controller = ensureMarketController(permanent: true);
        await controller.prepareStartupSurface(allowBackgroundRefresh: false);
        break;
      case PasajTabIds.jobFinder:
        final controller = ensureJobFinderController(permanent: true);
        await controller.prepareStartupSurface(allowBackgroundRefresh: false);
        break;
      case PasajTabIds.scholarships:
        final controller = ensureScholarshipsController(permanent: true);
        await controller.prepareStartupSurface(allowBackgroundRefresh: false);
        break;
      case PasajTabIds.tutoring:
        final controller = ensureTutoringController(permanent: true);
        await controller.prepareStartupSurface(allowBackgroundRefresh: false);
        break;
    }
    debugPrint(
      '[AuthEntryWarm] status=controller_prime_ok label=pasaj_$tabId',
    );
  }

  static Future<void> _warmSliderCache(
    String sliderId, {
    required String logLabel,
  }) async {
    final normalizedSliderId = sliderId.trim();
    if (normalizedSliderId.isEmpty) return;
    debugPrint('[AuthEntryWarm] status=slider_warm_start label=$logLabel');
    final cache = SliderCacheService();
    final snapshot = await cache.readSnapshot(normalizedSliderId);
    if (snapshot.hasItems) {
      await cache.warmImages(snapshot.items);
    }
    try {
      await cache.refreshAndCacheItems(normalizedSliderId);
    } catch (error) {
      debugPrint(
        '[AuthEntryWarm] status=slider_warm_refresh_fail '
        'label=$logLabel sliderId=$normalizedSliderId error=$error',
      );
    }
    debugPrint('[AuthEntryWarm] status=slider_warm_ok label=$logLabel');
  }

  static Future<void> _warmPasajSlider(String tabId) async {
    final sliderId = _authEntryPasajSliderIds[tabId]?.trim() ?? '';
    if (sliderId.isEmpty) return;
    await _warmSliderCache(
      sliderId,
      logLabel: 'pasaj_$tabId',
    );
  }

  static Future<void> _warmStandaloneEducationSliders() async {
    await Future.wait(<Future<void>>[
      for (final sliderId in _authEntryStandaloneSliderIds)
        _warmSliderCache(
          sliderId,
          logLabel: 'education_slider_$sliderId',
        ),
    ]);
  }

  static Future<void> ensureSliderAssetPrecaching(BuildContext context) {
    final existing = _sliderAssetPrecacheInFlight;
    if (existing != null) {
      return existing;
    }

    final future = () async {
      debugPrint('[AuthEntryWarm] status=slider_asset_precache_start');
      final seen = <String>{};
      final assetPaths = <String>[
        for (final sliderId in _authEntryPasajSliderIds.values)
          ...SliderCatalog.defaultImagesFor(sliderId),
        for (final sliderId in _authEntryStandaloneSliderIds)
          ...SliderCatalog.defaultImagesFor(sliderId),
        ..._authEntryStaticSliderAssets,
      ];
      for (final rawPath in assetPaths) {
        final path = rawPath.trim();
        if (path.isEmpty || !seen.add(path)) continue;
        try {
          await precacheImage(AssetImage(path), context);
        } catch (_) {}
      }
      debugPrint(
        '[AuthEntryWarm] status=slider_asset_precache_ok count=${seen.length}',
      );
    }();

    _sliderAssetPrecacheInFlight = future.whenComplete(() {
      if (identical(_sliderAssetPrecacheInFlight, future)) {
        _sliderAssetPrecacheInFlight = null;
      }
    });
    return _sliderAssetPrecacheInFlight!;
  }

  static Future<void> ensureStarted({
    String source = 'unknown',
    bool isFirstLaunch = false,
  }) {
    final existing = _inFlight;
    if (existing != null) {
      debugPrint('[AuthEntryWarm] status=join_existing source=$source');
      return existing;
    }

    Future<void> runStep(
      String label,
      Future<void> Function() action,
    ) async {
      final startedAt = DateTime.now();
      debugPrint('[AuthEntryWarm] status=start label=$label source=$source');
      try {
        await action();
        debugPrint(
          '[AuthEntryWarm] status=refresh_ok label=$label '
          'source=$source elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds}',
        );
      } catch (error) {
        debugPrint(
          '[AuthEntryWarm] status=refresh_fail label=$label '
          'source=$source elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds} '
          'error=$error',
        );
        rethrow;
      }
    }

    Future<void> runFloodStep() async {
      final startedAt = DateTime.now();
      debugPrint('[AuthEntryWarm] status=start label=flood_manifest source=$source');
      try {
        final roots = await ExploreRepository.ensure().ensureFloodManifestStoreReady();
        if (roots <= 0) {
          throw StateError('flood_manifest_empty');
        }
        debugPrint(
          '[AuthEntryWarm] status=refresh_ok label=flood_manifest '
          'source=$source elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds} roots=$roots',
        );
      } catch (error) {
        debugPrint(
          '[AuthEntryWarm] status=refresh_fail label=flood_manifest '
          'source=$source elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds} '
          'error=$error',
        );
        rethrow;
      }
    }

    Future<void> runPasajStep() {
      return ensurePasajStarted(
        source: source,
        isFirstLaunch: isFirstLaunch,
      );
    }

    final future = () async {
      debugPrint('[AuthEntryWarm] status=begin source=$source');
      try {
        await runStep(
          'feed_manifest',
          () async {
            await ensureFeedManifestRepository().syncActiveWindowIfChanged();
            await ensureFeedManifestRepository().warmStartupWindow();
          },
        );
        await runStep(
          'short_manifest',
          () => ensureShortManifestRepository().warmStartupWindow(),
        );
        await _startQuotaFillAfterShortReady();
        final floodFuture = runFloodStep().catchError((error, stackTrace) {
          return;
        });
        await runPasajStep();
        await floodFuture;
      } finally {
        debugPrint('[AuthEntryWarm] status=finish source=$source');
      }
    }();

    _inFlight = future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
    return _inFlight!;
  }

  static Future<void> ensurePasajStarted({
    String source = 'unknown',
    bool isFirstLaunch = false,
  }) {
    final existing = _pasajInFlight;
    if (existing != null) {
      debugPrint('[AuthEntryWarm] status=join_existing_pasaj source=$source');
      return existing;
    }

    Future<void> runPasajStepInternal() async {
      final standaloneSliderFuture = isFirstLaunch
          ? _warmStandaloneEducationSliders()
          : Future<void>.value();
      final tabs = await _loadVisiblePasajListingTabs();
      debugPrint(
        '[AuthEntryWarm] status=start label=pasaj_tabs '
        'source=$source visibleTabs=${tabs.join(",")}',
      );
      if (tabs.isEmpty) {
        await standaloneSliderFuture;
        debugPrint(
          '[AuthEntryWarm] status=refresh_ok label=pasaj_tabs '
          'source=$source visibleTabs=0',
        );
        return;
      }
      Future<void> warmTab(String tabId) async {
        final startedAt = DateTime.now();
        debugPrint(
          '[AuthEntryWarm] status=start label=pasaj_$tabId source=$source',
        );
        try {
          final result = await _warmPasajListingTab(tabId);
          if (isFirstLaunch) {
            await _warmPasajSlider(tabId);
          }
          await _primePasajListingController(tabId);
          debugPrint(
            '[AuthEntryWarm] status=refresh_ok label=pasaj_$tabId '
            'source=$source elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds} '
            'readyCount=${result.readyCount} warmedImages=${result.warmedImages}',
          );
        } catch (error) {
          debugPrint(
            '[AuthEntryWarm] status=refresh_fail label=pasaj_$tabId '
            'source=$source elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds} '
            'error=$error',
          );
          rethrow;
        }
      }
      await Future.wait(<Future<void>>[
        standaloneSliderFuture,
        for (final tabId in tabs) warmTab(tabId),
      ]);
      debugPrint(
        '[AuthEntryWarm] status=refresh_ok label=pasaj_tabs '
        'source=$source visibleTabs=${tabs.length}',
      );
    }

    final future = () async {
      await runPasajStepInternal();
    }();

    _pasajInFlight = future.whenComplete(() {
      if (identical(_pasajInFlight, future)) {
        _pasajInFlight = null;
      }
    });
    return _pasajInFlight!;
  }
}
