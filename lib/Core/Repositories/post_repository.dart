import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/typesense_post_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../../Models/posts_model.dart';
import '../../Models/post_sharers_model.dart';
import '../../Services/post_count_manager.dart';
import '../../Services/post_interaction_service.dart';

part 'post_repository_interaction_part.dart';
part 'post_repository_query_part.dart';
part 'post_repository_sharing_part.dart';

class PostRepositoryState {
  PostRepositoryState(this.postId);

  final String postId;
  final RxBool liked = false.obs;
  final RxBool saved = false.obs;
  final RxBool reshared = false.obs;
  final RxBool reported = false.obs;
  final RxBool commented = false.obs;
  final Rxn<Map<String, dynamic>> latestPostData = Rxn<Map<String, dynamic>>();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? postSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? commentsSub;
  DateTime? interactionFetchedAt;
  bool interactionLoading = false;
  int retainCount = 0;
}

class PostSubcollectionPage {
  const PostSubcollectionPage({
    required this.userIds,
    required this.lastDoc,
    required this.hasMore,
  });

  final List<String> userIds;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}

class PostSharersPage {
  const PostSharersPage({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
  });

  final List<PostSharersModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}

class PostReshareEntry {
  const PostReshareEntry({
    required this.userId,
    required this.timeStamp,
    required this.quotedPost,
  });

  final String userId;
  final int timeStamp;
  final bool quotedPost;
}

class PostQueryPage {
  const PostQueryPage({
    required this.items,
    required this.lastDoc,
  });

  final List<PostsModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
}

class UserFeedReference {
  const UserFeedReference({
    required this.postId,
    required this.authorId,
    required this.timeStamp,
    required this.isCelebrity,
    required this.expiresAt,
  });

  final String postId;
  final String authorId;
  final int timeStamp;
  final bool isCelebrity;
  final int expiresAt;
}

class UserFeedReferencePage {
  const UserFeedReferencePage({
    required this.items,
    required this.lastDoc,
  });

  final List<UserFeedReference> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
}

class PostRepository extends GetxService {
  PostRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    PostInteractionService? interactionService,
    PostCountManager? countManager,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _interactionService =
            interactionService ?? PostInteractionService.ensure(),
        _countManager = countManager ?? PostCountManager.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PostInteractionService _interactionService;
  final PostCountManager _countManager;
  final TypesensePostService _typesensePostService =
      TypesensePostService.instance;

  static const Duration _interactionTtl = Duration(seconds: 30);
  static const Duration _stuckUploadingRepairAge = Duration(seconds: 10);
  static final Set<String> _uploadRepairInFlight = <String>{};
  bool get _shouldLogDiagnostics => kDebugMode && !IntegrationTestMode.enabled;
  final Map<String, PostRepositoryState> _states =
      <String, PostRepositoryState>{};
  final Map<String, List<PostSharersModel>> _postSharersMemory =
      <String, List<PostSharersModel>>{};
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

  static PostRepository? maybeFind() {
    final isRegistered = Get.isRegistered<PostRepository>();
    if (!isRegistered) return null;
    return Get.find<PostRepository>();
  }

  static PostRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(PostRepository(), permanent: true);
  }

  PostRepositoryState attachPost(
    PostsModel model, {
    bool loadInteraction = true,
    bool loadCommentMembership = true,
  }) =>
      _performAttachPost(
        model,
        loadInteraction: loadInteraction,
        loadCommentMembership: loadCommentMembership,
      );

  void releasePost(String postId) => _performReleasePost(postId);

  Future<bool> toggleLike(PostsModel model) => _performToggleLike(model);

  Future<bool> toggleSave(PostsModel model) => _performToggleSave(model);

  Future<bool> toggleReshare(PostsModel model) => _performToggleReshare(model);

  Future<void> refreshInteraction(String postId) =>
      _performRefreshInteraction(postId);

  Future<void> setArchived(PostsModel model, bool archived) =>
      _performSetArchived(model, archived);

  Future<Map<String, PostsModel>> fetchPostsByIds(
    List<String> postIds, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      _performFetchPostsByIds(
        postIds,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<Map<String, PostsModel>> fetchPostCardsByIds(
    List<String> postIds, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      _performFetchPostCardsByIds(
        postIds,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<PostQueryPage> fetchAgendaWindowPage({
    required int cutoffMs,
    required int nowMs,
    required int limit,
    DocumentSnapshot? startAfter,
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      _performFetchAgendaWindowPage(
        cutoffMs: cutoffMs,
        nowMs: nowMs,
        limit: limit,
        startAfter: startAfter,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<UserFeedReferencePage> fetchUserFeedReferences({
    required String uid,
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      _performFetchUserFeedReferences(
        uid: uid,
        limit: limit,
        startAfter: startAfter,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<List<String>> fetchCelebrityAuthorIds(
    List<String> authorIds, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      _performFetchCelebrityAuthorIds(
        authorIds,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<List<PostsModel>> fetchRecentPostsForAuthors(
    List<String> authorIds, {
    required int nowMs,
    required int cutoffMs,
    int perAuthorLimit = 3,
    int maxConcurrent = 12,
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      _performFetchRecentPostsForAuthors(
        authorIds,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        perAuthorLimit: perAuthorLimit,
        maxConcurrent: maxConcurrent,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<List<PostsModel>> fetchPublicScheduledIzBirakPosts({
    required int nowMs,
    required int cutoffMs,
    int limit = 40,
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      _performFetchPublicScheduledIzBirakPosts(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<List<PostsModel>> fetchRecentGlobalPosts({
    required int nowMs,
    required int cutoffMs,
    int limit = 40,
    int? maxTimeExclusive,
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      _performFetchRecentGlobalPosts(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        maxTimeExclusive: maxTimeExclusive,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<PostsModel?> fetchPostById(
    String postId, {
    bool preferCache = true,
  }) =>
      _performFetchPostById(postId, preferCache: preferCache);

  void mergeCachedPostData(String postId, Map<String, dynamic> patch) =>
      _performMergeCachedPostData(postId, patch);

  Future<Map<String, dynamic>?> fetchPostRawById(
    String postId, {
    bool preferCache = true,
  }) =>
      _performFetchPostRawById(postId, preferCache: preferCache);

  Future<QuerySnapshot<Map<String, dynamic>>> _getQueryWithSource(
    Query<Map<String, dynamic>> query, {
    required bool preferCache,
    required bool cacheOnly,
  }) =>
      _performGetQueryWithSource(
        query,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<String?> resolveDocumentIdByLegacyId(
    String legacyId, {
    bool preferCache = true,
  }) =>
      _performResolveDocumentIdByLegacyId(
        legacyId,
        preferCache: preferCache,
      );

  void _seedCounts(PostRepositoryState state, PostsModel model) =>
      _performSeedCounts(state, model);

  bool _isRenderableCard(PostsModel model) => _performIsRenderableCard(model);

  PostsModel _normalizeLikelyCompletedOwnPost(PostsModel model) =>
      _performNormalizeLikelyCompletedOwnPost(model);

  bool _shouldRepairStuckUploading(PostsModel model) =>
      _performShouldRepairStuckUploading(model);

  Future<void> _repairStuckUploadingPost(PostsModel model) =>
      _performRepairStuckUploadingPost(model);

  Map<String, dynamic> _typesenseDocToPostMap(
    Map<String, dynamic> doc,
    String docId,
  ) =>
      _performTypesenseDocToPostMap(doc, docId);

  void _startPostStream(PostRepositoryState state) =>
      _performStartPostStream(state);

  void _startCommentsMembershipStream(PostRepositoryState state) =>
      _performStartCommentsMembershipStream(state);

  Future<void> _ensureInteraction(
    PostRepositoryState state, {
    bool forceRefresh = false,
  }) =>
      _performEnsureInteraction(state, forceRefresh: forceRefresh);

  void _applyCountDelta({
    required String postId,
    required bool from,
    required bool to,
    required RxInt countRx,
    required num Function() readStat,
    required void Function(num value) writeStat,
  }) =>
      _performApplyCountDelta(
        postId: postId,
        from: from,
        to: to,
        countRx: countRx,
        readStat: readStat,
        writeStat: writeStat,
      );
}
