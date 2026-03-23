part of 'social_media_links_controller.dart';

extension SocialMediaControllerActionsPart on SocialMediaController {
  Future<void> pickImage(BuildContext context) async {
    final file = await AppImagePickerService.pickSingleImage(context);
    imageFile.value = file;
  }

  void updateEnableSave() {
    enableSave.value = textController.text.trim().isNotEmpty &&
        urlController.text.trim().isNotEmpty &&
        (selected.value.isNotEmpty || imageFile.value != null);
  }

  void resetFields() {
    selected.value = '';
    textController.clear();
    urlController.clear();
    imageFile.value = null;
  }

  void showAddBottomSheet() {
    Get.bottomSheet(
      AddSocialMediaBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
    ).then((_) {
      unawaited(getData(silent: true, forceRefresh: true));
    });
  }

  Future<void> updateAllSira() async {
    await _linksRepository.reorderLinks(
      currentUid,
      List<SocialMediaModel>.from(list),
    );
  }

  Future<void> updateItemOrder(int oldIndex, int newIndex) async {
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    await _linksRepository.reorderLinks(
      currentUid,
      List<SocialMediaModel>.from(list),
    );
  }

  Future<String> uploadFileImage(File file, String docID) async {
    isUploading.value = true;
    final nsfw = await OptimizedNSFWService.checkImage(file);
    if (nsfw.errorMessage != null) {
      throw Exception('NSFW görsel kontrolü başarısız');
    }
    if (nsfw.isNSFW) {
      throw Exception('Uygunsuz görsel tespit edildi');
    }
    return WebpUploadService.uploadFileAsWebp(
      storage: FirebaseStorage.instance,
      file: file,
      storagePathWithoutExt: 'users/$currentUid/social_links/$docID',
    );
  }

  Future<void> deleteLink(String docId) async {
    await _linksRepository.deleteLink(currentUid, docId);
  }

  Future<void> saveLink(SocialMediaModel model) async {
    await _linksRepository.saveLink(currentUid, model: model);
  }
}
