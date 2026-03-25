import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Modules/Story/StoryHighlights/story_highlight_model.dart';

part 'story_highlights_repository_models_part.dart';
part 'story_highlights_repository_lifecycle_part.dart';
part 'story_highlights_repository_query_part.dart';
part 'story_highlights_repository_action_part.dart';
part 'story_highlights_repository_cache_part.dart';

class StoryHighlightsRepository extends GetxService {
  static const Duration _ttl = Duration(hours: 6);
  static const String _prefsPrefix = 'story_highlights_repository_v1';

  SharedPreferences? _prefs;
  final Map<String, _CachedStoryHighlights> _memory = {};

  static StoryHighlightsRepository? maybeFind() {
    final isRegistered = Get.isRegistered<StoryHighlightsRepository>();
    if (!isRegistered) return null;
    return Get.find<StoryHighlightsRepository>();
  }

  static StoryHighlightsRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(StoryHighlightsRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    _StoryHighlightsRepositoryLifecyclePart(this).handleOnInit();
  }
}
