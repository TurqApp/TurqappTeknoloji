import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:turqappv2/Utils/empty_padding.dart';

class AntremanScore extends StatelessWidget {
  AntremanScore({super.key});

  final AntremanScoreController controller = Get.put(AntremanScoreController());
  final String currentUserID = FirebaseAuth.instance.currentUser?.uid ?? '';
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(children: [
          Column(
            children: [
              BackButtons(
                text: "${controller.monthName} Ayı İlk 100",
              ),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return Center(child: CupertinoActivityIndicator());
                  }
                  if (controller.leaderboard.isEmpty) {
                    return Center(child: Text("Kullanıcı bulunamadı!"));
                  }

                  return RefreshIndicator(
                    color: Colors.white,
                    backgroundColor: Colors.black,
                    onRefresh: () => controller.fetchLeaderboard(),
                    child: ListView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        // Podyum
                        Column(
                          children: [
                            if (controller.leaderboard.isNotEmpty) ...[
                              _buildPodiumItem(
                                context,
                                controller.leaderboard[0],
                                'assets/images/gold.webp',
                                160,
                                100,
                                18,
                              ),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (controller.leaderboard.length >= 2) ...[
                                  _buildPodiumItem(
                                    context,
                                    controller.leaderboard[1],
                                    'assets/images/silver.webp',
                                    135,
                                    80,
                                    18,
                                  ),
                                  SizedBox(width: 100),
                                ],
                                if (controller.leaderboard.length >= 3) ...[
                                  _buildPodiumItem(
                                    context,
                                    controller.leaderboard[2],
                                    'assets/images/bronz.webp',
                                    120,
                                    75,
                                    16,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        15.ph,
                        if (!controller.leaderboard.any(
                          (val) => val["userID"] == currentUserID,
                        ))
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(50),
                                      border: Border.all(
                                        color: Colors.grey.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Text(
                                      "Siz",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: "MontserratMedium",
                                        color: Colors.indigo,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: controller.user.pfImage.value,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        CupertinoActivityIndicator(),
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.person, size: 50),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            controller.user.nickname.value,
                                            style: TextStyles.textFieldTitle
                                                .copyWith(fontSize: 16),
                                          ),
                                          SizedBox(width: 5),
                                          RozetContent(
                                            size: 15,
                                            userID: FirebaseAuth.instance
                                                    .currentUser?.uid ??
                                                '',
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "${controller.user.firstName.value} ${controller.user.lastName.value}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "${controller.userPoint.value}p",
                                  style: TextStyles.textFieldTitle,
                                ),
                              ],
                            ),
                          ),

                        // 4. sıradan itibaren diğer kullanıcılar
                        ...controller.leaderboard.sublist(3).map((user) {
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

// Podyum için widget
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
                  imageUrl: user['pfImage'] ?? '',
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => CupertinoActivityIndicator(),
                  errorWidget: (context, url, error) =>
                      Icon(Icons.person, size: 24),
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user['nickname'] ?? 'Bilinmiyor',
                style: TextStyles.textFieldTitle.copyWith(fontSize: textSize),
              ),
              RozetContent(size: 15, userID: podiumUserID),
            ],
          ),
          Text("${user['antPoint'] ?? 0}p", style: TextStyles.textFieldTitle),
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
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      child: Row(
        children: [
          // Sıra numarası
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.indigo : Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Text(
              "$rank",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? Colors.white : Colors.black,
              ),
            ),
          ),
          SizedBox(width: 10),
          // Profil ve bilgiler
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
                      imageUrl: user['pfImage'] ?? '',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          CupertinoActivityIndicator(),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.person, size: 50),
                    ),
                  ),
                  SizedBox(width: 10),
                  // Kullanıcı bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user['nickname'] ?? 'Bilinmiyor',
                              style: TextStyles.textFieldTitle
                                  .copyWith(fontSize: 16),
                            ),
                            SizedBox(width: 5),
                            RozetContent(
                              size: 15,
                              userID: user['userID'] ?? '',
                            ),
                          ],
                        ),
                        Text(
                          "${user['firstName']} ${user['lastName']}",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Puan
          Text("${user['antPoint']}p", style: TextStyles.textFieldTitle),
        ],
      ),
    );
  }
}
