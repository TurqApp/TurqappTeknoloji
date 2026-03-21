import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/playback_state_machine.dart';
import 'package:turqappv2/Core/Services/player_budget_policy.dart';
import 'package:turqappv2/Models/posts_model.dart';

class ShortPlaybackWindow {
  const ShortPlaybackWindow({
    required this.activeIndex,
    required this.hotIndices,
    required this.warmIndices,
    required this.maxAttachedPlayers,
  });

  final int activeIndex;
  final Set<int> hotIndices;
  final Set<int> warmIndices;
  final int maxAttachedPlayers;
}

class ShortPlaybackCoordinator {
  ShortPlaybackCoordinator({
    required this.hotAhead,
    required this.hotBehind,
    required this.warmBehind,
    required this.maxAttachedPlayers,
    required this.budgetPolicy,
  });

  factory ShortPlaybackCoordinator.forCurrentPlatform() {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    return ShortPlaybackCoordinator(
      // Android'de agresif hot pencere codec churn uretip ilk acilista
      // stop/play/pause dalgasi olusturuyordu. Pencereyi butceye yaklastir.
      hotAhead: isAndroid ? 1 : 5,
      hotBehind: isAndroid ? 0 : 2,
      warmBehind: isAndroid ? 1 : 5,
      maxAttachedPlayers: isAndroid ? 3 : 11,
      budgetPolicy: PlayerBudgetPolicy.forSurface(
        PlayerSurfaceKind.shortFullscreen,
        lowMemoryDevice: isAndroid,
      ),
    );
  }

  final int hotAhead;
  final int hotBehind;
  final int warmBehind;
  final int maxAttachedPlayers;
  final PlayerBudgetPolicy budgetPolicy;

  final Map<String, PlaybackStateMachine> _machineByDocId =
      <String, PlaybackStateMachine>{};
  String? _lastWindowSignature;

  ShortPlaybackWindow buildWindow(
    List<PostsModel> items,
    int rawIndex,
  ) {
    if (items.isEmpty) {
      return const ShortPlaybackWindow(
        activeIndex: 0,
        hotIndices: <int>{},
        warmIndices: <int>{},
        maxAttachedPlayers: 0,
      );
    }

    final currentIndex = rawIndex.clamp(0, items.length - 1);
    final hotStart =
        currentIndex - hotBehind < 0 ? 0 : currentIndex - hotBehind;
    final hotEnd = currentIndex + hotAhead >= items.length
        ? items.length - 1
        : currentIndex + hotAhead;
    final warmStart =
        currentIndex - warmBehind < 0 ? 0 : currentIndex - warmBehind;

    final hotIndices = <int>{};
    for (int i = hotStart; i <= hotEnd; i++) {
      hotIndices.add(i);
    }

    final warmIndices = <int>{};
    for (int i = warmStart; i < hotStart; i++) {
      warmIndices.add(i);
    }

    if (defaultTargetPlatform == TargetPlatform.android &&
        items.length > 1 &&
        currentIndex <= 1) {
      // Android'de ilk iki short'ta 0,1,2'yi ayni anda hot tutmak
      // ikinci videoda renderer stall uretmeye basliyordu. Ilk geciste
      // sadece ilk iki index'i sicak tutup ucuncuyu soguk birak.
      hotIndices
        ..clear()
        ..add(0)
        ..add(1);
      warmIndices.remove(0);
      warmIndices.remove(1);
    }

    _syncStates(
      items,
      currentIndex: currentIndex,
      hotIndices: hotIndices,
      warmIndices: warmIndices,
    );
    _trackWindow(
      items: items,
      activeIndex: currentIndex,
      hotIndices: hotIndices,
      warmIndices: warmIndices,
    );

    return ShortPlaybackWindow(
      activeIndex: currentIndex,
      hotIndices: hotIndices,
      warmIndices: warmIndices,
      maxAttachedPlayers: defaultTargetPlatform == TargetPlatform.android &&
              items.length > 1 &&
              currentIndex <= 1
          ? (maxAttachedPlayers < 4 ? 4 : maxAttachedPlayers)
          : maxAttachedPlayers,
    );
  }

  void markFirstFrame(String docId) {
    if (docId.trim().isEmpty) return;
    _machineByDocId[docId]?.transition(
      PlaybackSessionEvent.firstFrameRendered,
    );
  }

  void reset() {
    _machineByDocId.clear();
    _lastWindowSignature = null;
  }

  void _syncStates(
    List<PostsModel> items, {
    required int currentIndex,
    required Set<int> hotIndices,
    required Set<int> warmIndices,
  }) {
    final activeDocId = items[currentIndex].docID;
    final liveDocIds = items.map((item) => item.docID).toSet();

    _machineByDocId.removeWhere((docId, _) => !liveDocIds.contains(docId));

    for (int i = 0; i < items.length; i++) {
      final docId = items[i].docID;
      if (docId.isEmpty) continue;
      final machine = _machineByDocId.putIfAbsent(
        docId,
        () => PlaybackStateMachine(),
      );
      if (docId == activeDocId) {
        machine.transition(PlaybackSessionEvent.primeRequested);
        machine.transition(PlaybackSessionEvent.attachRequested);
        machine.transition(PlaybackSessionEvent.activateRequested);
        continue;
      }
      if (hotIndices.contains(i)) {
        machine.transition(PlaybackSessionEvent.primeRequested);
        machine.transition(PlaybackSessionEvent.attachRequested);
        continue;
      }
      if (warmIndices.contains(i)) {
        machine.transition(PlaybackSessionEvent.primeRequested);
        machine.transition(PlaybackSessionEvent.suspendRequested);
        continue;
      }
      machine.transition(PlaybackSessionEvent.disposeRequested);
    }
  }

  void _trackWindow({
    required List<PostsModel> items,
    required int activeIndex,
    required Set<int> hotIndices,
    required Set<int> warmIndices,
  }) {
    final playbackKpi = PlaybackKpiService.maybeFind();
    if (playbackKpi == null) return;
    final safeIndex =
        items.isEmpty ? 0 : activeIndex.clamp(0, items.length - 1);
    final activeDocId = items.isEmpty ? '' : items[safeIndex].docID;
    final signature = <String>[
      '${items.length}',
      '$safeIndex',
      activeDocId,
      hotIndices.join(','),
      warmIndices.join(','),
      '$maxAttachedPlayers',
    ].join('|');
    if (signature == _lastWindowSignature) return;
    _lastWindowSignature = signature;
    playbackKpi.track(
      PlaybackKpiEventType.playbackWindow,
      <String, dynamic>{
        'surface': 'short',
        'itemCount': items.length,
        'activeIndex': safeIndex,
        'activeDocId': activeDocId,
        'hotCount': hotIndices.length,
        'warmCount': warmIndices.length,
        'maxAttachedPlayers': maxAttachedPlayers,
        'budgetMaxActivePlayers': budgetPolicy.maxActivePlayers,
        'budgetMaxWarmPlayers': budgetPolicy.maxWarmPlayers,
        'budgetMaxPreparedNeighbors': budgetPolicy.maxPreparedNeighbors,
      },
    );
  }
}
