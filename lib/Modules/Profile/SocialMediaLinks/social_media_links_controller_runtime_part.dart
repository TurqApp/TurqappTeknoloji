part of 'social_media_links_controller_library.dart';

class SocialMediaController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _SocialMediaControllerState();

  @override
  void onInit() {
    super.onInit();
    _SocialMediaControllerRuntimeX(this).handleOnInit();
  }
}

extension _SocialMediaControllerRuntimeX on SocialMediaController {
  void handleOnInit() {
    _bindFormListeners();
    unawaited(_bootstrapDataImpl());
  }

  void _bindFormListeners() {
    selected.listen((_) => updateEnableSave());
    textController.addListener(updateEnableSave);
    urlController.addListener(updateEnableSave);
  }

  Future<void> _bootstrapDataImpl() async {
    if (currentUid.isEmpty) {
      isLoading.value = false;
      list.value = <SocialMediaModel>[];
      return;
    }
    final cached = await _linksRepository.getLinks(
      currentUid,
      preferCache: true,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      list.value = List<SocialMediaModel>.from(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'profile:social_media:$currentUid',
        minInterval: SocialMediaController._silentRefreshInterval,
      )) {
        unawaited(getData(silent: true, forceRefresh: true));
      }
      return;
    }
    await getData();
  }

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final uid = currentUid;
    if (uid.isEmpty) {
      list.value = <SocialMediaModel>[];
      isLoading.value = false;
      return;
    }
    if (!silent) {
      isLoading.value = true;
    }
    try {
      final hadFreshCache =
          !forceRefresh && await _linksRepository.hasFreshCacheEntry(uid);
      var items = await _linksRepository.getLinks(
        uid,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      if (hadFreshCache && items.isEmpty) {
        items = await _linksRepository.getLinks(
          uid,
          preferCache: false,
          forceRefresh: true,
        );
      }
      list.value = List<SocialMediaModel>.from(items);
      SilentRefreshGate.markRefreshed('profile:social_media:$uid');
    } finally {
      isLoading.value = false;
    }
  }

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
