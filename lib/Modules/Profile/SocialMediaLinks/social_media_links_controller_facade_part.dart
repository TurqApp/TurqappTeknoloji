part of 'social_media_links_controller.dart';

SocialMediaController ensureSocialMediaController({bool permanent = false}) {
  final existing = maybeFindSocialMediaController();
  if (existing != null) return existing;
  return Get.put(SocialMediaController(), permanent: permanent);
}

SocialMediaController? maybeFindSocialMediaController() {
  final isRegistered = Get.isRegistered<SocialMediaController>();
  if (!isRegistered) return null;
  return Get.find<SocialMediaController>();
}

extension SocialMediaControllerFacadePart on SocialMediaController {
  String get currentUid => CurrentUserService.instance.effectiveUserId;

  bool isKnownEmbeddedKey(String key) => sosyal.contains(key);

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _SocialMediaControllerRuntimeX(this).getData(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<void> pickImage(BuildContext context) =>
      _SocialMediaControllerRuntimeX(this).pickImage(context);

  void updateEnableSave() =>
      _SocialMediaControllerRuntimeX(this).updateEnableSave();

  void resetFields() => _SocialMediaControllerRuntimeX(this).resetFields();

  void showAddBottomSheet() =>
      _SocialMediaControllerRuntimeX(this).showAddBottomSheet();

  Future<void> updateAllSira() =>
      _SocialMediaControllerRuntimeX(this).updateAllSira();

  Future<void> updateItemOrder(int oldIndex, int newIndex) =>
      _SocialMediaControllerRuntimeX(this).updateItemOrder(oldIndex, newIndex);

  Future<String> uploadFileImage(File file, String docID) =>
      _SocialMediaControllerRuntimeX(this).uploadFileImage(file, docID);

  Future<void> deleteLink(String docId) =>
      _SocialMediaControllerRuntimeX(this).deleteLink(docId);

  Future<void> saveLink(SocialMediaModel model) =>
      _SocialMediaControllerRuntimeX(this).saveLink(model);
}
