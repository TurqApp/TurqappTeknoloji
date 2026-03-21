import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
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
import 'package:turqappv2/Modules/Education/Antreman3/ThenSolve/then_solve.dart';
import 'package:turqappv2/Modules/Education/Antreman3/antreman_controller.dart';
import 'package:turqappv2/Modules/Education/education_controller.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';
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
import 'package:turqappv2/Modules/Education/Tutoring/FilterBottomSheet/tutoring_filter_bottom_sheet.dart';
import 'package:turqappv2/Modules/Education/Tutoring/FilterBottomSheet/tutoring_filter_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/LocationBasedTutoring/location_based_tutoring.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutorings/my_tutorings.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutoringApplications/my_tutoring_applications.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/saved_tutorings.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringSearch/tutoring_search.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/view_mode_controller.dart';
import 'package:turqappv2/Modules/Market/market_controller.dart';
import 'package:turqappv2/Modules/Market/market_create_view.dart';
import 'package:turqappv2/Modules/Market/market_filter_sheet.dart';
import 'package:turqappv2/Modules/Market/market_search_view.dart';
import 'package:turqappv2/Modules/Market/market_view.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder_controller.dart';
import 'package:turqappv2/Modules/JobFinder/JobCreator/job_creator.dart';
import 'package:turqappv2/Modules/JobFinder/CareerProfile/career_profile.dart';
import 'package:turqappv2/Modules/JobFinder/MyApplications/my_applications.dart';
import 'package:turqappv2/Modules/JobFinder/MyJobAds/my_job_ads.dart';
import 'package:turqappv2/Modules/JobFinder/SavedJobs/saved_jobs.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';

class EducationView extends StatelessWidget {
  EducationView({super.key});

  final EducationController controller = EducationController.ensure(
    permanent: true,
  );

  String _tabIdForIndex(int actualIndex) => controller.titles[actualIndex];

  String _localizedPasajTitle(String tabId) {
    final translationKey = pasajTitleTranslationKey(tabId);
    return translationKey.isNotEmpty ? translationKey.tr : tabId;
  }

  void _focusGlobalSearch() {
    controller.isSearchMode.value = true;
    controller.searchFocus.requestFocus();
  }

  MarketController? _activeMarketController() {
    if (_tabIdForIndex(controller.selectedTab.value) != PasajTabIds.market) {
      return null;
    }
    return MarketController.ensure(permanent: true);
  }

  bool _showInlineMarketActions() {
    return _activeMarketController() != null &&
        !controller.isKeyboardOpen.value &&
        !controller.isSearchMode.value;
  }

  JobFinderController? _activeJobFinderController() {
    if (_tabIdForIndex(controller.selectedTab.value) != PasajTabIds.jobFinder) {
      return null;
    }
    return JobFinderController.ensure(permanent: true);
  }

  bool _showInlineJobActions() {
    return _activeJobFinderController() != null &&
        !controller.isKeyboardOpen.value &&
        !controller.isSearchMode.value;
  }

  ViewModeController _viewModeController() {
    return ViewModeController.ensure(permanent: true);
  }

  DenemeSinavlariController? _activePracticeExamController() {
    if (_tabIdForIndex(controller.selectedTab.value) !=
        PasajTabIds.onlineExam) {
      return null;
    }
    return DenemeSinavlariController.ensure(permanent: true);
  }

  bool _showInlinePracticeExamActions() {
    return _activePracticeExamController() != null &&
        !controller.isKeyboardOpen.value &&
        !controller.isSearchMode.value;
  }

  AnswerKeyController? _activeAnswerKeyController() {
    if (_tabIdForIndex(controller.selectedTab.value) != PasajTabIds.answerKey) {
      return null;
    }
    return AnswerKeyController.ensure(permanent: true);
  }

  bool _showInlineAnswerKeyActions() {
    return _activeAnswerKeyController() != null &&
        !controller.isKeyboardOpen.value &&
        !controller.isSearchMode.value;
  }

  TutoringController? _activeTutoringController() {
    if (_tabIdForIndex(controller.selectedTab.value) != PasajTabIds.tutoring) {
      return null;
    }
    return TutoringController.ensure(permanent: true);
  }

  TutoringFilterController? _activeTutoringFilterController() {
    if (_tabIdForIndex(controller.selectedTab.value) != PasajTabIds.tutoring) {
      return null;
    }
    return TutoringFilterController.ensure(permanent: true);
  }

  bool _showInlineTutoringActions() {
    return _activeTutoringController() != null &&
        !controller.isKeyboardOpen.value &&
        !controller.isSearchMode.value;
  }

  Widget _marketTopActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
    String? semanticsLabel,
  }) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: GestureDetector(
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
      ),
    );
  }

  Future<void> _openTutoringFilterSheet(
    BuildContext context,
    TutoringController tutoringController,
  ) async {
    await Get.bottomSheet(
      TutoringFilterBottomSheet(controller: tutoringController),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
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
    switch (_tabIdForIndex(controller.selectedTab.value)) {
      case PasajTabIds.scholarships:
        return ScholarshipsController.maybeFind()?.scrollController;
      case PasajTabIds.onlineExam:
        return DenemeSinavlariController.maybeFind()?.scrollController;
      case PasajTabIds.answerKey:
        return AnswerKeyController.maybeFind()?.scrollController;
      case PasajTabIds.tutoring:
        return TutoringController.maybeFind()?.scrollController;
      case PasajTabIds.market:
        return MarketController.maybeFind()?.scrollController;
      default:
        return null;
    }
  }

  bool _showMenuByScrollOffset() {
    switch (_tabIdForIndex(controller.selectedTab.value)) {
      case PasajTabIds.scholarships:
        return (ScholarshipsController.maybeFind()?.scrollOffset.value ?? 0) <=
            350;
      case PasajTabIds.onlineExam:
        return (DenemeSinavlariController.maybeFind()?.scrollOffset.value ??
                0) <=
            350;
      case PasajTabIds.answerKey:
        return (AnswerKeyController.maybeFind()?.scrollOffset.value ?? 0) <=
            350;
      case PasajTabIds.tutoring:
        return (TutoringController.maybeFind()?.scrollOffset.value ?? 0) <= 350;
      case PasajTabIds.market:
        return (MarketController.maybeFind()?.scrollOffset.value ?? 0) <= 350;
      default:
        return true;
    }
  }

  List<PullDownMenuItem> _menuItemsForActiveTab(BuildContext context) {
    switch (_tabIdForIndex(controller.selectedTab.value)) {
      case PasajTabIds.scholarships:
        return [
          PullDownMenuItem(
            title: 'common.search'.tr,
            icon: CupertinoIcons.search,
            onTap: _focusGlobalSearch,
          ),
          PullDownMenuItem(
            title: 'settings.title'.tr,
            icon: CupertinoIcons.gear,
            onTap: () {
              ScholarshipsController.maybeFind()?.settings(context);
            },
          ),
          PullDownMenuItem(
            title: 'common.applications'.tr,
            icon: CupertinoIcons.doc_plaintext,
            onTap: () => Get.to(() => ApplicationsView()),
          ),
          PullDownMenuItem(
            title: 'scholarship.create_title'.tr,
            icon: CupertinoIcons.add_circled,
            onTap: () async {
              final allowed = await ensureCurrentUserRozetPermission(
                minimumRozet: 'sari',
                featureName: 'scholarship.create_title'.tr,
              );
              if (!allowed) return;
              Get.delete<CreateScholarshipController>(force: true);
              Get.to(CreateScholarshipView());
            },
          ),
          PullDownMenuItem(
            title: 'scholarship.my_listings'.tr,
            icon: CupertinoIcons.doc_text,
            onTap: () async {
              final allowed = await ensureCurrentUserRozetPermission(
                minimumRozet: 'sari',
                featureName: 'scholarship.my_listings'.tr,
              );
              if (!allowed) return;
              Get.to(MyScholarshipView());
            },
          ),
          PullDownMenuItem(
            title: 'common.saved'.tr,
            icon: CupertinoIcons.bookmark,
            onTap: () => Get.to(() => SavedItemsView()),
          ),
          PullDownMenuItem(
            title: 'explore.tab.for_you'.tr,
            icon: CupertinoIcons.star,
            onTap: () => Get.to(PersonalizedView()),
          ),
        ];
      case PasajTabIds.questionBank:
        return [
          PullDownMenuItem(
            title: 'education.change_main_category'.tr,
            icon: CupertinoIcons.square_grid_2x2,
            onTap: () {
              final antController = AntremanController.ensure();
              antController.openMainCategoryPicker(context, force: true);
            },
          ),
          PullDownMenuItem(
            title: 'pasaj.question_bank.solve_later'.tr,
            icon: CupertinoIcons.repeat,
            onTap: () => Get.to(() => ThenSolve()),
          ),
        ];
      case PasajTabIds.market:
        return [
          PullDownMenuItem(
            title: 'common.search'.tr,
            icon: CupertinoIcons.search,
            onTap: () => Get.to(() => const MarketSearchView()),
          ),
          PullDownMenuItem(
            title: 'pasaj.market.add_listing'.tr,
            icon: CupertinoIcons.add_circled,
            onTap: () {
              final marketController = MarketController.maybeFind();
              if (marketController != null) {
                marketController.openRoundMenu('create');
              } else {
                Get.to(() => const MarketCreateView());
              }
            },
          ),
          PullDownMenuItem(
            title: 'pasaj.market.my_listings'.tr,
            icon: CupertinoIcons.cube_box,
            onTap: () {
              MarketController.maybeFind()?.openRoundMenu('my_items');
            },
          ),
          PullDownMenuItem(
            title: 'pasaj.market.saved_items'.tr,
            icon: CupertinoIcons.hand_thumbsup,
            onTap: () {
              MarketController.maybeFind()?.openRoundMenu('saved');
            },
          ),
          PullDownMenuItem(
            title: 'pasaj.market.my_offers'.tr,
            icon: CupertinoIcons.tag,
            onTap: () {
              MarketController.maybeFind()?.openRoundMenu('offers');
            },
          ),
          PullDownMenuItem(
            title: 'pasaj.common.slider_admin'.tr,
            icon: CupertinoIcons.slider_horizontal_3,
            onTap: () => Get.to(
              () => SliderAdminView(
                sliderId: 'market',
                title: 'pasaj.tabs.market'.tr,
              ),
            ),
          ),
        ];
      case PasajTabIds.practiceExams:
        return [
          PullDownMenuItem(
            icon: Icons.history,
            title: 'pasaj.common.my_results'.tr,
            onTap: () => Get.to(() => CikmisSoruSonuclar()),
          ),
          PullDownMenuItem(
            icon: CupertinoIcons.slider_horizontal_3,
            title: 'pasaj.common.slider_admin'.tr,
            onTap: () => Get.to(
              () => SliderAdminView(
                sliderId: 'denemeler',
                title: 'pasaj.tabs.practice_exams'.tr,
              ),
            ),
          ),
        ];
      case PasajTabIds.onlineExam:
        return [
          PullDownMenuItem(
            icon: CupertinoIcons.search,
            title: 'common.search'.tr,
            onTap: () => Get.to(() => SearchDeneme()),
          ),
          PullDownMenuItem(
            icon: Icons.add,
            title: 'common.create'.tr,
            onTap: () async {
              final allowed = await ensureCurrentUserRozetPermission(
                minimumRozet: 'sari',
                featureName: 'tests.create_title'.tr,
              );
              if (!allowed) return;
              Get.to(() => SinavHazirla());
            },
          ),
          PullDownMenuItem(
            icon: CupertinoIcons.slider_horizontal_3,
            title: 'pasaj.common.slider_admin'.tr,
            onTap: () => Get.to(
              () => SliderAdminView(
                sliderId: 'online_sinav',
                title: 'pasaj.tabs.online_exam'.tr,
              ),
            ),
          ),
          PullDownMenuItem(
            icon: Icons.history,
            title: 'pasaj.common.my_results'.tr,
            onTap: () => Get.to(() => SinavSonuclarim()),
          ),
          PullDownMenuItem(
            icon: CupertinoIcons.doc_text,
            title: 'pasaj.common.published'.tr,
            onTap: () => Get.to(() => const MyPracticeExams()),
          ),
          PullDownMenuItem(
            icon: CupertinoIcons.bookmark,
            title: 'common.saved'.tr,
            onTap: () => Get.to(() => const SavedPracticeExams()),
          ),
        ];
      case PasajTabIds.answerKey:
        return [
          PullDownMenuItem(
            title: 'common.search'.tr,
            icon: CupertinoIcons.search,
            onTap: () => Get.to(() => const SearchAnswerKey()),
          ),
          PullDownMenuItem(
            title: 'common.saved'.tr,
            icon: CupertinoIcons.bookmark,
            onTap: () => Get.to(SavedOpticalForms()),
          ),
          PullDownMenuItem(
            title: 'pasaj.answer_key.join'.tr,
            icon: CupertinoIcons.arrow_right,
            onTap: () => Get.to(OpticalFormEntry()),
          ),
          PullDownMenuItem(
            title: 'common.create'.tr,
            icon: CupertinoIcons.add_circled,
            onTap: () => Get.to(AnswerKeyCreatingOption(
              onBack: () {
                AnswerKeyController.maybeFind()?.refreshData();
              },
            )),
          ),
          PullDownMenuItem(
            title: 'pasaj.common.my_results'.tr,
            icon: CupertinoIcons.chart_bar_square,
            onTap: () => Get.to(MyBookletResults()),
          ),
          PullDownMenuItem(
            title: 'pasaj.common.slider_admin'.tr,
            icon: CupertinoIcons.slider_horizontal_3,
            onTap: () => Get.to(
              () => SliderAdminView(
                sliderId: 'cevap_anahtari',
                title: 'pasaj.tabs.answer_key'.tr,
              ),
            ),
          ),
          PullDownMenuItem(
            title: 'pasaj.common.published'.tr,
            icon: CupertinoIcons.book,
            onTap: () => Get.to(OpticsAndBooksPublished()),
          ),
        ];
      case PasajTabIds.tutoring:
        return [
          PullDownMenuItem(
            title: 'common.search'.tr,
            icon: CupertinoIcons.search,
            onTap: () => Get.to(() => const TutoringSearch()),
          ),
          PullDownMenuItem(
            title: 'pasaj.common.my_applications'.tr,
            icon: CupertinoIcons.doc_text_search,
            onTap: () => Get.to(() => MyTutoringApplications()),
          ),
          PullDownMenuItem(
            title: 'pasaj.common.post_listing'.tr,
            icon: CupertinoIcons.add_circled,
            onTap: () => Get.to(CreateTutoringView()),
          ),
          PullDownMenuItem(
            title: 'pasaj.market.my_listings'.tr,
            icon: CupertinoIcons.list_bullet,
            onTap: () => Get.to(MyTutorings()),
          ),
          PullDownMenuItem(
            title: 'common.saved'.tr,
            icon: CupertinoIcons.bookmark,
            onTap: () => Get.to(() => SavedTutorings()),
          ),
          PullDownMenuItem(
            title: 'pasaj.tutoring.nearby_listings'.tr,
            icon: CupertinoIcons.location_solid,
            onTap: () => Get.to(() => LocationBasedTutoring()),
          ),
          PullDownMenuItem(
            title: 'pasaj.common.slider_admin'.tr,
            icon: CupertinoIcons.slider_horizontal_3,
            onTap: () => Get.to(
              () => SliderAdminView(
                sliderId: 'ozel_ders',
                title: 'pasaj.tabs.tutoring'.tr,
              ),
            ),
          ),
        ];
      case PasajTabIds.jobFinder:
        return [
          PullDownMenuItem(
            title: 'common.search'.tr,
            icon: CupertinoIcons.search,
            onTap: _focusGlobalSearch,
          ),
          PullDownMenuItem(
            title: 'pasaj.common.my_applications'.tr,
            icon: CupertinoIcons.doc_text_search,
            onTap: () => Get.to(() => MyApplications()),
          ),
          PullDownMenuItem(
            title: 'pasaj.common.post_listing'.tr,
            icon: CupertinoIcons.add_circled,
            onTap: () async {
              final allowed = await ensureCurrentUserRozetPermission(
                minimumRozet: 'sari',
                featureName: 'pasaj.common.post_listing'.tr,
              );
              if (!allowed) return;
              Get.to(() => JobCreator());
            },
          ),
          PullDownMenuItem(
            title: 'pasaj.market.my_listings'.tr,
            icon: CupertinoIcons.doc_text,
            onTap: () async {
              final allowed = await ensureCurrentUserRozetPermission(
                minimumRozet: 'sari',
                featureName: 'pasaj.market.my_listings'.tr,
              );
              if (!allowed) return;
              Get.to(() => MyJobAds());
            },
          ),
          PullDownMenuItem(
            title: 'pasaj.job_finder.career_profile'.tr,
            icon: CupertinoIcons.person_crop_circle,
            onTap: () => Get.to(() => CareerProfile()),
          ),
          PullDownMenuItem(
            title: 'common.saved'.tr,
            icon: CupertinoIcons.bookmark,
            onTap: () => Get.to(() => SavedJobs()),
          ),
          PullDownMenuItem(
            title: 'pasaj.common.slider_admin'.tr,
            icon: CupertinoIcons.slider_horizontal_3,
            onTap: () => Get.to(
              () => SliderAdminView(
                sliderId: 'is_bul',
                title: 'pasaj.tabs.job_finder'.tr,
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
                    final jobController = _activeJobFinderController();
                    final showJobActions =
                        jobController != null && _showInlineJobActions();
                    final practiceExamController =
                        _activePracticeExamController();
                    final showPracticeExamActions =
                        practiceExamController != null &&
                            _showInlinePracticeExamActions();
                    final answerKeyController = _activeAnswerKeyController();
                    final showAnswerKeyActions = answerKeyController != null &&
                        _showInlineAnswerKeyActions();
                    final tutoringController = _activeTutoringController();
                    final tutoringFilterController =
                        _activeTutoringFilterController();
                    final showTutoringActions = tutoringController != null &&
                        tutoringFilterController != null &&
                        _showInlineTutoringActions();
                    return Row(
                      children: [
                        Expanded(
                          child: TurqSearchBar(
                            controller: controller.searchController,
                            focusNode: controller.searchFocus,
                            hintText: "common.search".tr,
                            onTap: () {
                              if (_tabIdForIndex(
                                      controller.selectedTab.value) ==
                                  PasajTabIds.market) {
                                Get.to(() => const MarketSearchView());
                                return;
                              }
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
                                ? Icons.view_agenda_outlined
                                : Icons.grid_view_rounded,
                            onTap: marketController.toggleListingSelection,
                            semanticsLabel:
                                IntegrationTestKeys.marketTopActionViewMode,
                          ),
                          const SizedBox(width: 6),
                          _marketTopActionButton(
                            icon: Icons.swap_vert_rounded,
                            onTap: () =>
                                _openMarketSortSheet(context, marketController),
                            semanticsLabel:
                                IntegrationTestKeys.marketTopActionSort,
                          ),
                          const SizedBox(width: 6),
                          _marketTopActionButton(
                            icon: Icons.filter_alt_outlined,
                            active: marketController.hasAdvancedFilters,
                            semanticsLabel:
                                IntegrationTestKeys.marketTopActionFilter,
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
                        if (showJobActions) ...[
                          const SizedBox(width: 8),
                          _marketTopActionButton(
                            icon: jobController.listingSelection.value == 1
                                ? Icons.view_agenda_outlined
                                : Icons.grid_view_rounded,
                            onTap: () {
                              jobController.toggleListingSelection();
                            },
                          ),
                          const SizedBox(width: 6),
                          _marketTopActionButton(
                            icon: Icons.swap_vert_rounded,
                            active: jobController.short.value != 0,
                            onTap: jobController.siralaTapped,
                          ),
                          const SizedBox(width: 6),
                          _marketTopActionButton(
                            icon: Icons.filter_alt_outlined,
                            active: jobController.filtre.value,
                            onTap: jobController.filtreTapped,
                          ),
                        ],
                        if (showPracticeExamActions) ...[
                          const SizedBox(width: 8),
                          _marketTopActionButton(
                            icon:
                                practiceExamController.listingSelection.value ==
                                        1
                                    ? Icons.view_agenda_outlined
                                    : Icons.grid_view_rounded,
                            onTap:
                                practiceExamController.toggleListingSelection,
                          ),
                        ],
                        if (showAnswerKeyActions) ...[
                          const SizedBox(width: 8),
                          _marketTopActionButton(
                            icon:
                                answerKeyController.listingSelection.value == 1
                                    ? Icons.view_agenda_outlined
                                    : Icons.grid_view_rounded,
                            onTap: answerKeyController.toggleListingSelection,
                          ),
                        ],
                        if (showTutoringActions) ...[
                          const SizedBox(width: 8),
                          _marketTopActionButton(
                            icon: _viewModeController().isGridView.value
                                ? Icons.view_agenda_outlined
                                : Icons.grid_view_rounded,
                            onTap: () {
                              _viewModeController().toggleView();
                            },
                          ),
                          const SizedBox(width: 6),
                          _marketTopActionButton(
                            icon: Icons.swap_vert_rounded,
                            active: tutoringFilterController
                                .selectedLessonPlace.value!
                                .any(
                              (value) =>
                                  value == 'En Yeniler' ||
                                  value == 'Fiyat: Düşükten Yükseğe' ||
                                  value == 'Fiyat: Yüksekten Düşüğe',
                            ),
                            onTap: () => _openTutoringFilterSheet(
                                context, tutoringController),
                          ),
                          const SizedBox(width: 6),
                          _marketTopActionButton(
                            icon: Icons.filter_alt_outlined,
                            active:
                                (tutoringFilterController.selectedBranch.value?.isNotEmpty ?? false) ||
                                    (tutoringFilterController
                                            .selectedCity.value?.isNotEmpty ??
                                        false) ||
                                    (tutoringFilterController
                                            .selectedDistrict.value?.isNotEmpty ??
                                        false) ||
                                    (tutoringFilterController
                                            .selectedGender.value?.isNotEmpty ??
                                        false) ||
                                    tutoringFilterController.selectedLessonPlace
                                        .value!.isNotEmpty ||
                                    tutoringFilterController.maxPrice.value !=
                                        null ||
                                    tutoringFilterController.minPrice.value !=
                                        null,
                            onTap: () => _openTutoringFilterSheet(
                                context, tutoringController),
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
                                _localizedPasajTitle(
                                  controller.titles[actualIndex],
                                ),
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
                      return Center(
                        child: Text(
                          "pasaj.closed".tr,
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
                          switch (_tabIdForIndex(actualIndex)) {
                            case PasajTabIds.scholarships:
                              return ScholarshipsView(
                                embedded: true,
                                showEmbeddedControls: false,
                              );
                            case PasajTabIds.market:
                              final marketController =
                                  MarketController.ensure(permanent: true);
                              return MarketView(
                                embedded: true,
                                showEmbeddedControls: false,
                                controller: marketController,
                              );
                            case PasajTabIds.questionBank:
                              return AntremanView2(
                                embedded: true,
                                showEmbeddedControls: false,
                              );
                            case PasajTabIds.practiceExams:
                              return CikmisSorular(
                                embedded: true,
                                showEmbeddedControls: false,
                              );
                            case PasajTabIds.onlineExam:
                              return DenemeSinavlari(
                                embedded: true,
                                showEmbeddedControls: false,
                              );
                            case PasajTabIds.answerKey:
                              return AnswerKey(
                                embedded: true,
                                showEmbeddedControls: false,
                              );
                            case PasajTabIds.tutoring:
                              return TutoringView(
                                embedded: true,
                                showEmbeddedControls: false,
                              );
                            case PasajTabIds.jobFinder:
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
              final tabBarVisible =
                  NavBarController.maybeFind()?.showBar.value ?? true;
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
                        semanticsLabel: IntegrationTestKeys.educationActionMenu(
                          _tabIdForIndex(controller.selectedTab.value),
                        ),
                        size: 56,
                        lift: 62,
                        backgroundColor: Colors.green,
                        iconColor: Colors.white,
                        permissionScope: switch (
                            _tabIdForIndex(controller.selectedTab.value)) {
                          PasajTabIds.scholarships =>
                            ActionButtonPermissionScope.scholarships,
                          PasajTabIds.onlineExam =>
                            ActionButtonPermissionScope.practiceExams,
                          PasajTabIds.jobFinder =>
                            ActionButtonPermissionScope.jobFinder,
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
