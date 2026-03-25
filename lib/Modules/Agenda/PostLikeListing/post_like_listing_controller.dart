import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

part 'post_like_listing_controller_models_part.dart';
part 'post_like_listing_controller_runtime_part.dart';

class PostLikeListingController extends GetxController {
  PostLikeListingController({required this.postID});
  static const int _pageSize = 20;

  static PostLikeListingController ensure({required String tag}) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(PostLikeListingController(postID: tag), tag: tag);
  }

  static PostLikeListingController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<PostLikeListingController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PostLikeListingController>(tag: tag);
  }

  final String postID;
  final PostRepository _postRepository = PostRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final RxList<LikeUserItem> users = <LikeUserItem>[].obs;
  final RxList<LikeUserItem> filteredUsers = <LikeUserItem>[].obs;
  final RxString query = ''.obs;
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  DocumentSnapshot<Map<String, dynamic>>? _lastLikeDoc;
  bool _isFetching = false;

  @override
  void onInit() {
    super.onInit();
    _PostLikeListingControllerRuntimePart(this).handleOnInit();
  }

  @override
  void onClose() {
    _PostLikeListingControllerRuntimePart(this).handleOnClose();
    super.onClose();
  }

  void onSearchChanged(String value) =>
      _PostLikeListingControllerRuntimePart(this).onSearchChanged(value);

  Future<void> getLikes() =>
      _PostLikeListingControllerRuntimePart(this).getLikes();
}
