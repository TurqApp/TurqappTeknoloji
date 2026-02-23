import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGrid/deneme_grid.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/deneme_sinavlari_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeTurleriListesi/deneme_turleri_listesi.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SearchDeneme/search_deneme.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavHazirla/sinav_hazirla.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavSonuclarim/sinav_sonuclarim.dart';
import 'package:turqappv2/Modules/Profile/BecomeVerifiedAccount/become_verified_account.dart';
import 'package:turqappv2/Modules/TypeWriter/type_writer.dart';
import 'package:turqappv2/Themes/app_assets.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class DenemeSinavlari extends StatelessWidget {
  DenemeSinavlari({super.key});

  final DenemeSinavlariController controller = Get.put(
    DenemeSinavlariController(),
  );
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    _scrollController.addListener(() {
      controller.scrollOffset.value = _scrollController.offset;
    });
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Get.back();
                            },
                            icon: Icon(
                              AppIcons.arrowLeft,
                              color: Colors.black,
                              size: 25,
                            ),
                          ),
                          TypewriterText(
                            text: "Deneme Sınavları",
                          ),
                        ],
                      ),
                    ),
                    // if (controller.ustBar.value)
                    IconButton(
                      onPressed: () => Get.to(() => SearchDeneme()),
                      icon: Icon(AppIcons.search, color: Colors.black),
                    ),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: Colors.white,
                    backgroundColor: Colors.black,
                    onRefresh: controller.getData,
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return Center(child: CupertinoActivityIndicator());
                      }
                      if (controller.list.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.quiz_outlined,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                20.ph,
                                Text(
                                  "Henüz Deneme Sınavı Bulunmuyor",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontFamily: "MontserratBold",
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                10.ph,
                                Text(
                                  "Şu anda sistemde kayıtlı deneme sınavı bulunmamaktadır. Yeni sınavlar eklendiğinde burada görünecektir.",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                    fontFamily: "MontserratMedium",
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return ListView(
                        controller: _scrollController,
                        children: [
                          EducationSlider(
                            imageList: [
                              AppAssets.practice1,
                              AppAssets.practice2,
                              AppAssets.practice3,
                            ],
                          ),
                          20.ph,
                          SizedBox(
                            height: 85,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true,
                              physics: BouncingScrollPhysics(),
                              itemCount: sinavTurleriList.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: 25,
                                    left: index == 0 ? 20 : 0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      Get.to(
                                        () => DenemeTurleriListesi(
                                          sinavTuru: sinavTurleriList[index],
                                        ),
                                      );
                                    },
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: tumderslerColors[index],
                                          ),
                                          child: Icon(
                                            dersler1icons[index],
                                            color: Colors.white,
                                          ),
                                        ),
                                        8.ph,
                                        Text(
                                          sinavTurleriList[index],
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 13,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Get.to(() => SearchDeneme()),
                            child: Container(
                              color: Colors.white,
                              child: Padding(
                                padding: EdgeInsets.all(15),
                                child: Container(
                                  height: 50,
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          AppIcons.search,
                                          color: Colors.pink,
                                        ),
                                        12.pw,
                                        Expanded(
                                          child: Text(
                                            "Ara",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontFamily: "Montserrat",
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              "Deneme Sınavları",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontFamily: "MontserratBold",
                              ),
                            ),
                          ),
                          15.ph,
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                                childAspectRatio: 0.49,
                              ),
                              itemCount: controller.list.length,
                              itemBuilder: (context, index) {
                                return DenemeGrid(
                                  model: controller.list[index],
                                  getData: controller.getData,
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
            Obx(
              () => controller.showOkulAlert.value
                  ? okulAlertSheet(context, controller)
                  : SizedBox.shrink(),
            ),
            ScrollTotopButton(
              scrollController: _scrollController,
              visibilityThreshold: 350,
            ),
            Obx(() => Positioned(
                bottom: 20,
                right: 20,
                child: Visibility(
                    visible: controller.scrollOffset.value <= 350,
                    child: ActionButton(context: context, menuItems: [
                      PullDownMenuItem(
                        icon: Icons.add,
                        title: 'Oluştur',
                        onTap: () {
                          if (controller.okul.value) {
                            Get.to(() => SinavHazirla());
                          } else {
                            controller.showOkulAlert.value = true;
                          }
                        },
                      ),
                      PullDownMenuItem(
                        icon: Icons.history,
                        title: 'Sonuçlarım',
                        onTap: () => Get.to(() => SinavSonuclarim()),
                      ),
                      PullDownMenuItem(
                        icon: CupertinoIcons.search,
                        title: 'Ara',
                        onTap: () => Get.to(() => SearchDeneme()),
                      ),
                    ]))))
          ],
        ),
      ),
    );
  }

  Widget okulAlertSheet(
    BuildContext context,
    DenemeSinavlariController controller,
  ) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        GestureDetector(
          onTap: () => controller.showOkulAlert.value = false,
          child: Container(color: Colors.black.withAlpha(50)),
        ),
        Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(18),
              topLeft: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Sadece Onaylı Kurumlara Özel",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: "MontserratBold",
                  ),
                ),
                12.ph,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    "Deneme sınavları düzenlemek için onaylı bir kurumsal hesaba sahip olmanız gerekmektedir.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ),
                12.ph,
                GestureDetector(
                  onTap: () {
                    Get.to(() => BecomeVerifiedAccount());
                  },
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Text(
                      "Onaylı Hesap Ol",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
