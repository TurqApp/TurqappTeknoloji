import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/explore_repository.dart';
import 'package:turqappv2/Modules/Agenda/AgendaContent/agenda_content_controller.dart';
import 'package:turqappv2/Modules/Agenda/TopTags/top_tags_repository.dart';
import 'package:turqappv2/Core/Services/ContentPolicy/content_policy.dart';
import 'package:turqappv2/Core/Services/IndexPool/index_pool_store.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/storage_budget_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/Utils/account_status_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Models/hashtag_model.dart';
import 'package:turqappv2/Models/ogrenci_model.dart';
import 'package:turqappv2/Services/user_analytics_service.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';

import '../../Models/posts_model.dart';

part 'explore_controller_recent_search_part.dart';
part 'explore_controller_feed_part.dart';
part 'explore_controller_runtime_part.dart';
part 'explore_controller_search_part.dart';
part 'explore_controller_support_part.dart';
part 'explore_controller_api_part.dart';

class ExploreController extends GetxController {
  static ExploreController ensure() =>
      maybeFind() ?? Get.put(ExploreController());
  static ExploreController? maybeFind() => Get.isRegistered<ExploreController>()
      ? Get.find<ExploreController>()
      : null;

  final selection = 0.obs;
  final pageController = PageController(initialPage: 0);
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  final searchText = ''.obs;
  final searchedList = <OgrenciModel>[].obs,
      recentSearchUsers = <OgrenciModel>[].obs;
  final searchedHashtags = <HashtagModel>[].obs,
      searchedTags = <HashtagModel>[].obs;
  final showAllRecent = false.obs,
      isKeyboardOpen = false.obs,
      isSearchMode = false.obs;
  final scrollController = ScrollController();
  final trendingTags = <HashtagModel>[].obs;
  final ScrollController exploreScroll = ScrollController();
  final explorePosts = <PostsModel>[].obs;
  DocumentSnapshot? lastExploreDoc;
  final exploreHasMore = true.obs, exploreIsLoading = false.obs;
  final RxBool explorePreviewSuspended = false.obs;
  final RxInt explorePreviewFocusIndex = (-1).obs;
  final ScrollController videoScroll = ScrollController();
  final exploreVideos = <PostsModel>[].obs;
  DocumentSnapshot? lastVideoDoc;
  final videoHasMore = true.obs, videoIsLoading = false.obs;
  final ScrollController photoScroll = ScrollController();
  final explorePhotos = <PostsModel>[].obs;
  DocumentSnapshot? lastPhotoDoc;
  final photoHasMore = true.obs, photoIsLoading = false.obs;
  final ScrollController floodsScroll = ScrollController();
  final exploreFloods = <PostsModel>[].obs;
  DocumentSnapshot? lastFloodsDoc;
  final floodsHasMore = true.obs, floodsIsLoading = false.obs;
  final RxInt floodsVisibleIndex = (-1).obs;
  int? lastFloodVisibleIndex;
  String? _pendingFloodDocId;
  final showScrollToTop = false.obs;
  final RxSet<String> followingIDs = <String>{}.obs;
  int _exploreEmptyScans = 0,
      _videoEmptyScans = 0,
      _photoEmptyScans = 0,
      _floodsEmptyScans = 0;
  Worker? _currentUserWorker;
  Timer? _searchDebounce;
  int _searchRequestId = 0;
  String _recentSearchReloadKey = '';

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
