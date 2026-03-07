import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/Profile/MyStatistic/my_statistic_controller.dart';
import 'package:turqappv2/Services/firebase_my_store.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class MyStatisticView extends StatelessWidget {
  MyStatisticView({super.key});

  final MyStatisticController controller = Get.put(MyStatisticController());
  final user = Get.find<FirebaseMyStore>();
  static const List<Color> _statColors = [
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          return RefreshIndicator(
              backgroundColor: Colors.black,
              color: Colors.white,
              onRefresh: controller.refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    BackButtons(text: "İstatistikler"),
                    if (controller.isLoading.value)
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Center(child: CupertinoActivityIndicator()),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        children: [
                          // Kullanıcı kartı...
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
                                      child: user.avatarUrl.value != ""
                                          ? CachedNetworkImage(
                                              imageUrl: user.avatarUrl.value,
                                              fit: BoxFit.cover,
                                            )
                                          : const Center(
                                              child: CupertinoActivityIndicator(
                                                color: Colors.grey,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              "${user.firstName.value} ${user.lastName.value}",
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontFamily: "MontserratBold",
                                              ),
                                            ),
                                            RozetContent(
                                              size: 15,
                                              userID: FirebaseAuth
                                                  .instance.currentUser!.uid,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user.nickname.value,
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
                                  const Text(
                                    "Siz",
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
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "İstatistiksel verileriniz, 30 günlük aktivitelerinize göre düzenli olarak güncellenmektedir.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Dinamik istatistikler
                          Obx(() => _statItem(
                                controller.profileVisitsApprox.value,
                                "Profil Ziyareti (30 Gün)",
                                0,
                              )),
                          Row(
                            children: [
                              Expanded(
                                child: Obx(() => _statItem(
                                      controller.postViews30d.value,
                                      "Gönderi Görüntüleme",
                                      1,
                                    )),
                              ),
                              8.pw,
                              Expanded(
                                child: Obx(() => _statItem(
                                      controller.posts30d.value,
                                      "Gönderi Sayısı",
                                      2,
                                    )),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Obx(() => _statItem(
                                      controller.stories30d.value,
                                      "Hikaye Sayısı",
                                      6,
                                    )),
                              ),
                              8.pw,
                              Expanded(
                                child: Obx(() => _statItem(
                                      controller.followerGrowth30d.value,
                                      "Takipçi Artışı",
                                      8,
                                    )),
                              ),
                            ],
                          ),
                          10.ph,
                          const AdmobKare(),
                          10.ph,
                        ],
                      ),
                    ),
                  ],
                ),
              ));
        }),
      ),
    );
  }

  Widget _statItem(num value, String title, int colorIndex) {
    final bgColor = _statColors[colorIndex % _statColors.length];

    // Görünecek metin: yüzde ise “%” ekle, değilse NumberFormatter ile binlik ayracı kullan
    final displayText = NumberFormatter.format(value.toInt());

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
