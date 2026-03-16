part of 'profile_view.dart';

extension _ProfileViewHeaderPart on _ProfileViewState {
  Widget header() {
    return Obx(() {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          controller.pausetheall.value = true;
                          Get.to(() => AboutProfile(
                              userID: FirebaseAuth
                                  .instance.currentUser!.uid))?.then((_) {
                            controller.pausetheall.value = true;
                          });
                        },
                        child: Text(
                          _myIosSafeNickname,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontFamily: AppFontFamilies.mbold,
                          ),
                        ),
                      ),
                      if (_myIosSafeNickname.trim().isNotEmpty) ...[
                        RozetContent(
                          size: 15,
                          userID: _myUserId,
                          leftSpacing: 6,
                          rozetValue: _myRozet,
                        ),
                      ],
                    ],
                  ),
                ),
                AppHeaderActionButton(
                  onTap: () {
                    controller.pausetheall.value = true;
                    Get.to(() => MyQRCode())?.then((_) {
                      controller.pausetheall.value = false;
                    });
                  },
                  child: Icon(
                    CupertinoIcons.qrcode,
                    color: AppColors.textBlack,
                    size: AppIconSurface.kIconSize,
                  ),
                ),
                AppIconSurface.kGap.pw,
                AppHeaderActionButton(
                  onTap: () {
                    controller.pausetheall.value = true;
                    Get.to(() => ChatListing())?.then((_) {
                      controller.pausetheall.value = false;
                    });
                  },
                  child: Icon(
                    CupertinoIcons.mail,
                    color: AppColors.textBlack,
                    size: AppIconSurface.kIconSize,
                  ),
                ),
                AppIconSurface.kGap.pw,
                AppHeaderActionButton(
                  onTap: () {
                    controller.pausetheall.value = true;
                    Get.to(() => SettingsView())?.then((_) {
                      controller.pausetheall.value = false;
                      _refreshUserState();
                    });
                  },
                  child: Icon(
                    CupertinoIcons.gear,
                    color: AppColors.textBlack,
                    size: AppIconSurface.kIconSize,
                  ),
                ),
              ],
            ),
          ),
          imageAndFollowButtons(),
          12.ph,
          textInfoBody(),
          _buildLinksAndHighlightsRow(),
          Padding(padding: const EdgeInsets.only(top: 0), child: counters()),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: postButtons(context),
          ),
          Divider(
            height: 0,
            color: Colors.grey.withAlpha(50),
          ),
          4.ph,
        ],
      );
    });
  }

  Widget imageAndFollowButtons() {
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
                    onTap: () {
                      final myUserID = FirebaseAuth.instance.currentUser!.uid;

                      if (_hasMyStories) {
                        try {
                          final myStoryUser = storyOwnerUsers.firstWhereOrNull(
                              (u) =>
                                  u.userID == myUserID && u.stories.isNotEmpty);

                          if (myStoryUser != null &&
                              myStoryUser.stories.isNotEmpty) {
                            Get.to(() => StoryViewer(
                                  startedUser: myStoryUser,
                                  storyOwnerUsers: [myStoryUser],
                                ));
                          } else {
                            controller.pausetheall.value = true;
                            Get.to(() => StoryMaker())?.then((_) {
                              controller.pausetheall.value = false;
                              _refreshUserState();
                            });
                          }
                        } catch (_) {
                          controller.pausetheall.value = true;
                          Get.to(() => StoryMaker())?.then((_) {
                            controller.pausetheall.value = false;
                            _refreshUserState();
                          });
                        }
                      } else {
                        controller.pausetheall.value = true;
                        Get.to(() => StoryMaker())?.then((_) {
                          controller.pausetheall.value = false;
                          _refreshUserState();
                        });
                      }
                    },
                    onLongPress: () {
                      controller.showPfImage.value = true;
                    },
                    child: _buildProfileImageWithBorder(),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        controller.pausetheall.value = true;
                        Get.to(() => StoryMaker())?.then((_) {
                          controller.pausetheall.value = false;
                          _refreshUserState();
                        });
                      },
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
                        onTap: () {
                          controller.pausetheall.value = true;
                          Get.to(() => EditProfile())?.then((_) {
                            controller.pausetheall.value = false;
                            _refreshUserState();
                          });
                        },
                        child: Container(
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Düzenle",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                        ),
                      ),
                    ),
                    12.pw,
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          controller.pausetheall.value = true;
                          Get.to(() => MyStatisticView())?.then((_) {
                            controller.pausetheall.value = false;
                          });
                        },
                        child: Container(
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "İstatistikler",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontFamily: "MontserratBold",
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
      ],
    );
  }

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
                    controller.pausetheall.value = true;
                    Get.to(() => BecomeVerifiedAccount())?.then((_) {
                      controller.pausetheall.value = false;
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
                      const Text(
                        "Onaylı Hesap Ol",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      )
                    ],
                  ),
                )
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
                controller.pausetheall.value = true;
                Get.to(() => BiographyMaker())?.then((_) {
                  controller.pausetheall.value = false;
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

  Widget counters() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              controller.postSelection.value = 0;
            },
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      NumberFormatter.format(_myTotalPosts),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    const Text(
                      "Gönderi",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              controller.pausetheall.value = true;
              Get.to(() => FollowingFollowers(
                  selection: 0,
                  userId: FirebaseAuth.instance.currentUser!.uid))?.then((_) {
                controller.pausetheall.value = false;
              });
            },
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      NumberFormatter.format(controller.followerCount.value),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    const Text(
                      "Takipci",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              controller.pausetheall.value = true;
              Get.to(() => FollowingFollowers(
                  selection: 1,
                  userId: FirebaseAuth.instance.currentUser!.uid))?.then((_) {
                controller.pausetheall.value = false;
              });
            },
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      NumberFormatter.format(controller.followingCount.value),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    const Text(
                      "Takip",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Colors.white),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    NumberFormatter.format(_myTotalLikes),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                  const Text(
                    "Beğeni",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              controller.postSelection.value = 4;
            },
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      NumberFormatter.format(_myTotalMarket),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    const Text(
                      "İlan",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget postButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  controller.setPostSelection(0);
                },
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Icon(
                        Icons.tag,
                        color: controller.postSelection.value == 0
                            ? Colors.pink
                            : Colors.black,
                        size: controller.postSelection.value == 0 ? 30 : 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  controller.setPostSelection(3);
                },
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Icon(
                        Icons.repeat,
                        color: controller.postSelection.value == 3
                            ? Colors.pink
                            : Colors.black,
                        size: controller.postSelection.value == 3 ? 30 : 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  controller.setPostSelection(1);
                },
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: controller.postSelection.value == 1
                            ? Colors.pink
                            : Colors.black,
                        size: controller.postSelection.value == 1 ? 30 : 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  controller.setPostSelection(2);
                },
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Icon(
                        Icons.photo_outlined,
                        color: controller.postSelection.value == 2
                            ? Colors.pink
                            : Colors.black,
                        size: controller.postSelection.value == 2 ? 30 : 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  controller.setPostSelection(5);
                },
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        color: controller.postSelection.value == 5
                            ? Colors.pink
                            : Colors.black,
                        size: controller.postSelection.value == 5 ? 30 : 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  controller.setPostSelection(4);
                },
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: controller.postSelection.value == 4
                            ? Colors.pink
                            : Colors.black,
                        size: controller.postSelection.value == 4 ? 30 : 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
