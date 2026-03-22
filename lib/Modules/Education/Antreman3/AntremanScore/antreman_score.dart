import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Antreman3/AntremanScore/antreman_score_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class AntremanScore extends StatefulWidget {
  const AntremanScore({super.key});

  @override
  State<AntremanScore> createState() => _AntremanScoreState();
}

class _AntremanScoreState extends State<AntremanScore> {
  late final AntremanScoreController controller;
  final String currentUserID = CurrentUserService.instance.effectiveUserId;
  final ScrollController _scrollController = ScrollController();
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'antreman_score_${identityHashCode(this)}';
    controller = AntremanScoreController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    final existing = AntremanScoreController.maybeFind(tag: _controllerTag);
    if (identical(existing, controller)) {
      Get.delete<AntremanScoreController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(children: [
          Column(
            children: [
              BackButtons(
                text: 'training.monthly_scoreboard'
                    .trParams({'month': controller.monthName}),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return Center(child: CupertinoActivityIndicator());
                  }
                  if (controller.leaderboard.isEmpty) {
                    return RefreshIndicator(
                      color: Colors.white,
                      backgroundColor: Colors.black,
                      onRefresh: () => controller.fetchLeaderboard(),
                      child: ListView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: (MediaQuery.of(context).size.height * 0.22)
                                .clamp(130.0, 180.0),
                          ),
                          Center(
                            child: Text("training.leaderboard_empty".tr),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              "training.leaderboard_empty_body".tr,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: Colors.white,
                    backgroundColor: Colors.black,
                    onRefresh: () => controller.fetchLeaderboard(),
                    child: ListView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F8F6),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.05),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              if (controller.leaderboard.isNotEmpty) ...[
                                _buildPodiumItem(
                                  context,
                                  controller.leaderboard[0],
                                  'assets/images/gold.webp',
                                  124,
                                  76,
                                  15,
                                ),
                              ],
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (controller.leaderboard.length >= 2) ...[
                                    _buildPodiumItem(
                                      context,
                                      controller.leaderboard[1],
                                      'assets/images/silver.webp',
                                      124,
                                      76,
                                      15,
                                    ),
                                    const SizedBox(width: 28),
                                  ],
                                  if (controller.leaderboard.length >= 3) ...[
                                    _buildPodiumItem(
                                      context,
                                      controller.leaderboard[2],
                                      'assets/images/bronz.webp',
                                      124,
                                      76,
                                      15,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        ...controller.leaderboard.skip(3).map((user) {
                          return Column(
                            children: [
                              _buildUserItem(
                                context,
                                user,
                                user['rank'],
                                isCurrentUser: user['userID'] == currentUserID,
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
          ScrollTotopButton(
            scrollController: _scrollController,
            visibilityThreshold: 350,
          ),
        ]),
      ),
    );
  }

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
              Get.to(() => SocialProfile(userID: podiumUserID));
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
                child: CachedNetworkImage(
                  imageUrl: user['avatarUrl'] ?? '',
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => CupertinoActivityIndicator(),
                  errorWidget: (context, url, error) =>
                      Icon(Icons.person, size: 24),
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
                  "$rank",
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
                          Get.to(() => SocialProfile(userID: user['userID']));
                        },
                  child: Row(
                    children: [
                      ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: user['avatarUrl'] ?? '',
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const CupertinoActivityIndicator(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.person, size: 38),
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
