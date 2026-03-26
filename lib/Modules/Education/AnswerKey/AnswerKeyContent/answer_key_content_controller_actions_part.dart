part of 'answer_key_content_controller.dart';

extension AnswerKeyContentControllerActionsPart on AnswerKeyContentController {
  void navigateToPreview(BuildContext context) {
    _updateViewCount();
    Get.to(() => BookletPreview(model: model));
  }

  void editBooklet(BuildContext context) {
    Get.to(
      () => CreateBook(
        onBack: onUpdate,
        existingBook: model,
      ),
    );
  }

  void deleteBooklet(BuildContext context) {
    _showDeleteBottomSheet(context);
  }

  void openBooklet(BuildContext context) {
    if (isOwner) {
      _showOwnerActions(context);
      return;
    }
    navigateToPreview(context);
  }

  void _showOwnerActions(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text(
          model.baslik,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontFamily: 'MontserratBold',
          ),
        ),
        content: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: CachedNetworkImage(
            imageUrl: model.cover,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) =>
                const Icon(Icons.broken_image),
          ),
        ),
        backgroundColor: Colors.white,
        actions: [
          GestureDetector(
            onTap: () {
              Get.back();
              navigateToPreview(context);
            },
            child: Container(
              alignment: Alignment.center,
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'answer_key.inspect'.tr,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.purpleAccent,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Get.back();
              Future.delayed(const Duration(milliseconds: 300), () {
                deleteBooklet(context);
              });
            },
            child: Container(
              alignment: Alignment.center,
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'answer_key.delete_book'.tr,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.red,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Get.back();
              editBooklet(context);
            },
            child: Container(
              alignment: Alignment.center,
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'common.edit'.tr,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.indigo,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: Get.back,
            child: Container(
              alignment: Alignment.center,
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'common.cancel'.tr,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> shareBooklet() async {
    final currentUid = _resolveAnswerKeyContentCurrentUidFacade();
    final canShareFeed =
        AdminAccessService.isKnownAdminSync() || model.userID == currentUid;
    if (!canShareFeed) {
      AppSnackbar('common.warning'.tr, 'answer_key.share_owner_only'.tr);
      return;
    }
    final shareId = 'answer-key:${model.docID}';

    try {
      await ShareActionGuard.run(() async {
        final shortUrl =
            ShortLinkService().getEducationPublicUrlForImmediateShare(
          shareId: shareId,
          title: model.baslik,
          desc: model.yayinEvi.isNotEmpty
              ? model.yayinEvi
              : '${model.sinavTuru} ${'answer_key.book_answer_key_desc'.tr}',
          imageUrl: model.cover.isNotEmpty ? model.cover : null,
        );

        await ShareLinkService.shareUrl(
          url: shortUrl,
          title: model.baslik,
          subject: model.baslik,
        );
      });
    } catch (_) {
      AppSnackbar('common.error'.tr, 'training.share_failed'.tr);
    }
  }

  void showBottomSheet(BuildContext context) {
    if (model.userID != _resolveAnswerKeyContentCurrentUidFacade()) {
      _showSpamBottomSheet(context);
    } else {
      _showDeleteBottomSheet(context);
    }
  }

  void _showSpamBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Obx(
          () => FractionallySizedBox(
            heightFactor: 0.15,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'answer_key.about_title'.tr,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      secim.value = secim.value == 'spam' ? '' : 'spam';
                      if (secim.value == 'spam') {
                        Get.back();
                      }
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'common.spam'.tr,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 25,
                          height: 25,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(50),
                            ),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              decoration: BoxDecoration(
                                color: secim.value == 'spam'
                                    ? Colors.indigo
                                    : Colors.white,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteBottomSheet(BuildContext context) {
    noYesAlert(
      title: 'answer_key.delete_book'.tr,
      message: 'answer_key.delete_book_confirm'.tr,
      cancelText: 'common.cancel'.tr,
      yesText: 'common.delete'.tr,
      onYesPressed: () async {
        try {
          await FirebaseFirestore.instance
              .collection('books')
              .doc(model.docID)
              .delete();
          onUpdate(true);
        } catch (e) {
          log('Kitapcik silme hatasi: $e');
        }
      },
    );
  }
}
