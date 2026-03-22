part of 'profile_view.dart';

extension _ProfileViewHeaderPart on _ProfileViewState {
  Widget header() {
    return Obx(() {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: GestureDetector(
                          onTap: () {
                            _suspendProfileFeedForRoute();
                            Get.to(() => AboutProfile(
                                userID: _myUserId))?.then((_) {
                              _resumeProfileFeedAfterRoute();
                            });
                          },
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
                          rozetValue:
                              normalizeRozetValue(controller.headerRozet.value)
                                  .isNotEmpty
                              ? normalizeRozetValue(
                                  controller.headerRozet.value,
                                )
                              : normalizeRozetValue(
                                  userService.rozet,
                                ),
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
                      key: const ValueKey(
                        IntegrationTestKeys.actionProfileOpenQr,
                      ),
                      size: 36,
                      onTap: () {
                        _suspendProfileFeedForRoute();
                        Get.to(() => MyQRCode())?.then((_) {
                          _resumeProfileFeedAfterRoute();
                        });
                      },
                      child: Icon(
                        CupertinoIcons.qrcode,
                        color: AppColors.textBlack,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AppHeaderActionButton(
                      key: const ValueKey(
                        IntegrationTestKeys.actionProfileOpenChat,
                      ),
                      size: 36,
                      onTap: () {
                        _suspendProfileFeedForRoute();
                        Get.to(() => ChatListing())?.then((_) {
                          _resumeProfileFeedAfterRoute();
                        });
                      },
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
                      onTap: () {
                        _suspendProfileFeedForRoute();
                        Get.to(() => SettingsView())?.then((_) {
                          _resumeProfileFeedAfterRoute();
                          _refreshUserState();
                        });
                      },
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
                      final myUserID = _myUserId;

                      if (_hasMyStories) {
                        try {
                          final myStoryUser = storyOwnerUsers.firstWhereOrNull(
                              (u) =>
                                  u.userID == myUserID && u.stories.isNotEmpty);

                          if (myStoryUser != null &&
                              myStoryUser.stories.isNotEmpty) {
                            _suspendProfileFeedForRoute();
                            Get.to(() => StoryViewer(
                                  startedUser: myStoryUser,
                                  storyOwnerUsers: [myStoryUser],
                                ))?.then((_) {
                              _resumeProfileFeedAfterRoute();
                            });
                          } else {
                            _suspendProfileFeedForRoute();
                            Get.to(() => StoryMaker())?.then((_) {
                              _resumeProfileFeedAfterRoute();
                              _refreshUserState();
                            });
                          }
                        } catch (_) {
                          _suspendProfileFeedForRoute();
                          Get.to(() => StoryMaker())?.then((_) {
                            _resumeProfileFeedAfterRoute();
                            _refreshUserState();
                          });
                        }
                      } else {
                        _suspendProfileFeedForRoute();
                        Get.to(() => StoryMaker())?.then((_) {
                          _resumeProfileFeedAfterRoute();
                          _refreshUserState();
                        });
                      }
                    },
                    onLongPress: () {
                      _showProfileImagePreview();
                    },
                    child: _buildProfileImageWithBorder(),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        _suspendProfileFeedForRoute();
                        Get.to(() => StoryMaker())?.then((_) {
                          _resumeProfileFeedAfterRoute();
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
                        key: const ValueKey(
                          IntegrationTestKeys.actionProfileEdit,
                        ),
                        onTap: () {
                          _suspendProfileFeedForRoute();
                          Get.to(() => EditProfile())?.then((_) {
                            _resumeProfileFeedAfterRoute();
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
                            "profile.edit".tr,
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
                          _suspendProfileFeedForRoute();
                          Get.to(() => MyStatisticView())?.then((_) {
                            _resumeProfileFeedAfterRoute();
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
                            "profile.statistics".tr,
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

  Widget counters() {
    final items = <Widget>[
      _buildCounterTile(
        value: NumberFormatter.format(_myTotalPosts),
        label: "profile.posts".tr,
        onTap: () => controller.setPostSelection(0),
      ),
      _buildCounterTile(
        value: NumberFormatter.format(controller.followerCount.value),
        label: "profile.followers".tr,
        onTap: () {
          _suspendProfileFeedForRoute();
          Get.to(() => FollowingFollowers(selection: 0, userId: _myUserId))
              ?.then((_) {
            _resumeProfileFeedAfterRoute();
          });
        },
        semanticsLabel: IntegrationTestKeys.profileFollowersCounter,
        valueKey: const ValueKey(IntegrationTestKeys.profileFollowersCounter),
      ),
      _buildCounterTile(
        value: NumberFormatter.format(controller.followingCount.value),
        label: "profile.following".tr,
        onTap: () {
          _suspendProfileFeedForRoute();
          Get.to(() => FollowingFollowers(selection: 1, userId: _myUserId))
              ?.then((_) {
            _resumeProfileFeedAfterRoute();
          });
        },
        semanticsLabel: IntegrationTestKeys.profileFollowingCounter,
        valueKey: const ValueKey(IntegrationTestKeys.profileFollowingCounter),
      ),
      _buildCounterTile(
        value: NumberFormatter.format(_myTotalLikes),
        label: "profile.likes".tr,
      ),
      _buildCounterTile(
        value: NumberFormatter.format(_myTotalMarket),
        label: "profile.listings".tr,
        onTap: () => controller.setPostSelection(4),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: items
            .map((item) => Expanded(child: item))
            .toList(growable: false),
      ),
    );
  }

  Widget _buildCounterTile({
    required String value,
    required String label,
    VoidCallback? onTap,
    String? semanticsLabel,
    Key? valueKey,
  }) {
    Widget tile = Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontFamily: "MontserratBold",
            ),
          ),
          Text(
            label,
            key: valueKey,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontFamily: "MontserratMedium",
              height: 1.0,
            ),
          ),
        ],
      ),
    );

    if (semanticsLabel != null) {
      tile = Semantics(
        label: semanticsLabel,
        button: onTap != null,
        child: tile,
      );
    }

    if (onTap == null) return tile;

    return GestureDetector(
      onTap: onTap,
      child: tile,
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
                  unawaited(_loadMarketItems(force: true));
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
