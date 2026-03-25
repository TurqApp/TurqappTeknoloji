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
part 'story_repository_engagement_facade_part.dart';

class StoryRepository extends GetxService {
  static const Duration _storyRowCacheTtl = Duration(minutes: 15);
  static const Duration _deletedStoriesCacheTtl = Duration(hours: 12);
  static const int _deletedStoriesCacheLimit = 100;
  Duration get storyRowCacheTtlInternal => _storyRowCacheTtl;
  Duration get deletedStoriesCacheTtlInternal => _deletedStoriesCacheTtl;
  int get deletedStoriesCacheLimitInternal => _deletedStoriesCacheLimit;

  UserProfileCacheService get _userCache => _resolveUserCache();

  final UserRepository _userRepository = UserRepository.ensure();
  final VisibilityPolicyService _visibilityPolicy =
      VisibilityPolicyService.ensure();

  String? _storyRowCacheDirectoryPath;
  SharedPreferences? _prefs;

  static DateTime get _storyExpiryCutoff =>
      _storyRepositoryResolveStoryExpiryCutoff();
  DateTime get storyExpiryCutoffInternal => _storyExpiryCutoff;

  int _asEpochMillis(dynamic value, {int fallback = 0}) =>
      _performAsEpochMillis(value, fallback: fallback);

  List<Map<String, dynamic>> _normalizeStoryElements(dynamic raw) =>
      _performNormalizeStoryElements(raw);

  static StoryRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(StoryRepository(), permanent: true);
  }

  static StoryRepository? maybeFind() {
    final isRegistered = Get.isRegistered<StoryRepository>();
    if (!isRegistered) return null;
    return Get.find<StoryRepository>();
  }

  Future<void> _ensureInitialized() => _performEnsureInitialized();

  String? _storyRowCachePathForOwner(String ownerUid) =>
      _performStoryRowCachePathForOwner(ownerUid);

  Future<StoryFetchResult> fetchStoryUsers({
    required int limit,
    required bool cacheFirst,
    required String currentUid,
    required List<String> blockedUserIds,
  }) =>
      _performFetchStoryUsers(
        limit: limit,
        cacheFirst: cacheFirst,
        currentUid: currentUid,
        blockedUserIds: blockedUserIds,
      );

  Future<void> saveStoryRowCache(
    List<StoryUserModel> list, {
    required String ownerUid,
  }) =>
      _performSaveStoryRowCache(list, ownerUid: ownerUid);

  Future<List<StoryUserModel>> restoreStoryRowCache({
    required String ownerUid,
    bool allowExpired = false,
  }) =>
      _performRestoreStoryRowCache(
        ownerUid: ownerUid,
        allowExpired: allowExpired,
      );

  Future<void> clearStoryRowCacheForCurrentUser(String ownerUid) =>
      _performClearStoryRowCacheForCurrentUser(ownerUid);

  Future<void> invalidateStoryCachesForUser(
    String uid, {
    bool clearDeletedStories = true,
  }) =>
      _performInvalidateStoryCachesForUser(
        uid,
        clearDeletedStories: clearDeletedStories,
      );

  Future<Map<String, StoryModel>> fetchStoriesByIds(List<String> storyIds) =>
      _performFetchStoriesByIds(storyIds);

  Future<StoryModel?> fetchStoryById(
    String storyId, {
    bool preferCache = true,
  }) =>
      _performFetchStoryById(
        storyId,
        preferCache: preferCache,
      );

  Future<List<StoryModel>> fetchActiveStoriesByMusicId(
    String musicId, {
    int limit = 60,
  }) =>
      _performFetchActiveStoriesByMusicId(
        musicId,
        limit: limit,
      );

  Future<void> markExpiredStoriesDeleted(String uid) =>
      _performMarkExpiredStoriesDeleted(uid);

  Future<String> softDeleteStory(
    String storyId, {
    String reason = 'manual',
  }) =>
      _performSoftDeleteStory(
        storyId,
        reason: reason,
      );

  Future<void> restoreDeletedStory(String storyId) =>
      _performRestoreDeletedStory(storyId);

  Future<void> permanentlyDeleteStory(String storyId) =>
      _performPermanentlyDeleteStory(storyId);

  Future<String> repostDeletedStory(StoryModel story) =>
      _performRepostDeletedStory(story);

  Future<DeletedStoryCachePayload?> restoreDeletedStoriesCache(String uid) =>
      _performRestoreDeletedStoriesCache(uid);

  Future<void> persistDeletedStoriesCache({
    required String uid,
    required List<StoryModel> stories,
    required Map<String, int> deletedAtById,
    required Map<String, String> deleteReasonById,
  }) =>
      _performPersistDeletedStoriesCache(
        uid: uid,
        stories: stories,
        deletedAtById: deletedAtById,
        deleteReasonById: deleteReasonById,
      );

  Future<void> clearDeletedStoriesCache(String uid) =>
      _performClearDeletedStoriesCache(uid);

  Future<DeletedStoryCachePayload> fetchDeletedStories(String uid) =>
      _performFetchDeletedStories(uid);

  Future<Map<String, dynamic>?> getStoryRaw(
    String storyId, {
    bool preferCache = true,
  }) =>
      _performGetStoryRaw(
        storyId,
        preferCache: preferCache,
      );

  Future<List<StoryModel>> getStoriesForUser(
    String userId, {
    bool preferCache = true,
    bool includeDeleted = false,
  }) =>
      _performGetStoriesForUser(
        userId,
        preferCache: preferCache,
        includeDeleted: includeDeleted,
      );

  Future<List<String>> fetchStoryViewerIds(
    String storyId, {
    int limit = 50,
  }) =>
      _performFetchStoryViewerIds(
        storyId,
        limit: limit,
      );

  Future<int> fetchStoryViewerCount(String storyId) =>
      _performFetchStoryViewerCount(storyId);

  Future<List<StoryCommentModel>> fetchStoryComments(
    String storyId, {
    int limit = 50,
  }) =>
      _performFetchStoryComments(
        storyId,
        limit: limit,
      );

  Future<int> fetchStoryCommentCount(String storyId) =>
      _performFetchStoryCommentCount(storyId);
}
