import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/performance_service.dart';
import 'package:turqappv2/Core/Services/qa_lab_bridge.dart';
import 'package:turqappv2/Core/Services/story_music_library_service.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Models/story_comment_model.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_model.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_user_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'story_repository_helpers_part.dart';
part 'story_repository_foundation_part.dart';
part 'story_repository_cache_part.dart';
part 'story_repository_deleted_part.dart';
part 'story_repository_engagement_part.dart';
part 'story_repository_models_part.dart';
part 'story_repository_facade_part.dart';
part 'story_repository_engagement_facade_part.dart';
part 'story_repository_cache_facade_part.dart';
part 'story_repository_query_facade_part.dart';
part 'story_repository_fields_part.dart';
part 'story_repository_support_part.dart';

class StoryRepository extends GetxService {
  static const Duration _storyRowCacheTtl = Duration(minutes: 15);
  static const Duration _deletedStoriesCacheTtl = Duration(hours: 12);
  static const int _deletedStoriesCacheLimit = 100;

  UserProfileCacheService get _userCache =>
      _resolveStoryRepositoryUserCache(this);
  final _StoryRepositoryState _state = _StoryRepositoryState();

  static DateTime get _storyExpiryCutoff =>
      _storyRepositoryResolveStoryExpiryCutoff();

  static StoryRepository ensure() => _ensureStoryRepository();

  static StoryRepository? maybeFind() => _maybeFindStoryRepository();
}
