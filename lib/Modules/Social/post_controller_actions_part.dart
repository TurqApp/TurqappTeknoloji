part of 'post_controller_library.dart';

void _initializePostState(PostController controller) {
  controller.getYorumCount(controller.postID);
  controller.getIlkPaylasan();
}

extension PostControllerActionsPart on PostController {
  Future<void> getYorumCount(String postID) async {
    final cached = await _postRepository.fetchPostById(postID);
    yorumCount.value = cached?.stats.commentCount.toInt() ?? yorumCount.value;
  }

  Future<void> getIlkPaylasan() async {}

  Future<void> begen(String postID) async {
    final userID = CurrentUserService.instance.effectiveUserId;
    if (userID.isEmpty) return;
    final nextLiked = await _postRepository.toggleLike(model);
    if (nextLiked) {
      if (!begeniler.contains(userID)) begeniler.add(userID);
    } else {
      begeniler.remove(userID);
    }
  }

  Future<void> begenme(String postID) async {
    final userID = CurrentUserService.instance.effectiveUserId;
    if (userID.isEmpty) return;

    final result = await _postRepository.toggleDislike(postID);
    if (!result.liked) {
      begeniler.remove(userID);
    }

    if (result.disliked) {
      if (!begenmeme.contains(userID)) begenmeme.add(userID);
    } else {
      begenmeme.remove(userID);
    }
  }

  Future<void> kayitEt(String postID) async {
    final userID = CurrentUserService.instance.effectiveUserId;
    if (userID.isEmpty) return;
    final nextSaved = await _postRepository.toggleSave(model);
    if (nextSaved) {
      if (!kaydedilenler.contains(userID)) kaydedilenler.add(userID);
    } else {
      kaydedilenler.remove(userID);
    }
  }

  Future<void> yenidenPaylas() async {}

  Future<void> yorumYap(BuildContext context, {VoidCallback? onClosed}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => buildPostCommentsSheet(
        context: context,
        postID: postID,
        userID: model.userID,
        collection: 'Sosyal',
        preferredHeightFactor: 0.95,
      ),
    );

    if (onClosed != null) {
      onClosed();
    }
  }

  Future<void> openShareSheet(BuildContext context) async {
    await ShareActionGuard.run(() async {
      try {
        final previewImage = model.thumbnail.trim().isNotEmpty
            ? model.thumbnail.trim()
            : (model.img.isNotEmpty ? model.img.first.trim() : null);
        final shortUrl = await ShortLinkService().getPostPublicUrl(
          postId: model.docID,
          desc: model.metin,
          imageUrl: previewImage,
          existingShortUrl: model.shortUrl,
        );
        await ShareLinkService.shareUrl(
          url: shortUrl,
          title: 'post.share_title'.tr,
          subject: 'post.share_title'.tr,
        );
      } catch (e) {
        print('Error downloading or sharing the image: $e');
      }
    });
  }

  Future<void> gizle(bool gizleValue) async {
    gizlendi.value = gizleValue;
  }

  Future<void> arsivle(bool arsivleValue) async {
    arsivlendi.value = arsivleValue;
  }

  Future<void> changePage(int index) async {
    pageCounter.value = index;
  }
}
