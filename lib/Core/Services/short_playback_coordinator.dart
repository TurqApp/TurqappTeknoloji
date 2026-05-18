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
    if (defaultTargetPlatform == TargetPlatform.android) {
      return ShortPlaybackCoordinator(
        hotAhead: 1,
        hotBehind: 1,
        warmBehind: 3,
        maxAttachedPlayers: 5,
        budgetPolicy: PlayerBudgetPolicy.forSurface(
          PlayerSurfaceKind.shortFullscreen,
        ),
      );
    }
    return ShortPlaybackCoordinator(
      hotAhead: 1,
      hotBehind: 3,
      warmBehind: 3,
      maxAttachedPlayers: 5,
      budgetPolicy: PlayerBudgetPolicy.forSurface(
        PlayerSurfaceKind.shortFullscreen,
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
  int? _lastActiveIndex;
  int _lastDirection = 1;

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
    final previousIndex = _lastActiveIndex;
    var direction = _lastDirection;
    if (previousIndex != null) {
      if (currentIndex > previousIndex) {
        direction = 1;
      } else if (currentIndex < previousIndex) {
        direction = -1;
      }
    }
    _lastActiveIndex = currentIndex;
    _lastDirection = direction;

    final hotIndices = _resolveDirectionalHotIndices(
      currentIndex: currentIndex,
      itemCount: items.length,
      direction: direction,
    );
    final warmIndices = _resolveDirectionalWarmIndices(
      currentIndex: currentIndex,
      itemCount: items.length,
      direction: direction,
      hotIndices: hotIndices,
    );

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
      direction: direction,
    );

    return ShortPlaybackWindow(
      activeIndex: currentIndex,
      hotIndices: hotIndices,
      warmIndices: warmIndices,
      maxAttachedPlayers: maxAttachedPlayers,
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
    _lastActiveIndex = null;
    _lastDirection = 1;
  }

  Set<int> _resolveDirectionalHotIndices({
    required int currentIndex,
    required int itemCount,
    required int direction,
  }) {
    final behindCount = direction >= 0 ? hotBehind : hotAhead;
    final aheadCount = direction >= 0 ? hotAhead : hotBehind;
    final hotStart =
        currentIndex - behindCount < 0 ? 0 : currentIndex - behindCount;
    final hotEnd = currentIndex + aheadCount >= itemCount
        ? itemCount - 1
        : currentIndex + aheadCount;
    return <int>{for (int i = hotStart; i <= hotEnd; i++) i};
  }

  Set<int> _resolveDirectionalWarmIndices({
    required int currentIndex,
    required int itemCount,
    required int direction,
    required Set<int> hotIndices,
  }) {
    if (itemCount <= 0) return <int>{};
    final warmIndices = <int>{};
    if (direction >= 0) {
      final warmStart =
          currentIndex - warmBehind < 0 ? 0 : currentIndex - warmBehind;
      for (int i = warmStart; i < currentIndex; i++) {
        if (!hotIndices.contains(i)) warmIndices.add(i);
      }
      return warmIndices;
    }
    final warmEnd = currentIndex + warmBehind >= itemCount
        ? itemCount - 1
        : currentIndex + warmBehind;
    for (int i = currentIndex + 1; i <= warmEnd; i++) {
      if (!hotIndices.contains(i)) warmIndices.add(i);
    }
    return warmIndices;
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
    required int direction,
  }) {
    final playbackKpi = maybeFindPlaybackKpiService();
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
      '$direction',
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
        'direction': direction >= 0 ? 'forward' : 'backward',
        'maxAttachedPlayers': maxAttachedPlayers,
        'budgetMaxActivePlayers': budgetPolicy.maxActivePlayers,
        'budgetMaxWarmPlayers': budgetPolicy.maxWarmPlayers,
        'budgetMaxPreparedNeighbors': budgetPolicy.maxPreparedNeighbors,
      },
    );
  }
}
