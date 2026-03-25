import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';

part 'post_reshare_listing_controller_runtime_part.dart';

class ReshareUserItem {
  const ReshareUserItem({
    required this.userID,
    required this.nickname,
    required this.fullName,
    required this.avatarUrl,
  });

  final String userID;
  final String nickname;
  final String fullName;
  final String avatarUrl;
}

class PostReshareListingController extends GetxController {
  PostReshareListingController({required this.postID});

  static const int _pageSize = 20;

  static PostReshareListingController ensure({required String tag}) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(PostReshareListingController(postID: tag), tag: tag);
  }

  static PostReshareListingController? maybeFind({required String tag}) {
    final isRegistered =
        Get.isRegistered<PostReshareListingController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PostReshareListingController>(tag: tag);
  }

  final String postID;
  final PostRepository _postRepository = PostRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final RxList<ReshareUserItem> reshareUsers = <ReshareUserItem>[].obs;
  final RxList<ReshareUserItem> quoteUsers = <ReshareUserItem>[].obs;
  final RxBool isLoadingReshares = false.obs;
  final RxBool isLoadingQuotes = false.obs;
  final RxBool isLoadingMoreReshares = false.obs;
  final RxBool isLoadingMoreQuotes = false.obs;
  final RxBool hasMoreReshares = true.obs;
  final RxBool hasMoreQuotes = true.obs;
  final ScrollController reshareScrollController = ScrollController();
  final ScrollController quoteScrollController = ScrollController();

  DocumentSnapshot<Map<String, dynamic>>? _lastReshareDoc;
  DocumentSnapshot<Map<String, dynamic>>? _lastQuoteSharerDoc;
  bool _fetchingReshares = false;
  bool _fetchingQuotes = false;
  bool _quotesInitialized = false;

  @override
  void onInit() {
    super.onInit();
    _PostReshareListingControllerRuntimePart.onInit(this);
  }

  @override
  void onClose() {
    _PostReshareListingControllerRuntimePart.onClose(this);
    super.onClose();
  }

  void ensureQuotesLoaded() {
    _PostReshareListingControllerRuntimePart.ensureQuotesLoaded(this);
  }

  Future<void> loadMoreReshares({bool initial = false}) {
    return _PostReshareListingControllerRuntimePart.loadMoreReshares(
      this,
      initial: initial,
    );
  }

  Future<void> loadMoreQuotes({bool initial = false}) {
    return _PostReshareListingControllerRuntimePart.loadMoreQuotes(
      this,
      initial: initial,
    );
  }
}
