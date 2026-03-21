import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Services/reshare_helper.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/follower_controller.dart';
import 'package:turqappv2/Modules/Social/PostSharers/post_sharers_controller.dart';
import 'package:turqappv2/Models/post_sharers_model.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';

class PostSharers extends StatefulWidget {
  final String postID;

  const PostSharers({super.key, required this.postID});

  @override
  State<PostSharers> createState() => _PostSharersState();
}

class _PostSharersState extends State<PostSharers> {
  late final String _controllerTag;
  late final PostSharersController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'post_sharers_${widget.postID}_${DateTime.now().microsecondsSinceEpoch}';
    _ownsController =
        PostSharersController.maybeFind(tag: _controllerTag) == null;
    controller = PostSharersController.ensure(
      postID: widget.postID,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          PostSharersController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<PostSharersController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                BackButtons(text: 'short.shared_as_post_by'.tr),
              ],
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CupertinoActivityIndicator(),
                  );
                }

                if (controller.postSharers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.share_up,
                          size: 64,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'post_sharers.empty'.tr,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  controller: controller.scrollController,
                  itemCount: controller.postSharers.length +
                      (controller.isLoadingMore.value ? 1 : 0),
                  separatorBuilder: (context, index) => Divider(
                    indent: 10,
                    endIndent: 10,
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    if (index >= controller.postSharers.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CupertinoActivityIndicator(),
                        ),
                      );
                    }

                    final sharer = controller.postSharers[index];
                    final userData = controller.usersData[sharer.userID];

                    return _PostSharerTile(
                      sharer: sharer,
                      userData: userData,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostSharerTile extends StatefulWidget {
  const _PostSharerTile({
    required this.sharer,
    required this.userData,
  });

  final PostSharersModel sharer;
  final Map<String, dynamic>? userData;

  @override
  State<_PostSharerTile> createState() => _PostSharerTileState();
}

class _PostSharerTileState extends State<_PostSharerTile> {
  late final String _followTag;
  FollowerController? _followController;
  bool _followStateReady = false;
  bool _ownsFollowController = false;

  String get _currentUid => CurrentUserService.instance.userId;

  @override
  void initState() {
    super.initState();
    _followTag =
        'post_sharer_follow_${widget.sharer.userID}_${DateTime.now().microsecondsSinceEpoch}';
    if (widget.sharer.userID != _currentUid) {
      _ownsFollowController =
          FollowerController.maybeFind(tag: _followTag) == null;
      _followController = FollowerController.ensure(tag: _followTag);
      _refreshFollowState();
    }
  }

  @override
  void dispose() {
    if (_ownsFollowController &&
        identical(
          FollowerController.maybeFind(tag: _followTag),
          _followController,
        )) {
      Get.delete<FollowerController>(tag: _followTag, force: true);
    }
    super.dispose();
  }

  Future<void> _refreshFollowState() async {
    if (_followController == null) return;
    await _followController!.followControl(widget.sharer.userID);
    if (!mounted) return;
    setState(() {
      _followStateReady = true;
    });
  }

  Future<void> _openProfile() async {
    await Get.to(() => SocialProfile(userID: widget.sharer.userID));
    await _refreshFollowState();
  }

  @override
  Widget build(BuildContext context) {
    final nickname = (widget.userData?['nickname'] ?? '').toString().trim();
    final fullName = (widget.userData?['fullName'] ?? '').toString().trim();
    final displayName =
        fullName.isNotEmpty && !ReshareHelper.isUnknownUserLabel(fullName)
            ? fullName
            : (nickname.isNotEmpty ? nickname : 'common.unknown_user'.tr);
    final subtitle =
        nickname.isNotEmpty ? '@$nickname' : '@${'common.unknown_user'.tr}';
    final avatarUrl = (widget.userData?['avatarUrl'] ?? '').toString().trim();

    return ListTile(
      onTap: _openProfile,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: ClipOval(
        child: SizedBox(
          width: 48,
          height: 48,
          child: avatarUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: avatarUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      CupertinoIcons.person_fill,
                      color: Colors.grey,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      CupertinoIcons.person_fill,
                      color: Colors.grey,
                    ),
                  ),
                )
              : Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    CupertinoIcons.person_fill,
                    color: Colors.grey,
                  ),
                ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratBold",
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeAgoMetin(widget.sharer.timestamp),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontFamily: "MontserratMedium",
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.blueAccent,
            fontSize: 15,
            fontFamily: "MontserratBold",
          ),
        ),
      ),
      trailing:
          widget.sharer.userID == _currentUid ? null : _buildFollowButton(),
    );
  }

  Widget _buildFollowButton() {
    if (_followController == null || !_followStateReady) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      if (_followController!.isFollowed.value) {
        return const SizedBox.shrink();
      }

      return GestureDetector(
        onTap: _followController!.followLoading.value
            ? null
            : () {
                _followController!.follow(widget.sharer.userID);
              },
        child: Container(
          height: 30,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: _followController!.followLoading.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'following.follow'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: "MontserratBold",
                  ),
                ),
        ),
      );
    });
  }
}
