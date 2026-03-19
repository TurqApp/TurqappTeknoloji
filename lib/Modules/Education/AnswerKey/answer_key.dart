import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Core/Slider/slider_admin_view.dart';
import 'package:turqappv2/Core/Widgets/pasaj_listing_ad_layout.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyContent/answer_key_content.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/answer_key_controller.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyCreatingOption/answer_key_creating_option.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/CategoryBasedAnswerKey/category_based_answer_key.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/MyBookletResults/my_booklet_results.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticalFormEntry/optical_form_entry.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticsAndBooksPublished/optics_and_books_published.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/SavedOpticalForms/saved_optical_forms.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/SearchAnswerKey/search_answer_key.dart';
import 'package:turqappv2/Modules/TypeWriter/type_writer.dart';
import 'package:turqappv2/Themes/app_assets.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class AnswerKey extends StatelessWidget {
  AnswerKey({
    super.key,
    this.embedded = false,
    this.showEmbeddedControls = true,
  });

  final bool embedded;
  final bool showEmbeddedControls;
  final AnswerKeyController controller = Get.isRegistered<AnswerKeyController>()
      ? Get.find<AnswerKeyController>()
      : Get.put(AnswerKeyController(), permanent: true);
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
        onRefresh: controller.refreshData,
        child: ListView(
          controller: _scrollController, // _scrollController'ı buraya bağla
          children: [
            Obx(
              () {
                if (!controller.listingSelectionReady.value) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                final items = controller.hasActiveSearch
                    ? controller.searchResults
                    : controller.bookList;
                return Column(
                  children: [
                    EducationSlider(
                      sliderId: 'cevap_anahtari',
                      imageList: [
                        AppAssets.optical1,
                        AppAssets.optical2,
                        AppAssets.optical3
                      ],
                    ),
                    8.ph,
                    lessonsCategory(),
                    if (!embedded) search(),
                    controller.isLoading.value
                        ? const Center(child: CupertinoActivityIndicator())
                        : controller.isSearchLoading.value
                            ? const Center(child: CupertinoActivityIndicator())
                            : items.isNotEmpty
                                ? Obx(
                                    () => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15),
                                      child: controller.listingSelection.value ==
                                              0
                                          ? Column(
                                              children: PasajListingAdLayout.buildListChildren(
                                                items: items,
                                                itemBuilder: (item, index) =>
                                                    AnswerKeyContent(
                                                  key: ValueKey(item.docID),
                                                  model: item,
                                                  onUpdate: (v) => controller
                                                      .refreshData(),
                                                  isListLayout: true,
                                                ),
                                                adBuilder: (slot) => AdmobKare(
                                                  key: ValueKey(
                                                      'answer-key-list-ad-$slot'),
                                                ),
                                              ),
                                            )
                                          : Column(
                                              children: PasajListingAdLayout.buildTwoColumnGridChildren(
                                                items: items,
                                                horizontalSpacing: 4,
                                                rowSpacing: 4,
                                                itemBuilder: (item, index) =>
                                                    AnswerKeyContent(
                                                  key: ValueKey(item.docID),
                                                  model: item,
                                                  onUpdate: (v) => controller
                                                      .refreshData(),
                                                ),
                                                adBuilder: (slot) => AdmobKare(
                                                  key: ValueKey(
                                                      'answer-key-grid-ad-$slot'),
                                                ),
                                              ),
                                            ),
                                    ),
                                  )
                                : Container(
                                    color: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 15),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                  Icons.lightbulb_outline,
                                                  color: Colors.black),
                                              const SizedBox(height: 7),
                                              Text(
                                                controller.hasActiveSearch
                                                    ? "Aramana uygun cevap anahtarı yok."
                                                    : "Herhangi bir optik form yok.",
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15,
                                                  fontFamily: "Montserrat",
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );

    final overlays = [
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
                  title: 'answer_key.published'.tr,
                  icon: AppIcons.book,
                  onTap: () => Get.to(OpticsAndBooksPublished()),
                ),
                PullDownMenuItem(
                  title: 'common.saved'.tr,
                  icon: AppIcons.save,
                  onTap: () => Get.to(SavedOpticalForms()),
                ),
                PullDownMenuItem(
                  title: 'answer_key.my_results'.tr,
                  icon: AppIcons.question,
                  onTap: () => Get.to(MyBookletResults()),
                ),
                PullDownMenuItem(
                  title: 'common.create'.tr,
                  icon: AppIcons.addCircled,
                  onTap: () => Get.to(
                      AnswerKeyCreatingOption(onBack: controller.refreshData)),
                ),
                PullDownMenuItem(
                  title: 'pasaj.answer_key.join'.tr,
                  icon: AppIcons.arrowRight,
                  onTap: () => Get.to(OpticalFormEntry()),
                ),
                PullDownMenuItem(
                  title: 'practice.slider_management'.tr,
                  icon: CupertinoIcons.slider_horizontal_3,
                  onTap: () => Get.to(
                    () => SliderAdminView(
                      sliderId: 'cevap_anahtari',
                      title: 'answer_key.title'.tr,
                    ),
                  ),
                ),
              ])))),
    ];

    if (embedded) {
      return Stack(
        children: [
          Column(children: [bodyContent]),
          if (showEmbeddedControls) ...overlays,
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(children: [
          Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon:
                        Icon(AppIcons.arrowLeft, color: Colors.black, size: 25),
                  ),
                  TypewriterText(text: "Cevap Anahtarları"),
                ],
              ),
              bodyContent,
            ],
          ),
          ...overlays,
        ]),
      ),
    );
  }

  Widget search() {
    return GestureDetector(
      onTap: () {
        Get.to(() => SearchAnswerKey());
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
        child: Container(
          height: 50,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(AppIcons.search, color: Colors.pink),
                SizedBox(width: 12),
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
    );
  }

  Widget lessonsCategory() {
    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: controller.lessons.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 25, left: index == 0 ? 20 : 0),
            child: GestureDetector(
              onTap: () {
                Get.to(
                    () => CategoryBasedAnswerKey(sinavTuru: dersler1[index]));
              },
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: controller.lessonsColors[index],
                    ),
                    child: Icon(
                      controller.lessonsIcons[index],
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.lessons[index],
                    style: const TextStyle(
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
    );
  }
}
