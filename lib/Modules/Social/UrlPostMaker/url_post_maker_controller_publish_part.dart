part of 'url_post_maker_controller.dart';

extension UrlPostMakerControllerPublishPart on UrlPostMakerController {
  String _resolvePostLocationCity() {
    return CurrentUserService.instance.preferredLocationCity;
  }

  ({
    String nickname,
    String displayName,
    String avatarUrl,
    String rozet,
  }) _resolvePostAuthorSummary() {
    final current = CurrentUserService.instance;
    final nickname = current.nickname.trim();
    final effectiveDisplayName = current.effectiveDisplayName.trim();
    final fullName = current.fullName.trim();
    final displayName = effectiveDisplayName.isNotEmpty
        ? effectiveDisplayName
        : (fullName.isNotEmpty ? fullName : nickname);
    return (
      nickname: nickname,
      displayName: displayName,
      avatarUrl: current.avatarUrl.trim(),
      rozet: current.rozet.trim(),
    );
  }

  Future<void> getReadyVideoPlayer(String url) async {
    final ctrl = HLSVideoAdapter(url: url, autoPlay: false, loop: false);
    ctrl.addListener(() {
      isPlaying.value = ctrl.value.isPlaying;
    });
    videoPlayerController.value = ctrl;
    isPlaying.value = ctrl.value.isPlaying;
  }

  Future<void> setData(
    List<String> imgs,
    String video,
    String thumbnail,
    double aspectRatio, {
    String? originalUserID,
    String? originalPostID,
    bool sharedAsPost = false,
  }) async {
    if (isSharing.value) return;

    isSharing.value = true;
    this.originalUserID = originalUserID;
    this.originalPostID = originalPostID;
    print(
      'UrlPostMakerController setData: originalUserID = $originalUserID, originalPostID = $originalPostID',
    );

    try {
      GlobalLoaderController.ensure().isOn.value = true;
      final uuid = Uuid().v4();
      final currentUserId = CurrentUserService.instance.effectiveUserId;
      final normalizedAR = double.parse(aspectRatio.toStringAsFixed(4));
      final authorSummary = _resolvePostAuthorSummary();
      final imageUrls =
          imgs.map((url) => url.trim()).where((url) => url.isNotEmpty).toList();
      final imgMap = imageUrls
          .map(
            (url) => {
              'url': url,
              'aspectRatio': normalizedAR,
            },
          )
          .toList();

      var finalOriginalUserID = '';
      var finalOriginalPostID = '';

      if (sharedAsPost && originalUserID != null) {
        print(
          'UrlPostMaker: Creating shared post - need to determine original chain',
        );
        finalOriginalUserID = originalUserID;
        finalOriginalPostID = originalPostID ?? '';
      }

      final locationCity = _resolvePostLocationCity();

      await FirebaseFirestore.instance.collection('Posts').doc(uuid).set({
        'arsiv': false,
        if (imageUrls.isEmpty) 'aspectRatio': normalizedAR,
        'debugMode': false,
        'deletedPost': false,
        'deletedPostTime': 0,
        'flood': false,
        'floodCount': 1,
        'gizlendi': false,
        'img': imageUrls,
        'imgMap': imgMap,
        'isAd': false,
        'ad': false,
        'izBirakYayinTarihi': 0,
        'konum': '',
        'locationCity': locationCity,
        'mainFlood': uuid,
        'metin': textEditingController.text,
        'reshareMap': {
          'visibility': 0,
        },
        'scheduledAt': 0,
        'sikayetEdildi': false,
        'stabilized': false,
        'stats': {
          'commentCount': 0,
          'likeCount': 0,
          'reportedCount': 0,
          'retryCount': 0,
          'savedCount': 0,
          'statsCount': 0,
        },
        'tags': [],
        'thumbnail': thumbnail,
        'timeStamp': DateTime.now().millisecondsSinceEpoch,
        'userID': currentUserId,
        'authorNickname': authorSummary.nickname,
        'authorDisplayName': authorSummary.displayName,
        'authorAvatarUrl': authorSummary.avatarUrl,
        'nickname': authorSummary.nickname,
        'fullName': authorSummary.displayName,
        'displayName': authorSummary.displayName,
        'avatarUrl': authorSummary.avatarUrl,
        'rozet': authorSummary.rozet,
        'video': video,
        'hlsStatus': 'none',
        'hlsMasterUrl': '',
        'hlsUpdatedAt': 0,
        'yorum': yorum.value,
        'yorumMap': {
          'visibility': yorum.value ? 0 : 3,
        },
        'originalUserID': finalOriginalUserID,
        'originalPostID': finalOriginalPostID,
        'sharedAsPost': sharedAsPost,
      });
      unawaited(
        TypesensePostService.instance.syncPostById(uuid).catchError((_) {}),
      );
      print(
        'UrlPostMakerController: Post saved with originalUserID: $originalUserID, originalPostID: $originalPostID',
      );

      if (sharedAsPost && finalOriginalUserID.isNotEmpty) {
        try {
          final targetPostID = finalOriginalPostID.isNotEmpty
              ? finalOriginalPostID
              : originalPostID ?? '';

          if (targetPostID.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection('Posts')
                .doc(targetPostID)
                .collection('postSharers')
                .doc(currentUserId)
                .set({
              'userID': currentUserId,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'sharedPostID': uuid,
              'quotedPost': false,
            });
            print(
              'postSharers updated for post: $targetPostID by user: $currentUserId',
            );
          }
        } catch (e) {
          print('Error updating postSharers: $e');
        }
      }

      final newPost = PostsModel(
        arsiv: false,
        aspectRatio: normalizedAR,
        debugMode: false,
        deletedPost: false,
        deletedPostTime: 0,
        docID: uuid,
        editTime: null,
        flood: false,
        floodCount: 1,
        gizlendi: false,
        img: imageUrls,
        isAd: false,
        ad: false,
        izBirakYayinTarihi: 0,
        stats: PostStats(),
        konum: '',
        locationCity: locationCity,
        mainFlood: uuid,
        metin: textEditingController.text,
        paylasGizliligi: 0,
        reshareMap: const {
          'visibility': 0,
        },
        scheduledAt: 0,
        sikayetEdildi: false,
        stabilized: false,
        tags: const [],
        thumbnail: thumbnail,
        timeStamp: DateTime.now().millisecondsSinceEpoch,
        userID: currentUserId,
        authorNickname: authorSummary.nickname,
        authorDisplayName: authorSummary.displayName,
        authorAvatarUrl: authorSummary.avatarUrl,
        rozet: authorSummary.rozet,
        video: video,
        hlsStatus: 'none',
        hlsMasterUrl: '',
        hlsUpdatedAt: 0,
        yorum: yorum.value,
        yorumMap: {
          'visibility': yorum.value ? 0 : 3,
        },
        originalUserID: finalOriginalUserID,
        originalPostID: finalOriginalPostID,
      );

      final agendaController = maybeFindAgendaController();
      if (agendaController != null) {
        agendaController.addUploadedPostsAtTop([newPost]);

        if (agendaController.scrollController.hasClients) {
          agendaController.scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }

      ProfileController.maybeFind()?.getLastPostAndAddToAllPosts();
      GlobalLoaderController.ensure().isOn.value = false;
      isSharing.value = false;
      Get.back();
    } catch (e) {
      GlobalLoaderController.ensure().isOn.value = false;
      isSharing.value = false;
      print('UrlPostMaker setData error: $e');
    }
  }
}
