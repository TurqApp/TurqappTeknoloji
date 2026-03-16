import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Core/Slider/slider_admin_view.dart';
import 'package:turqappv2/Core/Widgets/turq_search_bar.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyCreatingOption/answer_key_creating_option.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/MyBookletResults/my_booklet_results.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticalFormEntry/optical_form_entry.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticsAndBooksPublished/optics_and_books_published.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/SavedOpticalForms/saved_optical_forms.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/SearchAnswerKey/search_answer_key.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/answer_key_controller.dart';
import 'package:turqappv2/Modules/Education/Antreman3/AntremanScore/antreman_score.dart';
import 'package:turqappv2/Modules/Education/Antreman3/ThenSolve/then_solve.dart';
import 'package:turqappv2/Modules/Education/Antreman3/antreman_controller.dart';
import 'package:turqappv2/Modules/Education/education_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/MyScholarship/my_scholarship_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/Personalized/personalized_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/SavedItems/saved_items_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/Applications/applications_view.dart';
import 'package:turqappv2/Modules/Education/Antreman3/antreman_view.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/deneme_sinavlari.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/MyPracticeExams/my_practice_exams.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SearchDeneme/search_deneme.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavHazirla/sinav_hazirla.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavSonuclarim/sinav_sonuclarim.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/deneme_sinavlari_controller.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_soru_sonuclar.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/answer_key.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_view.dart';
import 'package:turqappv2/Modules/Education/Tutoring/CreateTutoring/create_tutoring_view.dart';
import 'package:turqappv2/Modules/Education/Tutoring/LocationBasedTutoring/location_based_tutoring.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutorings/my_tutorings.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/saved_tutorings.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringSearch/tutoring_search.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Modules/Market/market_controller.dart';
import 'package:turqappv2/Modules/Market/market_create_view.dart';
import 'package:turqappv2/Modules/Market/market_filter_sheet.dart';
import 'package:turqappv2/Modules/Market/market_search_view.dart';
import 'package:turqappv2/Modules/Market/market_view.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder.dart';
import 'package:turqappv2/Modules/JobFinder/JobCreator/job_creator.dart';
import 'package:turqappv2/Modules/JobFinder/CareerProfile/career_profile.dart';
import 'package:turqappv2/Modules/JobFinder/MyApplications/my_applications.dart';
import 'package:turqappv2/Modules/JobFinder/MyJobAds/my_job_ads.dart';
import 'package:turqappv2/Modules/JobFinder/SavedJobs/saved_jobs.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';

class EducationView extends StatelessWidget {
  EducationView({super.key});

  final EducationController controller = Get.put(EducationController());

  String _titleForIndex(int actualIndex) => controller.titles[actualIndex];

  void _focusGlobalSearch() {
    controller.isSearchMode.value = true;
    controller.searchFocus.requestFocus();
  }

  MarketController? _activeMarketController() {
    if (_titleForIndex(controller.selectedTab.value) != "Market") return null;
    if (!Get.isRegistered<MarketController>()) {
      Get.put(MarketController());
    }
    return Get.find<MarketController>();
  }

  bool _showInlineMarketActions() {
    return _activeMarketController() != null &&
        !controller.isKeyboardOpen.value &&
        !controller.isSearchMode.value;
  }

  Widget _marketTopActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? Colors.pink.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? Colors.pink.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 19,
          color: active ? Colors.pink : Colors.black,
        ),
      ),
    );
  }

  Future<void> _openMarketSortSheet(
    BuildContext context,
    MarketController marketController,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sırala',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMarketSortOption(
                    context,
                    marketController,
                    'En Yeni',
                    'newest',
                  ),
                  _buildMarketSortOption(
                    context,
                    marketController,
                    'Fiyat Artan',
                    'price_asc',
                  ),
                  _buildMarketSortOption(
                    context,
                    marketController,
                    'Fiyat Azalan',
                    'price_desc',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarketSortOption(
    BuildContext context,
    MarketController marketController,
    String label,
    String value,
  ) {
    final selected = marketController.sortSelection.value == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontFamily: selected ? 'MontserratBold' : 'MontserratMedium',
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: Colors.black)
          : null,
      onTap: () {
        marketController.applyAdvancedFilters(
          city: marketController.selectedCityFilter.value,
          contactPreference: marketController.selectedContactFilter.value,
          minPrice: marketController.minPriceFilter.value,
          maxPrice: marketController.maxPriceFilter.value,
          sortBy: value,
        );
        Navigator.of(context).pop();
      },
    );
  }

  ScrollController? _activeScrollController() {
    switch (_titleForIndex(controller.selectedTab.value)) {
      case "Burslar":
        return Get.isRegistered<ScholarshipsController>()
            ? Get.find<ScholarshipsController>().scrollController
            : null;
      case "Online Sınav":
        return Get.isRegistered<DenemeSinavlariController>()
            ? Get.find<DenemeSinavlariController>().scrollController
            : null;
      case "Cevap Anahtarı":
        return Get.isRegistered<AnswerKeyController>()
            ? Get.find<AnswerKeyController>().scrollController
            : null;
      case "Özel Ders":
        return Get.isRegistered<TutoringController>()
            ? Get.find<TutoringController>().scrollController
            : null;
      case "Market":
        return Get.isRegistered<MarketController>()
            ? Get.find<MarketController>().scrollController
            : null;
      default:
        return null;
    }
  }

  bool _showMenuByScrollOffset() {
    switch (_titleForIndex(controller.selectedTab.value)) {
      case "Burslar":
        return Get.isRegistered<ScholarshipsController>()
            ? Get.find<ScholarshipsController>().scrollOffset.value <= 350
            : true;
      case "Online Sınav":
        return Get.isRegistered<DenemeSinavlariController>()
            ? Get.find<DenemeSinavlariController>().scrollOffset.value <= 350
            : true;
      case "Cevap Anahtarı":
        return Get.isRegistered<AnswerKeyController>()
            ? Get.find<AnswerKeyController>().scrollOffset.value <= 350
            : true;
      case "Özel Ders":
        return Get.isRegistered<TutoringController>()
            ? Get.find<TutoringController>().scrollOffset.value <= 350
            : true;
      case "Market":
        return Get.isRegistered<MarketController>()
            ? Get.find<MarketController>().scrollOffset.value <= 350
            : true;
      default:
        return true;
    }
  }

  List<PullDownMenuItem> _menuItemsForActiveTab(BuildContext context) {
    switch (_titleForIndex(controller.selectedTab.value)) {
      case "Burslar":
        return [
          PullDownMenuItem(
            title: 'Ara',
            icon: CupertinoIcons.search,
            onTap: _focusGlobalSearch,
          ),
          PullDownMenuItem(
            title: 'Ayarlar',
            icon: CupertinoIcons.gear,
            onTap: () {
              if (Get.isRegistered<ScholarshipsController>()) {
                Get.find<ScholarshipsController>().settings(context);
              }
            },
          ),
          PullDownMenuItem(
            title: 'Başvurular',
            icon: CupertinoIcons.doc_plaintext,
            onTap: () => Get.to(() => ApplicationsView()),
          ),
          PullDownMenuItem(
            title: 'Burs Oluştur',
            icon: CupertinoIcons.add_circled,
            onTap: () async {
              final allowed = await ensureCurrentUserRozetPermission(
                minimumRozet: 'Sarı',
                featureName: 'Burs oluşturma',
              );
              if (!allowed) return;
              Get.delete<CreateScholarshipController>(force: true);
              Get.to(CreateScholarshipView());
            },
          ),
          PullDownMenuItem(
            title: 'İlanlarım',
            icon: CupertinoIcons.doc_text,
            onTap: () async {
              final allowed = await ensureCurrentUserRozetPermission(
                minimumRozet: 'Sarı',
                featureName: 'Burs ilanları',
              );
              if (!allowed) return;
              Get.to(MyScholarshipView());
            },
          ),
          PullDownMenuItem(
            title: 'Kaydedilenler',
            icon: CupertinoIcons.bookmark,
            onTap: () => Get.to(() => SavedItemsView()),
          ),
          PullDownMenuItem(
            title: 'Sana Özel',
            icon: CupertinoIcons.star,
            onTap: () => Get.to(PersonalizedView()),
          ),
        ];
      case "Soru Bankası":
        return [
          PullDownMenuItem(
            title: 'Ana Kategori Değiştir',
            icon: CupertinoIcons.square_grid_2x2,
            onTap: () {
              final antController = Get.isRegistered<AntremanController>()
                  ? Get.find<AntremanController>()
                  : Get.put(AntremanController());
              antController.openMainCategoryPicker(context, force: true);
            },
          ),
          PullDownMenuItem(
            title: 'Puan Tablosu',
            icon: CupertinoIcons.chart_bar_fill,
            onTap: () => Get.to(() => AntremanScore()),
          ),
          PullDownMenuItem(
            title: 'Sonra Çöz',
            icon: CupertinoIcons.repeat,
            onTap: () => Get.to(() => ThenSolve()),
          ),
        ];
      case "Market":
        return [
          PullDownMenuItem(
            title: 'Ara',
            icon: CupertinoIcons.search,
            onTap: () => Get.to(() => const MarketSearchView()),
          ),
          PullDownMenuItem(
            title: 'İlan Ekle',
            icon: CupertinoIcons.add_circled,
            onTap: () {
              if (Get.isRegistered<MarketController>()) {
                Get.find<MarketController>().openRoundMenu('create');
              } else {
                Get.to(() => const MarketCreateView());
              }
            },
          ),
          PullDownMenuItem(
            title: 'İlanlarım',
            icon: CupertinoIcons.cube_box,
            onTap: () {
              if (Get.isRegistered<MarketController>()) {
                Get.find<MarketController>().openRoundMenu('my_items');
              }
            },
          ),
          PullDownMenuItem(
            title: 'Beğendiklerim',
            icon: CupertinoIcons.bookmark,
            onTap: () {
              if (Get.isRegistered<MarketController>()) {
                Get.find<MarketController>().openRoundMenu('saved');
              }
            },
          ),
          PullDownMenuItem(
            title: 'Tekliflerim',
            icon: CupertinoIcons.tag,
            onTap: () {
              if (Get.isRegistered<MarketController>()) {
                Get.find<MarketController>().openRoundMenu('offers');
              }
            },
          ),
          PullDownMenuItem(
            title: 'Slider Yönetimi',
            icon: CupertinoIcons.slider_horizontal_3,
            onTap: () => Get.to(
              () => const SliderAdminView(
                sliderId: 'market',
                title: 'Market',
              ),
            ),
          ),
        ];
      case "Denemeler":
        return [
          PullDownMenuItem(
            icon: Icons.history,
            title: 'Sonuçlarım',
            onTap: () => Get.to(() => CikmisSoruSonuclar()),
          ),
          PullDownMenuItem(
            icon: CupertinoIcons.slider_horizontal_3,
            title: 'Slider Yönetimi',
            onTap: () => Get.to(
              () => const SliderAdminView(
                sliderId: 'denemeler',
                title: 'Denemeler',
              ),
            ),
          ),
        ];
      case "Online Sınav":
        return [
          PullDownMenuItem(
            icon: CupertinoIcons.search,
            title: 'Ara',
            onTap: () => Get.to(() => SearchDeneme()),
          ),
          PullDownMenuItem(
            icon: Icons.add,
            title: 'Oluştur',
            onTap: () async {
              final allowed = await ensureCurrentUserRozetPermission(
                minimumRozet: 'Sarı',
                featureName: 'Online sınav oluşturma',
              );
              if (!allowed) return;
              Get.to(() => SinavHazirla());
            },
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
        ];
      case "Cevap Anahtarı":
        return [
          PullDownMenuItem(
            title: 'Ara',
            icon: CupertinoIcons.search,
            onTap: () => Get.to(() => const SearchAnswerKey()),
          ),
          PullDownMenuItem(
            title: 'Kaydedilenler',
            icon: CupertinoIcons.bookmark,
            onTap: () => Get.to(SavedOpticalForms()),
          ),
          PullDownMenuItem(
            title: 'Katıl',
            icon: CupertinoIcons.arrow_right,
            onTap: () => Get.to(OpticalFormEntry()),
          ),
          PullDownMenuItem(
            title: 'Oluştur',
            icon: CupertinoIcons.add_circled,
            onTap: () => Get.to(AnswerKeyCreatingOption(
              onBack: () {
                if (Get.isRegistered<AnswerKeyController>()) {
                  Get.find<AnswerKeyController>().refreshData();
                }
              },
            )),
          ),
          PullDownMenuItem(
            title: 'Sonuçlarım',
            icon: CupertinoIcons.chart_bar_square,
            onTap: () => Get.to(MyBookletResults()),
          ),
          PullDownMenuItem(
            title: 'Slider Yönetimi',
            icon: CupertinoIcons.slider_horizontal_3,
            onTap: () => Get.to(
              () => const SliderAdminView(
                sliderId: 'cevap_anahtari',
                title: 'Cevap Anahtarı',
              ),
            ),
          ),
          PullDownMenuItem(
            title: 'Yayınladıklarım',
            icon: CupertinoIcons.book,
            onTap: () => Get.to(OpticsAndBooksPublished()),
          ),
        ];
      case "Özel Ders":
        return [
          PullDownMenuItem(
            title: 'Ara',
            icon: CupertinoIcons.search,
            onTap: () => Get.to(() => const TutoringSearch()),
          ),
          PullDownMenuItem(
            title: 'Bölgemdeki İlanlar',
            icon: CupertinoIcons.location_solid,
            onTap: () => Get.to(() => LocationBasedTutoring()),
          ),
          PullDownMenuItem(
            title: 'Kaydedilenler',
            icon: CupertinoIcons.bookmark,
            onTap: () => Get.to(() => SavedTutorings()),
          ),
          PullDownMenuItem(
            title: 'Oluştur',
            icon: CupertinoIcons.add_circled,
            onTap: () => Get.to(CreateTutoringView()),
          ),
          PullDownMenuItem(
            title: 'Özel Ders İlanlarım',
            icon: CupertinoIcons.list_bullet,
            onTap: () => Get.to(MyTutorings()),
          ),
          PullDownMenuItem(
            title: 'Slider Yönetimi',
            icon: CupertinoIcons.slider_horizontal_3,
            onTap: () => Get.to(
              () => const SliderAdminView(
                sliderId: 'ozel_ders',
                title: 'Özel Ders',
              ),
            ),
          ),
        ];
      case "İş Bul":
        return [
          PullDownMenuItem(
            title: 'Ara',
            icon: CupertinoIcons.search,
            onTap: _focusGlobalSearch,
          ),
          PullDownMenuItem(
            title: 'Başvurularım',
            icon: CupertinoIcons.doc_text_search,
            onTap: () => Get.to(() => MyApplications()),
          ),
          PullDownMenuItem(
            title: 'İlan Ver',
            icon: CupertinoIcons.add_circled,
            onTap: () async {
              final allowed = await ensureCurrentUserRozetPermission(
                minimumRozet: 'Sarı',
                featureName: 'İş ilanı verme',
              );
              if (!allowed) return;
              Get.to(() => JobCreator());
            },
          ),
          PullDownMenuItem(
            title: 'İlanlarım',
            icon: CupertinoIcons.doc_text,
            onTap: () async {
              final allowed = await ensureCurrentUserRozetPermission(
                minimumRozet: 'Sarı',
                featureName: 'İş ilanları',
              );
              if (!allowed) return;
              Get.to(() => MyJobAds());
            },
          ),
          PullDownMenuItem(
            title: 'Kariyer Profili',
            icon: CupertinoIcons.person_crop_circle,
            onTap: () => Get.to(() => CareerProfile()),
          ),
          PullDownMenuItem(
            title: 'Kaydedilenler',
            icon: CupertinoIcons.bookmark,
            onTap: () => Get.to(() => SavedJobs()),
          ),
          PullDownMenuItem(
            title: 'Slider Yönetimi',
            icon: CupertinoIcons.slider_horizontal_3,
            onTap: () => Get.to(
              () => const SliderAdminView(
                sliderId: 'is_bul',
                title: 'İş Bul',
              ),
            ),
          ),
        ];
      default:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // ——— Arama Çubuğu ———
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Obx(() {
                    final marketController = _activeMarketController();
                    final showMarketActions =
                        marketController != null && _showInlineMarketActions();
                    return Row(
                      children: [
                        Expanded(
                          child: TurqSearchBar(
                            controller: controller.searchController,
                            focusNode: controller.searchFocus,
                            hintText: "Ara",
                            onTap: () {
                              controller.isSearchMode.value = true;
                            },
                            onChanged: (v) {
                              controller.updateSearchText(v);
                            },
                          ),
                        ),
                        if (showMarketActions) ...[
                          const SizedBox(width: 8),
                          _marketTopActionButton(
                            icon: marketController.listingSelection.value == 1
                                ? Icons.grid_view_rounded
                                : Icons.view_agenda_outlined,
                            onTap: marketController.toggleListingSelection,
                          ),
                          const SizedBox(width: 6),
                          _marketTopActionButton(
                            icon: Icons.swap_vert_rounded,
                            onTap: () =>
                                _openMarketSortSheet(context, marketController),
                          ),
                          const SizedBox(width: 6),
                          _marketTopActionButton(
                            icon: Icons.filter_alt_outlined,
                            active: marketController.hasAdvancedFilters,
                            onTap: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (_) => MarketFilterSheet(
                                controller: marketController,
                              ),
                            ),
                          ),
                        ],
                        if (controller.isKeyboardOpen.value)
                          GestureDetector(
                            onTap: () => controller.clearSearch(context),
                            child: const Padding(
                              padding: EdgeInsets.only(left: 15),
                              child: Icon(
                                CupertinoIcons.xmark,
                                color: Colors.black,
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                ),

                // ——— Yatay Kaydırılabilir Tab ———
                Obx(() {
                  if (!controller.hasVisibleTabs &&
                      controller.pasajConfigLoaded.value) {
                    return const SizedBox(height: 45);
                  }
                  return SizedBox(
                    height: 45,
                    child: SingleChildScrollView(
                      controller: controller.tabScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        children:
                            List.generate(controller.visibleTabIndexes.length,
                                (visibleIndex) {
                          final actualIndex =
                              controller.actualIndexForVisible(visibleIndex);
                          final isSelected =
                              controller.selectedTab.value == actualIndex;
                          return GestureDetector(
                            onTap: () => controller.onTabTap(visibleIndex),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                controller.titles[actualIndex],
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontFamily: isSelected
                                      ? "MontserratBold"
                                      : "MontserratMedium",
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                }),

                const Divider(height: 1, color: Color(0xFFE0E0E0)),

                // ——— PageView ile Gömülü Modül ———
                Expanded(
                  child: Obx(() {
                    if (!controller.hasVisibleTabs &&
                        controller.pasajConfigLoaded.value) {
                      return const Center(
                        child: Text(
                          "Pasaj şu anda kapalı",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      );
                    }

                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is UserScrollNotification &&
                            notification.metrics.axis == Axis.vertical) {
                          controller.onVerticalScrollDirection(
                            notification.direction,
                          );
                        }
                        return controller.handleEducationBoundarySwipe(
                          notification,
                        );
                      },
                      child: PageView.builder(
                        controller: controller.pageController,
                        onPageChanged: controller.onPageChanged,
                        itemCount: controller.visibleTabIndexes.length,
                        itemBuilder: (context, visibleIndex) {
                          final actualIndex =
                              controller.actualIndexForVisible(visibleIndex);
                          switch (_titleForIndex(actualIndex)) {
                            case "Burslar":
                              return ScholarshipsView(
                                embedded: true,
                                showEmbeddedControls: false,
                              );
                            case "Market":
                              return MarketView(
                                embedded: true,
                                showEmbeddedControls: false,
                              );
                            case "Soru Bankası":
                              return AntremanView2(
                                embedded: true,
                                showEmbeddedControls: false,
                              );
                            case "Denemeler":
                              return CikmisSorular(
                                embedded: true,
                                showEmbeddedControls: false,
                              );
                            case "Online Sınav":
                              return DenemeSinavlari(
                                embedded: true,
                                showEmbeddedControls: false,
                              );
                            case "Cevap Anahtarı":
                              return AnswerKey(
                                embedded: true,
                                showEmbeddedControls: false,
                              );
                            case "Özel Ders":
                              return TutoringView(
                                embedded: true,
                                showEmbeddedControls: false,
                              );
                            case "İş Bul":
                              return JobFinder(
                                embedded: true,
                                showEmbeddedControls: false,
                              );
                            default:
                              return const SizedBox.shrink();
                          }
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
            Obx(() {
              if (!controller.hasVisibleTabs) {
                return const SizedBox.shrink();
              }
              final scrollController = _activeScrollController();
              final showMenu = _showMenuByScrollOffset();
              final menuItems = _menuItemsForActiveTab(context);
              final tabBarVisible = Get.isRegistered<NavBarController>()
                  ? Get.find<NavBarController>().showBar.value
                  : true;
              final searchActive = controller.isKeyboardOpen.value ||
                  controller.isSearchMode.value;

              return Stack(
                children: [
                  if (scrollController != null)
                    ScrollTotopButton(
                      scrollController: scrollController,
                      visibilityThreshold: 350,
                    ),
                  if (showMenu && tabBarVisible && !searchActive)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: ActionButton(
                        context: context,
                        menuItems: menuItems,
                        permissionScope: switch (
                            _titleForIndex(controller.selectedTab.value)) {
                          "Burslar" => ActionButtonPermissionScope.scholarships,
                          "Online Sınav" =>
                            ActionButtonPermissionScope.practiceExams,
                          "İş Bul" => ActionButtonPermissionScope.jobFinder,
                          _ => ActionButtonPermissionScope.none,
                        },
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
