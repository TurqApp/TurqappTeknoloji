import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/Helpers/GlobalLoader/global_loader.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Widgets/turq_search_bar.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Core/Slider/slider_admin_view.dart';
import 'package:turqappv2/Modules/JobFinder/JobContent/job_content.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder_controller.dart';
import 'package:turqappv2/Modules/TypeWriter/type_writer.dart';

import '../../Themes/app_assets.dart';

class JobFinder extends StatelessWidget {
  JobFinder({
    super.key,
    this.embedded = false,
    this.showEmbeddedControls = true,
  });
  final bool embedded;
  final bool showEmbeddedControls;
  final controller = Get.put(JobFinderController());

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
        Expanded(child: _kesfetTab(context)),
      ],
    );

    if (embedded) {
      return Stack(
        children: [
          Column(
            children: [
              Expanded(child: content),
              GlobalLoader(),
            ],
          ),
          if (showEmbeddedControls && AdminAccessService.isKnownAdminSync())
            Positioned(
              right: 20,
              bottom: 20,
              child: ActionButton(
                context: context,
                menuItems: [
                  PullDownMenuItem(
                    icon: CupertinoIcons.slider_horizontal_3,
                    title: 'Slider Yönetimi',
                    onTap: () => Get.to(
                      () => const SliderAdminView(
                        sliderId: 'is_bul',
                        title: 'İş Bul',
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Standalone header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(CupertinoIcons.arrow_left,
                            color: Colors.black, size: 25),
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
                    onPressed: () => controller.showIlSec(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: Colors.red),
                          const SizedBox(width: 3),
                          Text(
                            controller.sehir.value.isNotEmpty
                                ? controller.sehir.value
                                : "Tüm Türkiye",
                            style: const TextStyle(
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
            Expanded(child: content),
            GlobalLoader(),
          ],
        ),
      ),
      floatingActionButton: AdminAccessService.isKnownAdminSync()
          ? ActionButton(
              context: context,
              menuItems: [
                PullDownMenuItem(
                  icon: CupertinoIcons.slider_horizontal_3,
                  title: 'Slider Yönetimi',
                  onTap: () => Get.to(
                    () => const SliderAdminView(
                      sliderId: 'is_bul',
                      title: 'İş Bul',
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  // ─── Tab 1: Keşfet ───
  Widget _kesfetTab(BuildContext context) {
    return Obx(() {
      if (controller.list.isEmpty) {
        return Column(
          children: [
            _kesfetHeader(isSearching: false, context: context),
            const SizedBox(height: 50),
            EmptyRow(text: "Sonuç bulunamadı"),
          ],
        );
      }

      final query = controller.search.text.trim();
      final isSearching = query.length >= 2;
      final tumTurkiye = controller.sehir.value.isEmpty ||
          controller.sehir.value == "Tüm Türkiye";

      final dataList = isSearching
          ? (tumTurkiye
              ? controller.aramaSonucu
              : controller.aramaSonucu
                  .where(
                      (e) => e.city.toString().contains(controller.sehir.value))
                  .toList())
          : (tumTurkiye
              ? controller.list
              : controller.list
                  .where(
                      (e) => e.city.toString().contains(controller.sehir.value))
                  .toList());

      final screenWidth = MediaQuery.of(context).size.width;
      final itemWidth = screenWidth * 0.5;
      final itemHeight = itemWidth / 0.56;
      final aspectRatio = itemWidth / itemHeight;

      if (controller.listingSelection.value == 0) {
        if (dataList.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kesfetHeader(isSearching: isSearching, context: context),
              EmptyRow(text: "Şehrinde bir ilan bulunmuyor"),
            ],
          );
        }
        return ListView.builder(
          itemCount: dataList.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _kesfetHeader(isSearching: isSearching, context: context);
            }
            final model = dataList[index - 1];
            return JobContent(model: model, isGrid: false);
          },
        );
      } else {
        if (dataList.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kesfetHeader(isSearching: isSearching, context: context),
              EmptyRow(text: "Şehrinde bir ilan bulunmuyor"),
            ],
          );
        }
        return SingleChildScrollView(
          child: Column(
            children: [
              _kesfetHeader(isSearching: isSearching, context: context),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: GridView.builder(
                  itemCount: dataList.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: screenWidth * 0.5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: aspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    return JobContent(model: dataList[index], isGrid: true);
                  },
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  Widget _kesfetHeader(
      {required bool isSearching, required BuildContext context}) {
    return Column(
      children: [
        EducationSlider(
          sliderId: 'is_bul',
          imageList: [AppAssets.job1, AppAssets.job2, AppAssets.job3],
        ),
        if (!embedded) ...[
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TurqSearchBar(
              controller: controller.search,
              hintText: "Ne tür iş arıyorsun ?",
            ),
          ),
        ],
        if (!isSearching)
          Obx(() {
            return Padding(
              padding: const EdgeInsets.only(
                  left: 15, right: 15, top: 15, bottom: 7),
              child: Row(
                children: [
                  const Expanded(
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
                    onTap: () => controller.siralaTapped(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.arrow_up_arrow_down,
                          size: 14,
                          color: controller.short.value != 0
                              ? Colors.pinkAccent
                              : Colors.black,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          controller.short.value == 0
                              ? "Sırala"
                              : controller.short.value == 1
                                  ? "Yüksek Maaş"
                                  : controller.short.value == 2
                                      ? "Düşük Maaş"
                                      : "En Yakın",
                          style: TextStyle(
                            color: controller.short.value != 0
                                ? Colors.pinkAccent
                                : Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(25, 25),
                      fixedSize: const Size(30, 30),
                    ),
                    onPressed: () => controller.filtreTapped(),
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
                      minimumSize: const Size(25, 25),
                      fixedSize: const Size(30, 30),
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
