part of 'scholarships_view.dart';

extension ScholarshipsViewUserPart on _ScholarshipsViewState {
  Widget _buildUserHeader(
    String type,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? firmaData,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _buildUserInfo(type, userData, firmaData)),
          if (_shouldShowFollowButton(userData)) ...[
            8.pw,
            _buildFollowButton(userData),
          ],
        ],
      ),
    );
  }

  Widget _buildUserInfo(
    String type,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? firmaData,
  ) {
    final userId = userData?['userID']?.toString() ?? '';
    return GestureDetector(
      onTap: _getUserTapHandler(type, userData),
      child: Row(
        children: [
          _buildUserAvatar(type, userData, firmaData),
          6.pw,
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _truncateLabel(
                      _getUserDisplayName(type, userData, firmaData),
                      maxChars: 30,
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: "MontserratBold",
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
                if (isIndividualScholarshipType(type) && userId.isNotEmpty) ...[
                  4.pw,
                  RozetContent(
                    size: 13,
                    userID: userId,
                    leftSpacing: 0,
                    rozetValue: userData?['rozet']?.toString(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(
    String type,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? firmaData,
  ) {
    final imageUrl = (userData?['avatarUrl'] ?? '').toString();
    return CircleAvatar(
      radius: 15,
      child: imageUrl.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => CupertinoActivityIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            )
          : Icon(Icons.person, size: 20),
    );
  }

  VoidCallback? _getUserTapHandler(
    String type,
    Map<String, dynamic>? userData,
  ) {
    final uid = userData?['userID']?.toString() ?? '';
    if (uid != CurrentUserService.instance.effectiveUserId) {
      return () {
        Get.to(() => SocialProfile(userID: uid));
      };
    }
    return null;
  }

  String _getUserDisplayName(
    String type,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? firmaData,
  ) {
    final nick = (userData?['displayName'] ??
            userData?['username'] ??
            userData?['nickname'])
        ?.toString();
    if (nick != null && nick.isNotEmpty) return nick;
    final first = userData?['firstName']?.toString() ?? '';
    final last = userData?['lastName']?.toString() ?? '';
    final full = ('$first $last').trim();
    return full.isNotEmpty ? full : 'common.user'.tr;
  }

  String _truncateLabel(String value, {required int maxChars}) {
    final trimmed = value.trim();
    if (trimmed.length <= maxChars) {
      return trimmed;
    }
    final cutIndex = trimmed.lastIndexOf(' ', maxChars);
    final safeIndex = cutIndex > 0 ? cutIndex : maxChars;
    return '${trimmed.substring(0, safeIndex).trimRight()}...';
  }

  bool _shouldShowFollowButton(Map<String, dynamic>? userData) {
    final currentUid = CurrentUserService.instance.effectiveUserId;
    return userData?['userID']?.toString() != currentUid;
  }

  Widget _buildFollowButton(Map<String, dynamic>? userData) {
    final userId = userData?['userID']?.toString() ?? '';
    return Obx(() {
      final isLoading = controller.followLoading[userId] ?? false;
      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 86),
        child: ScaleTap(
          enabled: !isLoading,
          onPressed: isLoading ? null : () => _handleFollowTap(userData),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _getFollowButtonColor(userData),
              border: Border.all(width: 1, color: Colors.black),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLoading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getFollowButtonTextColor(userData),
                      ),
                    ),
                  )
                : Text(
                    _getFollowButtonText(userData),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      color: _getFollowButtonTextColor(userData),
                      fontSize: 12,
                      fontFamily: "MontserratBold",
                    ),
                  ),
          ),
        ),
      );
    });
  }

  Color _getFollowButtonColor(Map<String, dynamic>? userData) {
    final isFollowing =
        controller.followedUsers[userData?['userID']?.toString() ?? ''] ??
            false;
    return isFollowing ? Colors.white : Colors.black;
  }

  String _getFollowButtonText(Map<String, dynamic>? userData) {
    final isFollowing =
        controller.followedUsers[userData?['userID']?.toString() ?? ''] ??
            false;
    return isFollowing ? 'following.following'.tr : 'following.follow'.tr;
  }

  Color _getFollowButtonTextColor(Map<String, dynamic>? userData) {
    final isFollowing =
        controller.followedUsers[userData?['userID']?.toString() ?? ''] ??
            false;
    return isFollowing ? Colors.black : Colors.white;
  }

  Future<void> _handleFollowTap(Map<String, dynamic>? userData) async {
    final followedId = userData?['userID']?.toString() ?? '';
    if (followedId.isEmpty) return;
    await controller.toggleFollow(followedId);
    controller.allScholarships.refresh();
    controller.visibleScholarships.refresh();
  }
}
