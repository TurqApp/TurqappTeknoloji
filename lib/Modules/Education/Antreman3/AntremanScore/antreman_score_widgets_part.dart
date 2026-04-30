part of 'antreman_score.dart';

extension AntremanScoreWidgetsPart on _AntremanScoreState {
  Widget _buildPodiumItem(
    BuildContext context,
    Map<String, dynamic> user,
    String frameAsset,
    double frameWidth,
    double imageSize,
    double textSize,
  ) {
    final String podiumUserID = user['userID'] ?? '';
    final bool isCurrentUser = podiumUserID == currentUserID;

    return GestureDetector(
      onTap: isCurrentUser
          ? null
          : () {
              const ProfileNavigationService().openSocialProfile(podiumUserID);
            },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                frameAsset,
                width: frameWidth,
                height: frameWidth,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: frameWidth,
                    height: frameWidth,
                    color: Colors.grey,
                    child: Icon(Icons.error),
                  );
                },
              ),
              ClipOval(
                child: SizedBox(
                  width: imageSize,
                  height: imageSize,
                  child: CachedUserAvatar(
                    imageUrl: (user['avatarUrl'] ?? '').toString(),
                    radius: imageSize / 2,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '#${user['rank'] ?? '-'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: frameWidth * 0.78),
                child: Text(
                  user['nickname'] ?? 'common.unknown_user'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyles.textFieldTitle.copyWith(fontSize: textSize),
                ),
              ),
              const SizedBox(width: 3),
              _buildRozetIcon((user['rozet'] ?? '').toString(), 15),
            ],
          ),
          Text(
            "${user['antPoint'] ?? 0}p",
            style: TextStyles.textFieldTitle.copyWith(fontSize: textSize - 1),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(
    BuildContext context,
    Map<String, dynamic> user,
    int rank, {
    required bool isCurrentUser,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _rowBackground(rank, isCurrentUser),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              Container(
                alignment: Alignment.center,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _rankBadgeColor(rank, isCurrentUser),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: rank <= 3 || isCurrentUser
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: isCurrentUser
                      ? null
                      : () {
                          const ProfileNavigationService().openSocialProfile(
                            user['userID']?.toString() ?? '',
                          );
                        },
                  child: Row(
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 38,
                          height: 38,
                          child: CachedUserAvatar(
                            imageUrl: (user['avatarUrl'] ?? '').toString(),
                            radius: 19,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user['nickname'] ??
                                        'common.unknown_user'.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyles.textFieldTitle
                                        .copyWith(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                _buildRozetIcon(
                                  (user['rozet'] ?? '').toString(),
                                  13,
                                ),
                              ],
                            ),
                            Text(
                              "${user['firstName']} ${user['lastName']}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${user['antPoint']}p",
                style: TextStyles.textFieldTitle.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _rankBadgeColor(int rank, bool isCurrentUser) {
    if (isCurrentUser) return Colors.indigo;
    switch (rank) {
      case 1:
        return const Color(0xFFD4A63A);
      case 2:
        return const Color(0xFF9FA6B2);
      case 3:
        return const Color(0xFFB46A3C);
      default:
        return Colors.white;
    }
  }

  Color _rowBackground(int rank, bool isCurrentUser) {
    if (isCurrentUser) {
      return Colors.indigo.withValues(alpha: 0.06);
    }
    switch (rank) {
      case 1:
        return const Color(0xFFFFF7E2);
      case 2:
        return const Color(0xFFF5F7FA);
      case 3:
        return const Color(0xFFFFF0E8);
      default:
        return Colors.white;
    }
  }

  Widget _buildRozetIcon(String rozet, double size) {
    final color = mapRozetToColor(rozet);
    if (color == Colors.transparent) {
      return const SizedBox.shrink();
    }

    return Transform.translate(
      offset: const Offset(0, -1),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size - 7,
            height: size - 7,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            CupertinoIcons.checkmark_seal_fill,
            color: color,
            size: size,
          ),
        ],
      ),
    );
  }
}
