import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Core/Slider/slider_admin_view.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Modules/Education/Tutoring/CreateTutoring/create_tutoring_view.dart';
import 'package:turqappv2/Modules/Education/Tutoring/FilterBottomSheet/tutoring_filter_bottom_sheet.dart';
import 'package:turqappv2/Modules/Education/Tutoring/FilterBottomSheet/tutoring_filter_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/LocationBasedTutoring/location_based_tutoring.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutorings/my_tutorings.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/saved_tutorings_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_category.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringSearch/tutoring_search.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_widget_builder.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/saved_tutorings.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutoringApplications/my_tutoring_applications.dart';
import 'package:turqappv2/Modules/Education/Tutoring/view_mode_controller.dart';
import 'package:turqappv2/Modules/TypeWriter/type_writer.dart';
import 'package:turqappv2/Themes/app_assets.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class TutoringView extends StatelessWidget {
  TutoringView({
    super.key,
    this.embedded = false,
    this.showEmbeddedControls = true,
  });

  final bool embedded;
  final bool showEmbeddedControls;
  final TutoringController tutoringController = Get.put(TutoringController());
  final ViewModeController viewModeController = Get.put(ViewModeController());
  final TutoringFilterController filterController =
      Get.put(TutoringFilterController());
  final applyFilterTrigger = false.obs;
  ScrollController get _scrollController => tutoringController.scrollController;

  @override
  Widget build(BuildContext context) {
    Get.put(SavedTutoringsController());
    final bodyContent = Expanded(
      child: RefreshIndicator(
        color: Colors.white,
        backgroundColor: Colors.black,
        onRefresh: () async {
          tutoringController.listenToTutoringData();
          applyFilterTrigger.value = false;
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          child: Obx(() {
            List<TutoringModel> filteredList =
                (tutoringController.hasActiveSearch
                        ? tutoringController.searchResults
                        : tutoringController.tutoringList)
                    .toList();

            if (applyFilterTrigger.value) {
              if (filterController.selectedBranch.value != null &&
                  filterController.selectedBranch.value!.isNotEmpty) {
                filteredList = filteredList
                    .where(
                      (tutoring) =>
                          tutoring.brans ==
                          filterController.selectedBranch.value,
                    )
                    .toList();
              }
              if (filterController.selectedGender.value != null &&
                  filterController.selectedGender.value!.isNotEmpty) {
                filteredList = filteredList
                    .where(
                      (tutoring) =>
                          tutoring.cinsiyet ==
                          filterController.selectedGender.value,
                    )
                    .toList();
              }
              if (filterController.selectedLessonPlace.value != null &&
                  filterController.selectedLessonPlace.value!.isNotEmpty) {
                filteredList = filteredList
                    .where(
                      (tutoring) =>
                          filterController.selectedLessonPlace.value!.any(
                        (place) => tutoring.dersYeri.contains(place),
                      ),
                    )
                    .toList();
              }
              if (filterController.maxPrice.value != null) {
                filteredList = filteredList
                    .where(
                      (tutoring) =>
                          tutoring.fiyat <= filterController.maxPrice.value!,
                    )
                    .toList();
              }
              if (filterController.minPrice.value != null) {
                filteredList = filteredList
                    .where(
                      (tutoring) =>
                          tutoring.fiyat >= filterController.minPrice.value!,
                    )
                    .toList();
              }
              if (filterController.selectedCity.value != null &&
                  filterController.selectedCity.value!.isNotEmpty) {
                filteredList = filteredList
                    .where(
                      (tutoring) =>
                          tutoring.sehir == filterController.selectedCity.value,
                    )
                    .toList();
              }
              if (filterController.selectedDistrict.value != null &&
                  filterController.selectedDistrict.value!.isNotEmpty) {
                filteredList = filteredList
                    .where(
                      (tutoring) =>
                          tutoring.ilce ==
                          filterController.selectedDistrict.value,
                    )
                    .toList();
              }

              // Sıralama ölçütü
              if (filterController.selectedLessonPlace.value!.contains(
                'En Yeniler',
              )) {
                filteredList.sort(
                  (a, b) => b.timeStamp.compareTo(a.timeStamp),
                ); // Yeniden eskiye
              } else if (filterController.selectedLessonPlace.value!
                  .contains('Fiyat: Düşükten Yükseğe')) {
                filteredList.sort(
                  (a, b) => a.fiyat.compareTo(b.fiyat),
                ); // Azdan çoğa
              } else if (filterController.selectedLessonPlace.value!
                  .contains('Fiyat: Yüksekten Düşüğe')) {
                filteredList.sort(
                  (a, b) => b.fiyat.compareTo(a.fiyat),
                ); // Çoktan aza
              }
            }

            return Column(
              children: [
                EducationSlider(
                  sliderId: 'ozel_ders',
                  imageList: [
                    AppAssets.tutoring1,
                    AppAssets.tutoring2,
                    AppAssets.tutoring3,
                  ],
                ),
                16.ph,
                TutoringCategoryWidget(categories: kategoriler),
                if (!embedded) ...[
                  16.ph,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          margin: EdgeInsets.symmetric(horizontal: 15),
                          child: CupertinoTextField(
                            focusNode: tutoringController.focusNode,
                            cursorColor: Colors.black,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            placeholder: "Ara",
                            onTap: () {
                              Get.to(() => TutoringSearch());
                            },
                            prefix: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Icon(
                                AppIcons.search,
                                color: Colors.pink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                16.ph,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Sana Özel", style: TextStyles.bold18Black),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              closeKeyboard(context);
                              Get.bottomSheet(
                                TutoringFilterBottomSheet(
                                  controller: tutoringController,
                                ),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                isScrollControlled: true,
                              ).then((_) {
                                applyFilterTrigger.value = true;
                              });
                            },
                            icon: Icon(Icons.filter_alt_outlined),
                            color: applyFilterTrigger.value
                                ? Colors.pink
                                : Colors.black,
                          ),
                          Obx(
                            () => GestureDetector(
                              onTap: () {
                                viewModeController.toggleView();
                              },
                              child: Icon(
                                viewModeController.isGridView.value
                                    ? AppIcons.squareGrid2
                                    : AppIcons.list,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                8.ph,
                Obx(() {
                  if (tutoringController.isLoading.value) {
                    return Center(child: CupertinoActivityIndicator());
                  }
                  if (tutoringController.isSearchLoading.value) {
                    return Center(child: CupertinoActivityIndicator());
                  }
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: TutoringWidgetBuilder(
                      tutoringList: filteredList,
                      users: tutoringController.users,
                      isGridView: viewModeController.isGridView.value,
                    ),
                  );
                }),
                Obx(() {
                  if (tutoringController.isLoadingMore.value) {
                    return Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CupertinoActivityIndicator()),
                    );
                  }
                  return SizedBox.shrink();
                }),
              ],
            );
          }),
        ),
      ),
    );

    final overlays = [
      ScrollTotopButton(
        scrollController: _scrollController,
        visibilityThreshold: 350,
      ),
      Obx(
        () => Positioned(
          bottom: 20,
          right: 20,
          child: Visibility(
            visible: tutoringController.scrollOffset.value <= 350,
            child: ActionButton(
              context: context,
              menuItems: [
                PullDownMenuItem(
                  title: 'Başvurularım',
                  icon: CupertinoIcons.doc_text,
                  onTap: () {
                    Get.to(() => MyTutoringApplications());
                  },
                ),
                PullDownMenuItem(
                  title: 'Kaydedilenler',
                  icon: AppIcons.save,
                  onTap: () {
                    Get.to(() => SavedTutorings());
                  },
                ),
                PullDownMenuItem(
                  title: 'Bölgemdeki İlanlar',
                  icon: AppIcons.locationSolid,
                  onTap: () {
                    Get.to(() => LocationBasedTutoring());
                  },
                ),
                PullDownMenuItem(
                  title: 'Özel Ders İlanlarım',
                  icon: CupertinoIcons.list_bullet,
                  onTap: () {
                    Get.to(MyTutorings());
                  },
                ),
                PullDownMenuItem(
                  title: 'Oluştur',
                  icon: CupertinoIcons.add_circled,
                  onTap: () {
                    Get.to(CreateTutoringView());
                  },
                ),
                PullDownMenuItem(
                  title: 'Slider Yönetimi',
                  icon: CupertinoIcons.slider_horizontal_3,
                  onTap: () {
                    Get.to(
                      () => const SliderAdminView(
                        sliderId: 'ozel_ders',
                        title: 'Özel Ders',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ];

    if (embedded) {
      return Stack(
        children: [
          Column(
            children: [
              bodyContent,
              15.ph,
            ],
          ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                        text: "Özel Ders",
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      Get.to(() => TutoringSearch());
                    },
                    icon: Icon(AppIcons.search),
                  ),
                ],
              ),
              bodyContent,
              15.ph,
            ],
          ),
          ...overlays,
        ]),
      ),
    );
  }
}
