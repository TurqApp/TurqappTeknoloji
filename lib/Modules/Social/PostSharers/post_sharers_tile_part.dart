part of 'post_sharers.dart';

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

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  @override
  void initState() {
    super.initState();
    _followTag =
        'post_sharer_follow_${widget.sharer.userID}_${DateTime.now().microsecondsSinceEpoch}';
    if (widget.sharer.userID != _currentUid) {
      _ownsFollowController =
          maybeFindFollowerController(tag: _followTag) == null;
      _followController = ensureFollowerController(tag: _followTag);
      _refreshFollowState();
    }
  }

  @override
  void dispose() {
    if (_ownsFollowController &&
        identical(
          maybeFindFollowerController(tag: _followTag),
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
    await const ProfileNavigationService().openSocialProfile(
      widget.sharer.userID,
    );
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
          child: CachedUserAvatar(
            imageUrl: avatarUrl,
            radius: 24,
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
