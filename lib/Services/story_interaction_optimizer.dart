import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'story_interaction_optimizer_facade_part.dart';
part 'story_interaction_optimizer_fields_part.dart';
part 'story_interaction_optimizer_runtime_part.dart';

class StoryInteractionOptimizer extends GetxService {
  static StoryInteractionOptimizer? maybeFind() =>
      _maybeFindStoryInteractionOptimizer();

  static StoryInteractionOptimizer ensure() =>
      _ensureStoryInteractionOptimizer();

  static StoryInteractionOptimizer get to => ensure();
  final _state = _StoryInteractionOptimizerState();

  @override
  void onInit() {
    super.onInit();
    _handleStoryInteractionOptimizerInit(this);
  }

  Future<void> markStoryViewed(
    String storyOwnerId,
    String storyId,
    int storyTime,
  ) =>
      _markStoryInteractionViewed(
        this,
        storyOwnerId,
        storyId,
        storyTime,
      );

  bool areAllStoriesSeenCached(String storyOwnerId, List<dynamic> stories) =>
      _readAllStoriesSeenCached(
        this,
        storyOwnerId,
        stories,
      );

  Future<void> forceFlush() => _forceFlushStoryInteraction(this);

  Future<void> cleanup() => _cleanupStoryInteraction(this);

  @override
  void onClose() {
    _handleStoryInteractionOptimizerClose(this);
    super.onClose();
  }
}
