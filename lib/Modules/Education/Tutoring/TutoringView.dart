import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/ActionButton.dart';
import 'package:turqappv2/Core/Buttons/ScrollToTopButton.dart';
import 'package:turqappv2/Core/Functions.dart';
import 'package:turqappv2/Core/Slider/EducationSlider.dart';
import 'package:turqappv2/Core/TextStyles.dart';
import 'package:turqappv2/Models/Education/TutoringModel.dart';
import 'package:turqappv2/Modules/Education/Tutoring/CreateTutoring/CreateTutoringView.dart';
import 'package:turqappv2/Modules/Education/Tutoring/FilterBottomSheet/TutoringFilterBottomSheet.dart';
import 'package:turqappv2/Modules/Education/Tutoring/FilterBottomSheet/TutoringFilterController.dart';
import 'package:turqappv2/Modules/Education/Tutoring/LocationBasedTutoring/LocationBasedTutoring.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutorings/MyTutorings.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/SavedTutoringsController.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringCategory.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringController.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringSearch/TutoringSearch.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringWidgetBuilder.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/SavedTutorings.dart';
import 'package:turqappv2/Modules/Education/Tutoring/ViewModeController.dart.dart';
import 'package:turqappv2/Modules/TypeWriter/TypeWriter.dart';
import 'package:turqappv2/Themes/AppAssets.dart';
import 'package:turqappv2/Themes/AppIcons.dart';
import 'package:turqappv2/Utils/EmptyPadding.dart';

class TutoringView extends StatelessWidget {
  TutoringView({super.key});

  final TutoringController tutoringController = Get.put(TutoringController());
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    Get.put(SavedTutoringsController());
    final ViewModeController viewModeController = Get.put(ViewModeController());
    final TutoringFilterController filterController = Get.put(
      TutoringFilterController(),
    );

    var applyFilterTrigger = false.obs;
    _scrollController.addListener(() {
      tutoringController.scrollOffset.value = _scrollController.offset;
    });
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
              Expanded(
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
                          tutoringController.tutoringList.toList();

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
                        if (filterController.selectedLessonPlace.value !=
                                null &&
                            filterController
                                .selectedLessonPlace.value!.isNotEmpty) {
                          filteredList = filteredList
                              .where(
                                (tutoring) => filterController
                                    .selectedLessonPlace.value!
                                    .any(
                                  (place) => tutoring.dersYeri.contains(place),
                                ),
                              )
                              .toList();
                        }
                        if (filterController.maxPrice.value != null) {
                          filteredList = filteredList
                              .where(
                                (tutoring) =>
                                    tutoring.fiyat <=
                                    filterController.maxPrice.value!,
                              )
                              .toList();
                        }
                        if (filterController.minPrice.value != null) {
                          filteredList = filteredList
                              .where(
                                (tutoring) =>
                                    tutoring.fiyat >=
                                    filterController.minPrice.value!,
                              )
                              .toList();
                        }
                        if (filterController.selectedCity.value != null &&
                            filterController.selectedCity.value!.isNotEmpty) {
                          filteredList = filteredList
                              .where(
                                (tutoring) =>
                                    tutoring.sehir ==
                                    filterController.selectedCity.value,
                              )
                              .toList();
                        }
                        if (filterController.selectedDistrict.value != null &&
                            filterController
                                .selectedDistrict.value!.isNotEmpty) {
                          filteredList = filteredList
                              .where(
                                (tutoring) =>
                                    tutoring.ilce ==
                                    filterController.selectedDistrict.value,
                              )
                              .toList();
                        }

                        // Sıralama ölçütü
                        if (filterController.selectedLessonPlace.value!
                            .contains(
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
                            imageList: [
                              AppAssets.tutoring1,
                              AppAssets.tutoring2,
                              AppAssets.tutoring3,
                            ],
                          ),
                          16.ph,
                          TutoringCategoryWidget(categories: kategoriler),
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
                          16.ph,
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Sana Özel",
                                    style: TextStyles.bold18Black),
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
                              return Center(
                                  child: CupertinoActivityIndicator());
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
                        ],
                      );
                    }),
                  ),
                ),
              ),
              15.ph,
            ],
          ),
          ScrollTotopButton(
            scrollController: _scrollController,
            visibilityThreshold: 350,
          ),
          // ActionButton
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
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
