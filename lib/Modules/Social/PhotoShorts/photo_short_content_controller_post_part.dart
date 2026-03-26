part of 'photo_short_content_controller.dart';

extension PhotoShortContentControllerPostPart on PhotoShortsContentController {
  Future<void> toggleLike() async {
    try {
      await _postRepository.toggleLike(model);
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.like_failed'.tr);
    }
  }

  Future<void> like() => toggleLike();

  Future<void> toggleSave() async {
    try {
      await _postRepository.toggleSave(model);
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.save_failed'.tr);
    }
  }

  Future<void> save() => toggleSave();

  Future<void> toggleReshare() async {
    try {
      final status = await _postRepository.toggleReshare(model);
      if (status) {
        ProfileController.maybeFind()?.getResharesSingle();
      } else {
        ProfileController.maybeFind()?.removeReshare(model.docID);
      }
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.reshare_failed'.tr);
    }
  }

  Future<void> reshare() => toggleReshare();

  Future<void> reportPost() async {
    try {
      final success = await _interactionService.reportPost(model.docID);
      if (success) {
        isReported.value = true;
        AppSnackbar('common.success'.tr, 'post.report_success'.tr);
      }
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.report_failed'.tr);
    }
  }

  Future<void> getGizleArsivSikayetEdildi() async {
    gizlendi.value = model.gizlendi;
    arsiv.value = model.arsiv;
    silindi.value = model.deletedPost;
  }

  Future<void> gizle() async {
    final shortController = ShortController.maybeFind();
    final index = shortController?.shorts.indexOf(model) ?? -1;
    if (index >= 0) shortController!.shorts[index].gizlendi = true;

    final exploreController = ExploreController.maybeFind();
    final index3 = exploreController?.explorePosts.indexOf(model) ?? -1;
    if (index3 >= 0) {
      exploreController!.explorePosts[index3].gizlendi = true;
    }

    final index4 = exploreController?.explorePhotos.indexOf(model) ?? -1;
    if (index4 >= 0) {
      exploreController!.explorePhotos[index4].gizlendi = true;
    }

    final index5 = exploreController?.exploreVideos.indexOf(model) ?? -1;
    if (index5 >= 0) {
      exploreController!.exploreVideos[index5].gizlendi = true;
    }

    final store8 = maybeFindAgendaController();
    final index8 = store8?.agendaList.indexOf(model) ?? -1;
    if (index8 >= 0) store8!.agendaList[index8].gizlendi = true;

    final profile = ProfileController.maybeFind();
    final index9 = profile?.allPosts.indexOf(model) ?? -1;
    if (index9 >= 0) profile!.allPosts[index9].gizlendi = true;

    final index10 = profile?.allPosts.indexOf(model) ?? -1;
    if (index10 >= 0) profile!.allPosts[index10].gizlendi = true;

    gizlendi.value = true;
  }

  Future<void> gizlemeyiGeriAl() async {
    final shortController = ShortController.maybeFind();
    final index = shortController?.shorts.indexOf(model) ?? -1;
    if (index >= 0) shortController!.shorts[index].gizlendi = false;

    final exploreController = ExploreController.maybeFind();

    final index3 = exploreController?.explorePosts.indexOf(model) ?? -1;
    if (index3 >= 0) {
      exploreController!.explorePosts[index3].gizlendi = false;
    }

    final index4 = exploreController?.explorePhotos.indexOf(model) ?? -1;
    if (index4 >= 0) {
      exploreController!.explorePhotos[index4].gizlendi = false;
    }

    final index5 = exploreController?.exploreVideos.indexOf(model) ?? -1;
    if (index5 >= 0) {
      exploreController!.exploreVideos[index5].gizlendi = false;
    }

    final store8 = maybeFindAgendaController();
    final index8 = store8?.agendaList.indexOf(model) ?? -1;
    if (index8 >= 0) store8!.agendaList[index8].gizlendi = false;

    final profile = ProfileController.maybeFind();
    final index9 = profile?.allPosts.indexOf(model) ?? -1;
    if (index9 >= 0) profile!.allPosts[index9].gizlendi = false;

    final index10 = profile?.allPosts.indexOf(model) ?? -1;
    if (index10 >= 0) profile!.allPosts[index10].gizlendi = false;

    gizlendi.value = false;
  }

  Future<void> arsivle() async {
    await _postRepository.setArchived(model, true);

    final shortController = ShortController.maybeFind();
    final index = shortController?.shorts.indexOf(model) ?? -1;
    if (index >= 0) shortController!.shorts[index].arsiv = true;

    final exploreController = ExploreController.maybeFind();
    final index3 = exploreController?.explorePosts.indexOf(model) ?? -1;
    if (index3 >= 0) exploreController!.explorePosts[index3].arsiv = true;

    final index4 = exploreController?.explorePhotos.indexOf(model) ?? -1;
    if (index4 >= 0) exploreController!.explorePhotos[index4].arsiv = true;

    final index5 = exploreController?.exploreVideos.indexOf(model) ?? -1;
    if (index5 >= 0) exploreController!.exploreVideos[index5].arsiv = true;

    final store8 = maybeFindAgendaController();
    final index8 = store8?.agendaList.indexOf(model) ?? -1;
    if (index8 >= 0) store8!.agendaList[index8].arsiv = true;

    final profile = ProfileController.maybeFind();
    final index9 = profile?.allPosts.indexOf(model) ?? -1;
    if (index9 >= 0) profile!.allPosts[index9].arsiv = false;

    final index10 = profile?.allPosts.indexOf(model) ?? -1;
    if (index10 >= 0) profile!.allPosts[index10].arsiv = false;

    arsiv.value = true;
  }

  Future<void> arsivdenCikart() async {
    await _postRepository.setArchived(model, false);

    final shortController = ShortController.maybeFind();
    final index = shortController?.shorts.indexOf(model) ?? -1;
    if (index >= 0) shortController!.shorts[index].arsiv = false;
    final exploreController = ExploreController.maybeFind();

    final index3 = exploreController?.explorePosts.indexOf(model) ?? -1;
    if (index3 >= 0) exploreController!.explorePosts[index3].arsiv = false;

    final index4 = exploreController?.explorePhotos.indexOf(model) ?? -1;
    if (index4 >= 0) exploreController!.explorePhotos[index4].arsiv = false;
    final index5 = exploreController?.exploreVideos.indexOf(model) ?? -1;
    if (index5 >= 0) {
      exploreController!.exploreVideos[index5].arsiv = false;
    }

    final store8 = maybeFindAgendaController();
    final index8 = store8?.agendaList.indexOf(model) ?? -1;
    if (index8 >= 0) store8!.agendaList[index8].arsiv = false;

    final profile = ProfileController.maybeFind();
    final index9 = profile?.allPosts.indexOf(model) ?? -1;
    if (index9 >= 0) profile!.allPosts[index9].arsiv = false;

    final index10 = profile?.allPosts.indexOf(model) ?? -1;
    if (index10 >= 0) profile!.allPosts[index10].arsiv = false;

    arsiv.value = false;
  }

  Future<void> sil() async {
    await PostDeleteService.instance.softDelete(model);
    silindi.value = true;

    Future.delayed(const Duration(milliseconds: 2600), () {
      silindiOpacity.value = 0.0;
    });

    Future.delayed(const Duration(seconds: 3), () {
      final explore = ExploreController.maybeFind();
      if (explore != null) {
        final i1 =
            explore.explorePhotos.indexWhere((e) => e.docID == model.docID);
        if (i1 != -1) {
          explore.explorePhotos.removeAt(i1);
        }
        final i2 =
            explore.explorePosts.indexWhere((e) => e.docID == model.docID);
        if (i2 != -1) {
          explore.explorePosts.removeAt(i2);
        }
        explore.explorePhotos.refresh();
        explore.explorePosts.refresh();
      }

      final agenda = maybeFindAgendaController();
      if (agenda != null) {
        final idx = agenda.agendaList.indexWhere((e) => e.docID == model.docID);
        if (idx != -1) {
          agenda.agendaList.removeAt(idx);
          agenda.agendaList.refresh();
        }
      }
    });
  }

  Future<void> getYenidenPaylasBilgisi() async {
    _postState ??= _postRepository.attachPost(model);
    _syncSharedInteractionState();
  }

  Future<void> sikayetEt() async {
    try {
      final uid = _currentUserId;
      final bool yeniDurum = !model.sikayetEdildi;

      final hideRef = FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("HiddenPosts")
          .doc(model.docID);

      if (yeniDurum) {
        await hideRef.set({
          "timeStamp": DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        await hideRef.delete();
      }

      sikayetEdildi.value = yeniDurum;
      model = model.copyWith(sikayetEdildi: yeniDurum);

      final idx =
          agendaController.agendaList.indexWhere((e) => e.docID == model.docID);
      if (idx != -1) {
        agendaController.agendaList[idx] =
            agendaController.agendaList[idx].copyWith(sikayetEdildi: yeniDurum);
        agendaController.agendaList.refresh();
      }
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.hide_failed'.tr);
    }
  }

  Future<void> sikayetEdilenGonderiGoster() async {
    try {
      final bool yeniDurum = !model.sikayetEdildi;
      sikayetEdildi.value = yeniDurum;
      model = model.copyWith(sikayetEdildi: yeniDurum);

      final idx =
          agendaController.agendaList.indexWhere((e) => e.docID == model.docID);
      if (idx != -1) {
        agendaController.agendaList[idx] =
            agendaController.agendaList[idx].copyWith(sikayetEdildi: yeniDurum);
        agendaController.agendaList.refresh();
      }
    } catch (e) {
      AppSnackbar('common.error'.tr, 'post.hide_failed'.tr);
    }
  }

  Future<void> yenidenPaylasSorusu() async {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                Get.back();
                reShare(model);
              },
              child: Row(
                children: [
                  Image.asset(
                    "assets/icons/reshare.webp",
                    height: 30,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    reSharedUsers.contains(_currentUserId)
                        ? 'post.reshare_undo'.tr
                        : 'post.reshare_action'.tr,
                    style: TextStyle(
                      color: reSharedUsers.contains(_currentUserId)
                          ? Colors.red
                          : Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () {
                Get.back();
              },
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.arrow_turn_up_right,
                    color: Colors.black,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'common.quote'.tr,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black),
                ),
                child: Text(
                  'common.cancel'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: "MontserratBold",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> reShare(PostsModel model) async {
    final uid = _currentUserId;

    if (!reSharedUsers.contains(uid)) {
      final newPostID = const Uuid().v4();
      final newTimestamp = DateTime.now().millisecondsSinceEpoch;

      final originalUserInfo = await ReshareHelper.getDynamicOriginalInfo(
        model.docID,
        model.userID,
        model.originalUserID,
        model.originalPostID,
      );

      final normalizedAR = double.parse(model.aspectRatio.toStringAsFixed(4));
      await FirebaseFirestore.instance.collection("Posts").doc(newPostID).set({
        "arsiv": false,
        "aspectRatio": normalizedAR,
        "debugMode": false,
        "deletedPost": false,
        "deletedPostTime": 0,
        "flood": false,
        "floodCount": 0,
        "gizlendi": false,
        "img": [],
        "isAd": false,
        "ad": false,
        "izBirakYayinTarihi": 0,
        "konum": "",
        "mainFlood": "",
        "metin": "",
        "paylasGizliligi": 0,
        "scheduledAt": 0,
        "sikayetEdildi": false,
        "stabilized": false,
        "stats": {
          "commentCount": 0,
          "likeCount": 0,
          "reportedCount": 0,
          "retryCount": 0,
          "savedCount": 0,
          "statsCount": 0
        },
        "tags": [],
        "thumbnail": "",
        "timeStamp": newTimestamp,
        "userID": uid,
        "video": "",
        "yorum": true,
        "originalUserID": originalUserInfo['userID'],
        "originalPostID": originalUserInfo['originalPostID'],
      });
      unawaited(
        TypesensePostService.instance
            .syncPostById(newPostID)
            .catchError((_) {}),
      );

      try {
        if (CurrentUserService.instance.effectiveUserId.trim() == uid) {
          await CurrentUserService.instance.applyLocalCounterDelta(
            postsDelta: 1,
          );
        }
      } catch (_) {}

      await FirebaseFirestore.instance
          .collection("Posts")
          .doc(model.docID)
          .collection("YenidenPaylas")
          .doc(uid)
          .set({
        "timeStamp": newTimestamp,
        "yeniPostID": newPostID,
      });

      reSharedUsers.add(_currentUserId);

      try {
        ProfileController.maybeFind()?.getLastPostAndAddToAllPosts();
      } catch (_) {}
    } else {
      final yeniPostID =
          await _postRepository.fetchLegacyResharedPostId(model.docID, uid);

      if (yeniPostID != null && yeniPostID.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection("Posts")
            .doc(yeniPostID)
            .delete();
        await FirebaseFirestore.instance
            .collection("Posts")
            .doc(model.docID)
            .collection("YenidenPaylas")
            .doc(uid)
            .delete();
        reSharedUsers.remove(_currentUserId);

        agendaController.agendaList
            .removeWhere((item) => item.docID == yeniPostID);
        agendaController.agendaList.refresh();
      }
    }

    fetchUserData(model.userID);
    getReSharedUsers(model.docID);
    getSeens();
    getUnlikes();
  }

  Future<void> getLikes() async {
    final uid = _currentUserId;
    if (uid.isEmpty) {
      likes.clear();
      return;
    }
    _postState ??= _postRepository.attachPost(model);
    likes.value =
        (_postState?.liked.value ?? false) ? <String>[uid] : <String>[];
  }

  Future<void> getUnlikes() async {
    unLikes.value = await _postRepository.fetchDislikeUserIds(model.docID);
  }

  Future<void> getSeens() async {
    seens.clear();
  }

  Future<void> saveSeeing() async {
    try {
      final uid = _currentUserId;
      await _postRepository.ensureViewerSeen(model.docID, uid);
    } catch (_) {}
  }
}
