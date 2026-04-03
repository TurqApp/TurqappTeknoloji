import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/Education/Antreman3/MyStatistic/my_statistic_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class MyStatisticView extends StatefulWidget {
  const MyStatisticView({super.key});

  @override
  State<MyStatisticView> createState() => _MyStatisticViewState();
}

class _MyStatisticViewState extends State<MyStatisticView> {
  late final MyStatisticController controller;
  final userService = CurrentUserService.instance;
  late final String _controllerTag;
  static const List<Color> _statColors = [
    // Mevcutlar…
    Color(0xFF1E88E5),
    Color(0xFFF4511E),
    Color(0xFFE91E63),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
    Color(0xFF8E24AA),
    Color(0xFF00897B),
    Color(0xFFFFC107),
    Color(0xFF3949AB),
    Color(0xFFD32F2F),

    // Yeni eklemeler:
    Color(0xFF303F9F),
    Color(0xFF03A9F4),
    Color(0xFFCDDC39),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFFE64A19),
    Color(0xFF512DA8),
    Color(0xFF0097A7),
  ];

  @override
  void initState() {
    super.initState();
    _controllerTag = 'antreman_my_statistics_${identityHashCode(this)}';
    controller = MyStatisticController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    final existing = MyStatisticController.maybeFind(tag: _controllerTag);
    if (identical(existing, controller)) {
      Get.delete<MyStatisticController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final currentUser = userService.currentUserRx.value;
          final avatarUrl = currentUser?.avatarUrl ?? '';
          final firstName = currentUser?.firstName ?? '';
          final lastName = currentUser?.lastName ?? '';
          final nickname = currentUser?.nickname ?? '';
          return SingleChildScrollView(
            child: Column(
              children: [
                BackButtons(text: "statistics.title".tr),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    children: [
                      // Kullanıcı kartı
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueAccent),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            children: [
                              ClipOval(
                                child: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: CachedUserAvatar(
                                    imageUrl: avatarUrl,
                                    radius: 25,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "$firstName $lastName",
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratBold",
                                          ),
                                        ),
                                        RozetContent(
                                          size: 15,
                                          userID: userService.userId,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      nickname,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                        fontFamily: "MontserratMedium",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "statistics.you".tr,
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "statistics.notice".tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Renk paletinden sırasıyla 0, 1, 2 indexlerini kullanıyoruz:
                      _statItem(535000, "statistics.profile_visits_30d".tr, 0),
                      _statItem(86, "statistics.post_views_pct".tr, 2,
                          isPercentage: true),
                      _statItem(234000, "statistics.post_views".tr, 1),
                      _statItem(18, "statistics.follower_growth_pct".tr, 6,
                          isPercentage: true),
                      _statItem(123000, "statistics.follower_growth".tr, 8),
                    ],
                  ),
                )
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _statItem(
    num value,
    String title,
    int colorIndex, {
    bool isPercentage = false,
  }) {
    final bgColor = _statColors[colorIndex % _statColors.length];

    // Görünecek metin: yüzde ise “%” ekle, değilse NumberFormatter ile binlik ayracı kullan
    final displayText = isPercentage
        ? "${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}%"
        : NumberFormatter.format(value.toInt());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Column(
            children: [
              Text(
                displayText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: "MontserratBold",
                ),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
