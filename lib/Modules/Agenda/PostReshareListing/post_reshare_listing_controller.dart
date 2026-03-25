import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';

part 'post_reshare_listing_controller_fields_part.dart';
part 'post_reshare_listing_controller_models_part.dart';
part 'post_reshare_listing_controller_runtime_part.dart';

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
  final _state = _PostReshareListingControllerState();

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
