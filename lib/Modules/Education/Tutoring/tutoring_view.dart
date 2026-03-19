import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/Widgets/turq_search_bar.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Core/Slider/slider_admin_view.dart';
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
import 'package:turqappv2/Services/current_user_service.dart';
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
  final TutoringController tutoringController =
      Get.isRegistered<TutoringController>()
          ? Get.find<TutoringController>()
          : Get.put(TutoringController(), permanent: true);
  final ViewModeController viewModeController =
      Get.isRegistered<ViewModeController>()
          ? Get.find<ViewModeController>()
          : Get.put(ViewModeController(), permanent: true);
  final TutoringFilterController filterController =
      Get.isRegistered<TutoringFilterController>()
          ? Get.find<TutoringFilterController>()
          : Get.put(TutoringFilterController(), permanent: true);
  final applyFilterTrigger = false.obs;
  ScrollController get _scrollController => tutoringController.scrollController;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SavedTutoringsController>()) {
      Get.put(SavedTutoringsController(), permanent: true);
    }
    final bodyContent = Expanded(
      child: RefreshIndicator(
        color: Colors.white,
        backgroundColor: Colors.black,
        onRefresh: () async {
          await tutoringController.listenToTutoringData(forceRefresh: true);
          applyFilterTrigger.value = false;
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          child: Obx(() {
            if (!viewModeController.isReady.value) {
              return const SizedBox(
                height: 280,
                child: Center(child: CupertinoActivityIndicator()),
              );
            }
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

              // Sıralama
              if (filterController.selectedSort.value == 'En Yeni') {
                filteredList.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
              } else if (filterController.selectedSort.value ==
                  'En Çok Görüntülenen') {
                filteredList.sort(
                  (a, b) => (b.viewCount ?? 0).compareTo(a.viewCount ?? 0),
                );
              } else if (filterController.selectedSort.value ==
                  'Bana En Yakın') {
                final userCity =
                    (CurrentUserService.instance.currentUser?.city ?? '').trim();
                filteredList.sort((a, b) {
                  final aScore = a.sehir == userCity ? 1 : 0;
                  final bScore = b.sehir == userCity ? 1 : 0;
                  if (aScore != bScore) return bScore.compareTo(aScore);
                  return b.timeStamp.compareTo(a.timeStamp);
                });
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
                if (!embedded) ...[
                  16.ph,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        Expanded(
                          child: TurqSearchBar(
                            controller: TextEditingController(
                              text: tutoringController.searchQuery.value,
                            ),
                            hintText: 'tutoring.search_hint'.tr,
                            onTap: () => Get.to(() => const TutoringSearch()),
                          ),
                        ),
                        8.pw,
                        Obx(
                          () => AppHeaderActionButton(
                            onTap: () {
                              viewModeController.toggleView();
                            },
                            child: Icon(
                              viewModeController.isGridView.value
                                  ? AppIcons.squareGrid2
                                  : AppIcons.list,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                        8.pw,
                        Obx(
                          () => AppHeaderActionButton(
                            onTap: () {
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
                            child: Icon(
                              CupertinoIcons.arrow_up_arrow_down,
                              color: applyFilterTrigger.value
                                  ? Colors.black
                                  : Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                        8.pw,
                        Obx(
                          () => AppHeaderActionButton(
                            onTap: () {
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
                            child: Icon(
                              Icons.filter_alt_outlined,
                              color: applyFilterTrigger.value
                                  ? Colors.black
                                  : Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                16.ph,
                TutoringCategoryWidget(categories: kategoriler),
                16.ph,
                Obx(() {
                  if (tutoringController.isLoading.value) {
                    return Center(child: CupertinoActivityIndicator());
                  }
                  if (tutoringController.isSearchLoading.value) {
                    return Center(child: CupertinoActivityIndicator());
                  }
                  final content = TutoringWidgetBuilder(
                    tutoringList: filteredList,
                    users: tutoringController.users,
                    isGridView: viewModeController.isGridView.value,
                  );
                  if (viewModeController.isGridView.value) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: content,
                    );
                  }
                  return content;
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
                  title: 'common.search'.tr,
                  icon: CupertinoIcons.search,
                  onTap: () {
                    Get.to(() => const TutoringSearch());
                  },
                ),
                PullDownMenuItem(
                  title: 'tutoring.my_applications'.tr,
                  icon: CupertinoIcons.doc_text,
                  onTap: () {
                    Get.to(() => MyTutoringApplications());
                  },
                ),
                PullDownMenuItem(
                  title: 'tutoring.create_listing'.tr,
                  icon: CupertinoIcons.add_circled,
                  onTap: () {
                    Get.to(CreateTutoringView());
                  },
                ),
                PullDownMenuItem(
                  title: 'tutoring.my_listings'.tr,
                  icon: CupertinoIcons.list_bullet,
                  onTap: () {
                    Get.to(MyTutorings());
                  },
                ),
                PullDownMenuItem(
                  title: 'tutoring.saved'.tr,
                  icon: AppIcons.save,
                  onTap: () {
                    Get.to(() => SavedTutorings());
                  },
                ),
                PullDownMenuItem(
                  title: 'pasaj.tutoring.nearby_listings'.tr,
                  icon: AppIcons.locationSolid,
                  onTap: () {
                    Get.to(() => LocationBasedTutoring());
                  },
                ),
                PullDownMenuItem(
                  title: 'tutoring.slider_admin'.tr,
                  icon: CupertinoIcons.slider_horizontal_3,
                  onTap: () {
                    Get.to(
                      () => SliderAdminView(
                        sliderId: 'ozel_ders',
                        title: 'tutoring.title'.tr,
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
                        text: 'tutoring.title'.tr,
                      ),
                    ],
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
