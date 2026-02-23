import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/Helpers/GlobalLoader/global_loader.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Modules/JobFinder/FindingJobApply/finding_job_apply.dart';
import 'package:turqappv2/Modules/JobFinder/JobContent/job_content.dart';
import 'package:turqappv2/Modules/JobFinder/JobCreator/job_creator.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder_controller.dart';
import 'package:turqappv2/Modules/JobFinder/MyJobAds/my_job_ads.dart';
import 'package:turqappv2/Modules/JobFinder/SavedJobs/saved_jobs.dart';
import 'package:turqappv2/Modules/TypeWriter/type_writer.dart';

import '../../Core/Buttons/action_button.dart';
import '../../Themes/app_assets.dart';
import '../Profile/Cv/cv.dart';

class JobFinder extends StatelessWidget {
  JobFinder({super.key});
  final controller = Get.put(JobFinderController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                // ✨ YENİ: Veri çekiliyorsa bu mesajı göster
                if (controller.list.isEmpty) {
                  return Column(
                    children: [
                      header(isSearching: false, context: context),
                      SizedBox(
                        height: 50,
                      ),
                      EmptyRow(text: "Sonuç bulunamadı")
                    ],
                  );
                }

                // 👇 Aşağısı eskiden olduğu gibi
                final query = controller.search.text.trim();
                final isSearching = query.length >= 3;
                final tumTurkiye = controller.sehir.value.isEmpty ||
                    controller.sehir.value == "Tüm Türkiye";

                final dataList = isSearching
                    ? (tumTurkiye
                        ? controller.aramaSonucu
                        : controller.aramaSonucu
                            .where((e) => e.city
                                .toString()
                                .contains(controller.sehir.value))
                            .toList())
                    : (tumTurkiye
                        ? controller.list
                        : controller.list
                            .where((e) => e.city
                                .toString()
                                .contains(controller.sehir.value))
                            .toList());

                final screenWidth = MediaQuery.of(context).size.width;
                final itemWidth = screenWidth * 0.5;
                final itemHeight = itemWidth / 0.61;
                final aspectRatio = itemWidth / itemHeight;

                if (controller.listingSelection.value == 0) {
                  // Liste görünümü
                  if (dataList.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        header(isSearching: isSearching, context: context),
                        EmptyRow(text: "Şehrinde bir ilan bulunmuyor")
                      ],
                    );
                  }
                  return ListView.builder(
                    itemCount: dataList.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return header(
                            isSearching: isSearching, context: context);
                      }
                      final model = dataList[index - 1];
                      return JobContent(model: model, isGrid: false);
                    },
                  );
                } else {
                  // Grid görünümü
                  if (dataList.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        header(isSearching: isSearching, context: context),
                        EmptyRow(text: "Şehrinde bir ilan bulunmuyor")
                      ],
                    );
                  }
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        header(isSearching: isSearching, context: context),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          child: GridView.builder(
                            itemCount: dataList.length,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: screenWidth * 0.5,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: aspectRatio,
                            ),
                            itemBuilder: (context, index) {
                              return JobContent(
                                  model: dataList[index], isGrid: true);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }),
            ),
            GlobalLoader()
          ],
        ),
      ),
      floatingActionButton: ActionButton(
        context: context,
        menuItems: [
          PullDownMenuItem(
            title: 'İş İlanlarım',
            icon: CupertinoIcons.doc_text,
            onTap: () {
              Get.to(() => MyJobAds());
            },
          ),
          PullDownMenuItem(
            title: 'İlan Oluştur',
            icon: CupertinoIcons.plus,
            onTap: () {
              Get.to(() => JobCreator());
            },
          ),
          PullDownMenuItem(
            title: 'Kaydedilenler',
            icon: CupertinoIcons.bookmark,
            onTap: () {
              Get.to(() => SavedJobs());
            },
          ),
          PullDownMenuItem(
            title: 'Özgeçmişim',
            icon: CupertinoIcons.doc_plaintext,
            onTap: () {
              Get.to(() => Cv());
            },
          ),
          PullDownMenuItem(
            title: 'İş Arıyorum',
            icon: CupertinoIcons.search,
            onTap: () {
              Get.to(() => FindingJobApply());
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget header({required bool isSearching, required BuildContext context}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    Get.back();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity:
                        VisualDensity.compact, // opsiyonel: daha da sıkıştırır
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      CupertinoIcons.arrow_left,
                      color: Colors.black,
                      size: 25,
                    ),
                  ),
                ),
                TypewriterText(text: "İş Bul"),
              ],
            ),
            Obx(() {
              return TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  controller.showIlSec();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: Colors.red),
                      SizedBox(width: 3),
                      Text(
                        controller.sehir.value != ""
                            ? controller.sehir.value
                            : "Tüm Türkiye",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
        EducationSlider(
          imageList: [AppAssets.job1, AppAssets.job2, AppAssets.job3],
        ),
        SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Container(
            height: 50,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: controller.search,
                decoration: InputDecoration(
                  hintText: "Ne tür iş arıyorsun ?",
                  icon: Icon(CupertinoIcons.search, color: Colors.pinkAccent),
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontFamily: "MontserratMedium",
                  ),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ),
        ),
        if (!isSearching)
          Obx(() {
            return Padding(
              padding: const EdgeInsets.only(
                left: 15,
                right: 15,
                top: 15,
                bottom: 7,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Sana En Yakın İlanlar",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      controller.siralaTapped();
                    },
                    child: Text(
                      controller.short.value != 3 ? "Sırala" : "En Yakın",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                  SizedBox(width: 7),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: Size(25, 25),
                      fixedSize: Size(30, 30),
                    ),
                    onPressed: () {
                      controller.filtreTapped();
                    },
                    child: Icon(
                      Icons.filter_alt_outlined,
                      color: controller.filtre.value
                          ? Colors.pinkAccent
                          : Colors.black,
                      size: 20,
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: Size(25, 25),
                      fixedSize: Size(30, 30),
                    ),
                    onPressed: () {
                      controller.listingSelection.value =
                          controller.listingSelection.value == 0 ? 1 : 0;
                    },
                    child: Icon(
                      controller.listingSelection.value == 0
                          ? CupertinoIcons.list_bullet
                          : CupertinoIcons.square_grid_2x2,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
