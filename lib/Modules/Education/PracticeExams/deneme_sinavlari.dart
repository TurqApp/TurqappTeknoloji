import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Core/Slider/slider_admin_view.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGrid/deneme_grid.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/MyPracticeExams/my_practice_exams.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/deneme_sinavlari_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeTurleriListesi/deneme_turleri_listesi.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SearchDeneme/search_deneme.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavHazirla/sinav_hazirla.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavSonuclarim/sinav_sonuclarim.dart';
import 'package:turqappv2/Modules/Profile/BecomeVerifiedAccount/become_verified_account.dart';
import 'package:turqappv2/Modules/TypeWriter/type_writer.dart';
import 'package:turqappv2/Themes/app_assets.dart';
import 'package:turqappv2/Core/Widgets/skeleton_loader.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class DenemeSinavlari extends StatelessWidget {
  DenemeSinavlari({
    super.key,
    this.embedded = false,
    this.showEmbeddedControls = true,
  });

  final bool embedded;
  final bool showEmbeddedControls;
  final DenemeSinavlariController controller = Get.put(
    DenemeSinavlariController(),
  );
  ScrollController get _scrollController => controller.scrollController;

  @override
  Widget build(BuildContext context) {
    _scrollController.addListener(() {
      controller.scrollOffset.value = _scrollController.offset;
    });

    final bodyContent = Expanded(
      child: RefreshIndicator(
        color: Colors.white,
        backgroundColor: Colors.black,
        onRefresh: controller.getData,
        child: Obx(() {
          final items = controller.hasActiveSearch
              ? controller.searchResults
              : controller.list;
          if (controller.isLoading.value) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  EducationGridSkeleton(itemCount: 4),
                ],
              ),
            );
          }
          if (controller.isSearchLoading.value) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (items.isEmpty) {
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
                      controller.hasActiveSearch
                          ? "Aramana uygun sınav bulunamadı"
                          : "Henüz Deneme Sınavı Bulunmuyor",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: "MontserratBold",
                      ),
                      textAlign: TextAlign.center,
                    ),
                    10.ph,
                    Text(
                      controller.hasActiveSearch
                          ? "Farklı bir anahtar kelime deneyin."
                          : "Şu anda sistemde kayıtlı deneme sınavı bulunmamaktadır. Yeni sınavlar eklendiğinde burada görünecektir.",
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
                sliderId: 'online_sinav',
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
              if (!embedded)
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
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 0.52,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return DenemeGrid(
                      model: items[index],
                      getData: controller.getData,
                    );
                  },
                ),
              ),
              Obx(() =>
                  !controller.hasActiveSearch && controller.isLoadingMore.value
                      ? Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CupertinoActivityIndicator()),
                        )
                      : SizedBox.shrink()),
            ],
          );
        }),
      ),
    );

    if (embedded) {
      return Stack(
        children: [
          Column(children: [bodyContent]),
          Obx(
            () => controller.showOkulAlert.value
                ? okulAlertSheet(context, controller)
                : SizedBox.shrink(),
          ),
          if (showEmbeddedControls)
            ScrollTotopButton(
              scrollController: _scrollController,
              visibilityThreshold: 350,
            ),
          if (showEmbeddedControls)
            Obx(() => Positioned(
                bottom: 20,
                right: 20,
                child: Visibility(
                    visible: controller.scrollOffset.value <= 350,
                    child: ActionButton(
                      context: context,
                      permissionScope:
                          ActionButtonPermissionScope.practiceExams,
                      menuItems: [
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
                          icon: CupertinoIcons.doc_text,
                          title: 'Yayınladıklarım',
                          onTap: () => Get.to(() => const MyPracticeExams()),
                        ),
                        PullDownMenuItem(
                          icon: CupertinoIcons.bookmark,
                          title: 'Kaydedilenler',
                          onTap: () => Get.to(() => const SavedPracticeExams()),
                        ),
                        PullDownMenuItem(
                          icon: CupertinoIcons.search,
                          title: 'Ara',
                          onTap: () => Get.to(() => SearchDeneme()),
                        ),
                        PullDownMenuItem(
                          icon: CupertinoIcons.slider_horizontal_3,
                          title: 'Slider Yönetimi',
                          onTap: () => Get.to(
                            () => const SliderAdminView(
                              sliderId: 'online_sinav',
                              title: 'Online Sınav',
                            ),
                          ),
                        ),
                      ],
                    )))),
        ],
      );
    }

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
                            text: "Online Sınav",
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.to(() => SearchDeneme()),
                      icon: Icon(AppIcons.search, color: Colors.black),
                    ),
                  ],
                ),
                bodyContent,
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
                    child: ActionButton(
                      context: context,
                      permissionScope:
                          ActionButtonPermissionScope.practiceExams,
                      menuItems: [
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
                          icon: CupertinoIcons.doc_text,
                          title: 'Yayınladıklarım',
                          onTap: () => Get.to(() => const MyPracticeExams()),
                        ),
                        PullDownMenuItem(
                          icon: CupertinoIcons.bookmark,
                          title: 'Kaydedilenler',
                          onTap: () => Get.to(() => const SavedPracticeExams()),
                        ),
                        PullDownMenuItem(
                          icon: CupertinoIcons.search,
                          title: 'Ara',
                          onTap: () => Get.to(() => SearchDeneme()),
                        ),
                        PullDownMenuItem(
                          icon: CupertinoIcons.slider_horizontal_3,
                          title: 'Slider Yönetimi',
                          onTap: () => Get.to(
                            () => const SliderAdminView(
                              sliderId: 'online_sinav',
                              title: 'Online Sınav',
                            ),
                          ),
                        ),
                      ],
                    )))),
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
                  "Sarı Rozet ve Üstüne Özel",
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
                    "Online sınav oluşturmak için sarı rozet veya üstü doğrulanmış hesaba sahip olmanız gerekmektedir.",
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
