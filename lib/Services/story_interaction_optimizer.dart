import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'story_interaction_optimizer_runtime_part.dart';

class StoryInteractionOptimizer extends GetxService {
  static StoryInteractionOptimizer? maybeFind() {
    final isRegistered = Get.isRegistered<StoryInteractionOptimizer>();
    if (!isRegistered) return null;
    return Get.find<StoryInteractionOptimizer>();
  }

  static StoryInteractionOptimizer ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(StoryInteractionOptimizer(), permanent: true);
  }

  static StoryInteractionOptimizer get to => ensure();
  final CurrentUserService _userService = CurrentUserService.instance;

  // Debouncing ve batching için
  Timer? _writeTimer;
  final Map<String, int> _pendingWrites = {};
  final Set<String> _pendingUsers = {};

  // Concurrency kontrolü
  bool _isWriting = false;
  final List<Future<void>> _pendingOperations = [];

  // Local cache için (public reactive access)
  final RxMap<String, bool> localStoryCache = <String, bool>{}.obs;
  final RxMap<String, int> localTimeCache = <String, int>{}.obs;

  // Stream subscriptions for cleanup
  StreamSubscription? _userSubscription;

  @override
  void onInit() {
    super.onInit();
    _StoryInteractionOptimizerRuntimePart(this).handleOnInit();
  }

  Future<void> markStoryViewed(
    String storyOwnerId,
    String storyId,
    int storyTime,
  ) =>
      _StoryInteractionOptimizerRuntimePart(this).markStoryViewed(
        storyOwnerId,
        storyId,
        storyTime,
      );

  bool areAllStoriesSeenCached(String storyOwnerId, List<dynamic> stories) =>
      _StoryInteractionOptimizerRuntimePart(this).areAllStoriesSeenCached(
        storyOwnerId,
        stories,
      );

  Future<void> forceFlush() =>
      _StoryInteractionOptimizerRuntimePart(this).forceFlush();

  Future<void> cleanup() =>
      _StoryInteractionOptimizerRuntimePart(this).cleanup();

  @override
  void onClose() {
    _StoryInteractionOptimizerRuntimePart(this).handleOnClose();
    super.onClose();
  }
}
