part of 'profile_view.dart';

extension _ProfileViewActionsPart on _ProfileViewState {
  Widget textInfoBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$_myDisplayFirstName $_myDisplayLastName'.trim(),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratBold",
                ),
              ),
              4.pw,
              if (!_hasVerifiedRozet)
                GestureDetector(
                  onTap: () {
                    _suspendProfileFeedForRoute();
                    Get.to(() => BecomeVerifiedAccount())?.then((_) {
                      _resumeProfileFeedAfterRoute();
                    });
                  },
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        color: Colors.blueAccent,
                        size: 15,
                      ),
                      4.pw,
                      Text(
                        "settings.become_verified".tr,
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_myDisplayMeslek.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                _myDisplayMeslek,
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          if (_myDisplayBio.isNotEmpty)
            GestureDetector(
              onTap: () {
                _suspendProfileFeedForRoute();
                Get.to(() => BiographyMaker())?.then((_) {
                  _resumeProfileFeedAfterRoute();
                  _refreshUserState();
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  _myDisplayBio,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "Montserrat",
                  ),
                ),
              ),
            ),
          if (_myDisplayAdres.isNotEmpty)
            GestureDetector(
              onTap: () {
                showMapsSheetWithAdres(_myDisplayAdres);
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  _myDisplayAdres,
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontSize: 12,
                    fontFamily: "Montserrat",
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopHeaderRow() {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: GestureDetector(
                    onTap: _openAboutProfile,
                    child: Text(
                      _myIosSafeNickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: AppFontFamilies.mbold,
                      ),
                    ),
                  ),
                ),
                if (_myIosSafeNickname.trim().isNotEmpty) ...[
                  RozetContent(
                    size: 15,
                    userID: _myUserId,
                    leftSpacing: 6,
                    rozetValue: normalizeRozetValue(
                      controller.headerRozet.value,
                    ).isNotEmpty
                        ? normalizeRozetValue(controller.headerRozet.value)
                        : normalizeRozetValue(userService.rozet),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppHeaderActionButton(
                key: const ValueKey(IntegrationTestKeys.actionProfileOpenQr),
                size: 36,
                onTap: _openQrCode,
                child: Icon(
                  CupertinoIcons.qrcode,
                  color: AppColors.textBlack,
                  size: 18,
                ),
              ),
              const SizedBox(width: 6),
              AppHeaderActionButton(
                key: const ValueKey(IntegrationTestKeys.actionProfileOpenChat),
                size: 36,
                onTap: _openChatListing,
                child: Icon(
                  CupertinoIcons.mail,
                  color: AppColors.textBlack,
                  size: 18,
                ),
              ),
              const SizedBox(width: 6),
              AppHeaderActionButton(
                key: const ValueKey(
                  IntegrationTestKeys.actionProfileOpenSettings,
                ),
                size: 36,
                onTap: _openSettings,
                child: Icon(
                  CupertinoIcons.gear,
                  color: AppColors.textBlack,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageAndButtonsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: _handleProfileImageTap,
                    onLongPress: _showProfileImagePreview,
                    child: _buildProfileImageWithBorder(),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _openStoryMakerAndRefresh,
                      child: Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                        child: const Icon(
                          CupertinoIcons.add,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              12.pw,
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        key: const ValueKey(
                          IntegrationTestKeys.actionProfileEdit,
                        ),
                        onTap: _openEditProfile,
                        child: _buildHeaderButton("profile.edit".tr),
                      ),
                    ),
                    12.pw,
                    Expanded(
                      child: GestureDetector(
                        onTap: _openMyStatistics,
                        child: _buildHeaderButton("profile.statistics".tr),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderButton(String text) {
    return Container(
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(50),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontFamily: "MontserratBold",
        ),
      ),
    );
  }

  Future<void> arsivle(PostsModel model) async {
    await FirebaseFirestore.instance
        .collection("Posts")
        .doc(model.docID)
        .update(
      {
        "arsiv": true,
      },
    );

    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final isVisible = (model.timeStamp <= nowMs) && !model.flood;
      if (isVisible) {
        final me = _myUserId;
        if (me.isNotEmpty) {
          await UserRepository.ensure().updateUserFields(
            me,
            {'counterOfPosts': FieldValue.increment(-1)},
            mergeIntoCache: false,
          );
          await CurrentUserService.instance.applyLocalCounterDelta(
            postsDelta: -1,
          );
        }
      }
    } catch (_) {}

    final shortController = ShortController.maybeFind();
    final index = shortController?.shorts.indexOf(model) ?? -1;
    if (index >= 0) shortController!.shorts[index].arsiv = true;
    final exploreController = ExploreController.maybeFind();

    final index3 = exploreController?.explorePosts.indexOf(model) ?? -1;
    if (index3 >= 0) {
      exploreController!.explorePosts[index3].arsiv = true;
    }

    final index4 = exploreController?.explorePhotos.indexOf(model) ?? -1;
    if (index4 >= 0) {
      exploreController!.explorePhotos[index4].arsiv = true;
    }

    final index5 = exploreController?.exploreVideos.indexOf(model) ?? -1;
    if (index5 >= 0) {
      exploreController!.exploreVideos[index5].arsiv = true;
    }

    final store8 = AgendaController.maybeFind();
    if (store8 != null) {
      final index8 = store8.agendaList.indexOf(model);
      if (index8 >= 0) store8.agendaList[index8].arsiv = true;
    }

    final store9 = ProfileController.ensure();
    final index9 = store9.allPosts.indexOf(model);
    if (index9 >= 0) store9.allPosts[index9].arsiv = true;

    final store10 = ProfileController.ensure();
    final index10 = store10.videos.indexOf(model);
    if (index10 >= 0) store10.videos[index10].arsiv = true;

    final store11 = ProfileController.ensure();
    final index11 = store11.photos.indexOf(model);
    if (index11 >= 0) store11.photos[index11].arsiv = true;

    controller.photos.refresh();
    controller.videos.refresh();
    controller.allPosts.refresh();
  }
}
