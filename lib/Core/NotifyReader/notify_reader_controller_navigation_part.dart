part of 'notify_reader_controller.dart';

extension NotifyReaderControllerNavigationPart on NotifyReaderController {
  Future<void> goToPost(
    String postID, {
    bool returnToNavbarOnClose = true,
  }) async {
    final lookup = await _lookupRepository.getPostLookup(postID);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('common.info'.tr, 'notify_reader.post_missing'.tr);
      if (returnToNavbarOnClose) {
        toNavbar();
      }
      return;
    }
    final model = lookup.model!;
    if (model.deletedPost == true) {
      AppSnackbar('common.info'.tr, 'notify_reader.post_removed'.tr);
      if (returnToNavbarOnClose) {
        toNavbar();
      }
      return;
    }

    if (model.floodCount > 1) {
      await Get.to<FloodListing>(() => FloodListing(mainModel: model));
    } else {
      await Get.to<SinglePost>(
        () => SinglePost(model: model, showComments: false),
      );
    }
    if (returnToNavbarOnClose) {
      toNavbar();
    }
  }

  Future<void> goToPostComments(
    String postID, {
    bool returnToNavbarOnClose = true,
  }) async {
    final lookup = await _lookupRepository.getPostLookup(postID);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('common.info'.tr, 'notify_reader.post_missing'.tr);
      if (returnToNavbarOnClose) {
        toNavbar();
      }
      return;
    }
    final model = lookup.model!;
    if (model.deletedPost == true) {
      AppSnackbar('common.info'.tr, 'notify_reader.post_removed'.tr);
      if (returnToNavbarOnClose) {
        toNavbar();
      }
      return;
    }

    await Get.to<SinglePost>(
      () => SinglePost(model: model, showComments: true),
    );
    if (returnToNavbarOnClose) {
      toNavbar();
    }
  }

  Future<void> goToProfile(
    String userID, {
    bool returnToNavbarOnClose = true,
  }) async {
    await Get.to<SocialProfile>(() => SocialProfile(userID: userID));
    if (returnToNavbarOnClose) {
      toNavbar();
    }
  }

  Future<void> goToChat(
    String chatID, {
    bool returnToNavbarOnClose = true,
  }) async {
    final lookup = await _lookupRepository.getChatLookup(chatID);
    final otherUser = lookup.otherUser;

    if (otherUser.isEmpty) {
      AppSnackbar('common.info'.tr, 'notify_reader.chat_missing'.tr);
      if (returnToNavbarOnClose) {
        toNavbar();
      }
      return;
    }

    await Get.to<ChatView>(() => ChatView(chatID: chatID, userID: otherUser));
    if (returnToNavbarOnClose) {
      toNavbar();
    }
  }

  Future<void> goToJob(
    String jobID, {
    bool returnToNavbarOnClose = true,
  }) async {
    final lookup = await _lookupRepository.getJobLookup(jobID);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('common.info'.tr, 'notify_reader.listing_missing'.tr);
      if (returnToNavbarOnClose) {
        toNavbar();
      }
      return;
    }
    final model = lookup.model!;
    await Get.to<JobDetails>(() => JobDetails(model: model));
    if (returnToNavbarOnClose) {
      toNavbar();
    }
  }

  Future<void> goToTutoring(
    String tutoringID, {
    bool returnToNavbarOnClose = true,
  }) async {
    final lookup = await _lookupRepository.getTutoringLookup(tutoringID);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('common.info'.tr, 'notify_reader.tutoring_missing'.tr);
      if (returnToNavbarOnClose) {
        toNavbar();
      }
      return;
    }
    final model = lookup.model!;
    await Get.to<TutoringDetail>(() => TutoringDetail(), arguments: model);
    if (returnToNavbarOnClose) {
      toNavbar();
    }
  }

  Future<void> goToMarket(
    String itemId, {
    bool returnToNavbarOnClose = true,
  }) async {
    final lookup = await _lookupRepository.getMarketLookup(itemId);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('common.info'.tr, 'notify_reader.listing_missing'.tr);
      if (returnToNavbarOnClose) {
        toNavbar();
      }
      return;
    }
    final model = lookup.model!;
    await Get.to(() => MarketDetailView(item: model));
    if (returnToNavbarOnClose) {
      toNavbar();
    }
  }

  void toNavbar() {
    unawaited(AppRootNavigationService.offAllToAuthenticatedHome());
  }
}
