import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:turqappv2/Core/BottomSheets/NoYesAlert.dart';
import 'package:turqappv2/Modules/Education/Scholarships/SavedItems/SavedItemsController.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipDetail/ScholarshipDetailView.dart';
import 'package:turqappv2/Themes/AppIcons.dart';

class SavedItemsView extends StatelessWidget {
  SavedItemsView({super.key});

  final SavedItemsController controller = Get.put(SavedItemsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Obx(
            //   () => AppHeaderWidget(
            //     title:
            //         controller.selectedTabIndex.value == 0
            //             ? "Kaydedilenler (${controller.bookmarkedScholarships.length})"
            //             : "Beğenilenler (${controller.likedScholarships.length})",
            //   ),
            // ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: Icon(AppIcons.arrowLeft, size: 25, color: Colors.black),
                ),
                Expanded(
                  child: Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => controller.onTabChanged(0),
                                child: Text(
                                  'Kaydedilenler (${controller.bookmarkedScholarships.length})',
                                  style: TextStyle(
                                    color:
                                        controller.selectedTabIndex.value == 0
                                            ? Colors.black
                                            : Colors.black54,
                                    fontSize: 20,
                                    fontFamily: 'MontserratBold',
                                  ),
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                height: 2,
                                color: controller.selectedTabIndex.value == 0
                                    ? Colors.black
                                    : Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => controller.onTabChanged(1),
                                child: Text(
                                  'Beğenilenler (${controller.likedScholarships.length})',
                                  style: TextStyle(
                                    color:
                                        controller.selectedTabIndex.value == 1
                                            ? Colors.black
                                            : Colors.black54,
                                    fontSize: 20,
                                    fontFamily: 'MontserratBold',
                                  ),
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                height: 2,
                                color: controller.selectedTabIndex.value == 1
                                    ? Colors.black
                                    : Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: Obx(
                () => controller.isLoading.value &&
                        controller.likedScholarships.isEmpty &&
                        controller.bookmarkedScholarships.isEmpty
                    ? Center(child: CupertinoActivityIndicator())
                    : PageView(
                        controller: controller.pageController,
                        onPageChanged: (index) =>
                            controller.onTabChanged(index),
                        children: [
                          buildScholarshipList(
                            context,
                            controller.bookmarkedScholarships,
                            'Kaydedilen burs bulunamadı.',
                            true,
                          ),
                          buildScholarshipList(
                            context,
                            controller.likedScholarships,
                            'Beğenilen burs bulunamadı.',
                            false,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildScholarshipList(
    BuildContext context,
    RxList<Map<String, dynamic>> scholarships,
    String emptyMessage,
    bool isBookmarked,
  ) {
    return Obx(
      () => RefreshIndicator(
        backgroundColor: Colors.black,
        color: Colors.white,
        onRefresh: () async {
          controller.bindStreams();
        },
        child: scholarships.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.info, size: 35, color: Colors.grey),
                    Text(
                      emptyMessage,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'MontserratMedium',
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: scholarships.length,
                itemBuilder: (context, index) {
                  final scholarshipData = scholarships[index];
                  final burs = scholarshipData['model'];
                  final type = scholarshipData['type'] as String;
                  final userData =
                      scholarshipData['userData'] as Map<String, dynamic>?;
                  final firmaData =
                      scholarshipData['firmaData'] as Map<String, dynamic>?;
                  final docId = scholarshipData['docId'] as String;

                  return GestureDetector(
                    onTap: () {
                      Get.to(
                        () => ScholarshipDetailView(),
                        arguments: scholarshipData,
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (burs.img.isNotEmpty)
                            SizedBox(
                              width: 120,
                              height: 90,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: CachedNetworkImage(
                                  memCacheHeight: 1000,
                                  imageUrl: burs.img,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: CupertinoActivityIndicator(),
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 120,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.grey.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.image,
                                color: Colors.grey,
                                size: 40,
                              ),
                            ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        type == 'bireysel'
                                            ? "${burs.baslik} BURS BAŞVURULARI"
                                            : burs.baslik,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'MontserratBold',
                                          color: Colors.black,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    PullDownButton(
                                      itemBuilder: (context) => [
                                        PullDownMenuItem(
                                          iconColor: Colors.black,
                                          icon: isBookmarked
                                              ? CupertinoIcons.bookmark_fill
                                              : CupertinoIcons
                                                  .hand_thumbsup_fill,
                                          title: isBookmarked
                                              ? 'Kaydedilenlerden Kaldır'
                                              : 'Beğenilenlerden Kaldır',
                                          onTap: () {
                                            noYesAlert(
                                              title: isBookmarked
                                                  ? 'Kaydedilenlerden Kaldır'
                                                  : 'Beğenilenlerden Kaldır',
                                              message: isBookmarked
                                                  ? 'Bu bursu kaydedilenlerden kaldırmak istediğinize emin misiniz?'
                                                  : 'Bu bursu beğenilenlerden kaldırmak istediğinize emin misiniz?',
                                              onYesPressed: () {
                                                if (isBookmarked) {
                                                  controller.toggleBookmark(
                                                    docId,
                                                    type,
                                                  );
                                                } else {
                                                  controller.toggleLike(
                                                    docId,
                                                    type,
                                                  );
                                                }
                                                AppSnackbar(
                                                  "Başarılı",
                                                  isBookmarked
                                                      ? "Burs Kaydedilenlerden Kaldırıldı."
                                                      : "Burs Beğenilenlerden Kaldırıldı.",
                                                );
                                              },
                                              yesText: "Kaldır",
                                              cancelText: "Vazgeç",
                                            );
                                          },
                                        ),
                                      ],
                                      buttonBuilder: (context, showMenu) =>
                                          GestureDetector(
                                        onTap: showMenu,
                                        child: Icon(
                                          AppIcons.info,
                                          size: 18,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  type == 'bireysel'
                                      ? (userData?['nickname']?.isNotEmpty ??
                                              false
                                          ? userData!['nickname']
                                          : 'Bilinmeyen Kullanıcı')
                                      : (burs.kategori?.isNotEmpty ?? false
                                          ? burs.kategori
                                          : 'Bilinmeyen Kategori'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'MontserratMedium',
                                    color: Colors.blue.shade900,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  burs.aciklama,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Montserrat',
                                    color: Colors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
