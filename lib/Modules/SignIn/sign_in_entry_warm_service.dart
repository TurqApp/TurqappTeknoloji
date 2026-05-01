import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Repositories/job_home_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/market_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/scholarship_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/tutoring_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/explore_repository.dart';
import 'package:turqappv2/Core/Repositories/feed_manifest_repository.dart';
import 'package:turqappv2/Core/Repositories/short_manifest_repository.dart';
import 'package:turqappv2/Core/Services/pasaj_feature_gate.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';
import 'package:turqappv2/Services/current_user_service.dart';

const int _authEntryPasajWarmLimit = 6;
const List<String> _authEntryPasajListingTabs = <String>[
  PasajTabIds.market,
  PasajTabIds.jobFinder,
  PasajTabIds.scholarships,
  PasajTabIds.tutoring,
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
    return _PasajWarmResult(
      readyCount: items.length,
      warmedImages: warmedImages,
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

  static Future<void> ensureStarted({
    String source = 'unknown',
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

    Future<void> runPasajStep() async {
      final tabs = await _loadVisiblePasajListingTabs();
      debugPrint(
        '[AuthEntryWarm] status=start label=pasaj_tabs '
        'source=$source visibleTabs=${tabs.join(",")}',
      );
      if (tabs.isEmpty) {
        debugPrint(
          '[AuthEntryWarm] status=refresh_ok label=pasaj_tabs '
          'source=$source visibleTabs=0',
        );
        return;
      }
      for (final tabId in tabs) {
        final startedAt = DateTime.now();
        debugPrint(
          '[AuthEntryWarm] status=start label=pasaj_$tabId source=$source',
        );
        try {
          final result = await _warmPasajListingTab(tabId);
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
      debugPrint(
        '[AuthEntryWarm] status=refresh_ok label=pasaj_tabs '
        'source=$source visibleTabs=${tabs.length}',
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
}
