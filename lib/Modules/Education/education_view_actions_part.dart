part of 'education_view.dart';

extension EducationViewActionsPart on EducationView {
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
    return ensureMarketController(permanent: true);
  }

  bool _showInlineMarketActions() {
    return _activeMarketController() != null &&
        !controller.isKeyboardOpen.value &&
        !controller.isSearchMode.value;
  }

  ScholarshipsController? _activeScholarshipsController() {
    if (_tabIdForIndex(controller.selectedTab.value) !=
        PasajTabIds.scholarships) {
      return null;
    }
    return ensureScholarshipsController(permanent: true);
  }

  bool _showInlineScholarshipActions() {
    return _activeScholarshipsController() != null &&
        !controller.isKeyboardOpen.value &&
        !controller.isSearchMode.value;
  }

  JobFinderController? _activeJobFinderController() {
    if (_tabIdForIndex(controller.selectedTab.value) != PasajTabIds.jobFinder) {
      return null;
    }
    return ensureJobFinderController(permanent: true);
  }

  bool _showInlineJobActions() {
    return _activeJobFinderController() != null &&
        !controller.isKeyboardOpen.value &&
        !controller.isSearchMode.value;
  }

  ViewModeController _viewModeController() {
    return ensureViewModeController(permanent: true);
  }

  DenemeSinavlariController? _activePracticeExamController() {
    if (_tabIdForIndex(controller.selectedTab.value) !=
        PasajTabIds.onlineExam) {
      return null;
    }
    return ensureDenemeSinavlariController(permanent: true);
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
    return ensureAnswerKeyController(permanent: true);
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
    return ensureTutoringController(permanent: true);
  }

  TutoringFilterController? _activeTutoringFilterController() {
    if (_tabIdForIndex(controller.selectedTab.value) != PasajTabIds.tutoring) {
      return null;
    }
    return ensureTutoringFilterController(permanent: true);
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
    return MarketTopActionButton(
      icon: icon,
      onTap: onTap,
      active: active,
      semanticsLabel: semanticsLabel,
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
        return maybeFindScholarshipsController()?.scrollController;
      case PasajTabIds.practiceExams:
        return maybeFindCikmisSorularController()?.scrollController;
      case PasajTabIds.onlineExam:
        return maybeFindDenemeSinavlariController()?.scrollController;
      case PasajTabIds.answerKey:
        return maybeFindAnswerKeyController()?.scrollController;
      case PasajTabIds.tutoring:
        return maybeFindTutoringController()?.scrollController;
      case PasajTabIds.market:
        return maybeFindMarketController()?.scrollController;
      default:
        return null;
    }
  }

  bool _showMenuByScrollOffset() {
    switch (_tabIdForIndex(controller.selectedTab.value)) {
      case PasajTabIds.scholarships:
        return (maybeFindScholarshipsController()?.scrollOffset.value ?? 0) <=
            350;
      case PasajTabIds.practiceExams:
        return (maybeFindCikmisSorularController()?.scrollOffset.value ?? 0) <=
            350;
      case PasajTabIds.onlineExam:
        return (maybeFindDenemeSinavlariController()?.scrollOffset.value ??
                0) <=
            350;
      case PasajTabIds.answerKey:
        return (maybeFindAnswerKeyController()?.scrollOffset.value ?? 0) <= 350;
      case PasajTabIds.tutoring:
        return (maybeFindTutoringController()?.scrollOffset.value ?? 0) <= 350;
      case PasajTabIds.market:
        return (maybeFindMarketController()?.scrollOffset.value ?? 0) <= 350;
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
              maybeFindScholarshipsController()?.settings(context);
            },
          ),
          PullDownMenuItem(
            title: 'common.applications'.tr,
            icon: CupertinoIcons.doc_plaintext,
            onTap: ScholarshipNavigationService.openApplications,
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
              await ScholarshipNavigationService.openCreate(
                resetController: true,
              );
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
              await ScholarshipNavigationService.openMyScholarships();
            },
          ),
          PullDownMenuItem(
            title: 'common.saved'.tr,
            icon: CupertinoIcons.bookmark,
            onTap: ScholarshipNavigationService.openSavedItems,
          ),
          PullDownMenuItem(
            title: 'explore.tab.for_you'.tr,
            icon: CupertinoIcons.star,
            onTap: ScholarshipNavigationService.openPersonalized,
          ),
        ];
      case PasajTabIds.questionBank:
        return [
          PullDownMenuItem(
            title: 'education.change_main_category'.tr,
            icon: CupertinoIcons.square_grid_2x2,
            onTap: () {
              final antController = ensureAntremanController();
              antController.openMainCategoryPicker(context, force: true);
            },
          ),
          PullDownMenuItem(
            title: 'pasaj.question_bank.solve_later'.tr,
            icon: CupertinoIcons.repeat,
            onTap: () =>
                const EducationQuestionBankNavigationService().openThenSolve(),
          ),
        ];
      case PasajTabIds.market:
        return [
          PullDownMenuItem(
            title: 'common.search'.tr,
            icon: CupertinoIcons.search,
            onTap: () =>
                const MarketDetailNavigationService().openMarketSearch(),
          ),
          PullDownMenuItem(
            title: 'pasaj.market.add_listing'.tr,
            icon: CupertinoIcons.add_circled,
            onTap: () {
              final marketController = maybeFindMarketController();
              if (marketController != null) {
                marketController.openRoundMenu('create');
              } else {
                const MarketDetailNavigationService().openMarketCreate();
              }
            },
          ),
          PullDownMenuItem(
            title: 'pasaj.market.my_listings'.tr,
            icon: CupertinoIcons.cube_box,
            onTap: () {
              maybeFindMarketController()?.openRoundMenu('my_items');
            },
          ),
          PullDownMenuItem(
            title: 'pasaj.market.saved_items'.tr,
            icon: CupertinoIcons.hand_thumbsup,
            onTap: () {
              maybeFindMarketController()?.openRoundMenu('saved');
            },
          ),
          PullDownMenuItem(
            title: 'pasaj.market.my_offers'.tr,
            icon: CupertinoIcons.tag,
            onTap: () {
              maybeFindMarketController()?.openRoundMenu('offers');
            },
          ),
          PullDownMenuItem(
            title: 'pasaj.common.slider_admin'.tr,
            icon: CupertinoIcons.slider_horizontal_3,
            onTap: () => const SliderAdminNavigationService().openSliderAdmin(
              sliderId: 'market',
              title: 'pasaj.tabs.market'.tr,
            ),
          ),
        ];
      case PasajTabIds.practiceExams:
        return [
          PullDownMenuItem(
            icon: Icons.history,
            title: 'pasaj.common.my_results'.tr,
            onTap: () => const EducationQuestionBankNavigationService()
                .openPastQuestionResults(),
          ),
          PullDownMenuItem(
            icon: CupertinoIcons.slider_horizontal_3,
            title: 'pasaj.common.slider_admin'.tr,
            onTap: () => const SliderAdminNavigationService().openSliderAdmin(
              sliderId: 'denemeler',
              title: 'pasaj.tabs.practice_exams'.tr,
            ),
          ),
        ];
      case PasajTabIds.onlineExam:
        return [
          PullDownMenuItem(
            icon: CupertinoIcons.search,
            title: 'common.search'.tr,
            onTap: () =>
                const PracticeExamNavigationService().openSearchPracticeExams(),
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
              const PracticeExamNavigationService().openCreatePracticeExam();
            },
          ),
          PullDownMenuItem(
            icon: CupertinoIcons.slider_horizontal_3,
            title: 'pasaj.common.slider_admin'.tr,
            onTap: () => const SliderAdminNavigationService().openSliderAdmin(
              sliderId: 'online_sinav',
              title: 'pasaj.tabs.online_exam'.tr,
            ),
          ),
          PullDownMenuItem(
            icon: Icons.history,
            title: 'pasaj.common.my_results'.tr,
            onTap: () => const PracticeExamNavigationService()
                .openMyPracticeExamResults(),
          ),
          PullDownMenuItem(
            icon: CupertinoIcons.doc_text,
            title: 'pasaj.common.published'.tr,
            onTap: () =>
                const PracticeExamNavigationService().openMyPracticeExams(),
          ),
          PullDownMenuItem(
            icon: CupertinoIcons.bookmark,
            title: 'common.saved'.tr,
            onTap: () =>
                const PracticeExamNavigationService().openSavedPracticeExams(),
          ),
        ];
      case PasajTabIds.answerKey:
        return [
          PullDownMenuItem(
            title: 'common.search'.tr,
            icon: CupertinoIcons.search,
            onTap: () =>
                const AnswerKeyNavigationService().openSearchAnswerKey(),
          ),
          PullDownMenuItem(
            title: 'common.saved'.tr,
            icon: CupertinoIcons.bookmark,
            onTap: () =>
                const AnswerKeyNavigationService().openSavedOpticalForms(),
          ),
          PullDownMenuItem(
            title: 'pasaj.answer_key.join'.tr,
            icon: CupertinoIcons.arrow_right,
            onTap: () =>
                const AnswerKeyNavigationService().openOpticalFormEntry(),
          ),
          PullDownMenuItem(
            title: 'common.create'.tr,
            icon: CupertinoIcons.add_circled,
            onTap: () => const AnswerKeyNavigationService().openCreateAnswerKey(
                onBack: () {
              maybeFindAnswerKeyController()?.refreshData();
            }),
          ),
          PullDownMenuItem(
            title: 'pasaj.common.my_results'.tr,
            icon: CupertinoIcons.chart_bar_square,
            onTap: () =>
                const AnswerKeyNavigationService().openMyBookletResults(),
          ),
          PullDownMenuItem(
            title: 'pasaj.common.slider_admin'.tr,
            icon: CupertinoIcons.slider_horizontal_3,
            onTap: () => const SliderAdminNavigationService().openSliderAdmin(
              sliderId: 'cevap_anahtari',
              title: 'pasaj.tabs.answer_key'.tr,
            ),
          ),
          PullDownMenuItem(
            title: 'pasaj.common.published'.tr,
            icon: CupertinoIcons.book,
            onTap: () =>
                const AnswerKeyNavigationService().openPublishedAnswerKeys(),
          ),
        ];
      case PasajTabIds.tutoring:
        return [
          PullDownMenuItem(
            title: 'common.search'.tr,
            icon: CupertinoIcons.search,
            onTap: () =>
                const EducationDetailNavigationService().openTutoringSearch(),
          ),
          PullDownMenuItem(
            title: 'pasaj.common.my_applications'.tr,
            icon: CupertinoIcons.doc_text_search,
            onTap: () => const EducationDetailNavigationService()
                .openMyTutoringApplications(),
          ),
          PullDownMenuItem(
            title: 'pasaj.common.post_listing'.tr,
            icon: CupertinoIcons.add_circled,
            onTap: () =>
                const EducationDetailNavigationService().openCreateTutoring(),
          ),
          PullDownMenuItem(
            title: 'pasaj.market.my_listings'.tr,
            icon: CupertinoIcons.list_bullet,
            onTap: () =>
                const EducationDetailNavigationService().openMyTutorings(),
          ),
          PullDownMenuItem(
            title: 'common.saved'.tr,
            icon: CupertinoIcons.bookmark,
            onTap: () =>
                const EducationDetailNavigationService().openSavedTutorings(),
          ),
          PullDownMenuItem(
            title: 'pasaj.tutoring.nearby_listings'.tr,
            icon: CupertinoIcons.location_solid,
            onTap: () => const EducationDetailNavigationService()
                .openLocationBasedTutoring(),
          ),
          PullDownMenuItem(
            title: 'pasaj.common.slider_admin'.tr,
            icon: CupertinoIcons.slider_horizontal_3,
            onTap: () => const SliderAdminNavigationService().openSliderAdmin(
              sliderId: 'ozel_ders',
              title: 'pasaj.tabs.tutoring'.tr,
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
            onTap: () => const EducationDetailNavigationService()
                .openMyJobApplications(),
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
              await const EducationDetailNavigationService().openJobCreator();
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
              await const EducationDetailNavigationService().openMyJobAds();
            },
          ),
          PullDownMenuItem(
            title: 'pasaj.job_finder.career_profile'.tr,
            icon: CupertinoIcons.person_crop_circle,
            onTap: () =>
                const EducationDetailNavigationService().openCareerProfile(),
          ),
          PullDownMenuItem(
            title: 'common.saved'.tr,
            icon: CupertinoIcons.bookmark,
            onTap: () =>
                const EducationDetailNavigationService().openSavedJobs(),
          ),
          PullDownMenuItem(
            title: 'pasaj.common.slider_admin'.tr,
            icon: CupertinoIcons.slider_horizontal_3,
            onTap: () => const SliderAdminNavigationService().openSliderAdmin(
              sliderId: 'is_bul',
              title: 'pasaj.tabs.job_finder'.tr,
            ),
          ),
        ];
      default:
        return const [];
    }
  }
}
