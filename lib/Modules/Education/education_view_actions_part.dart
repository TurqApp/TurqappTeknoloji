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
    return MarketController.ensure(permanent: true);
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
    return ScholarshipsController.ensure(permanent: true);
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
        return ScholarshipsController.maybeFind()?.scrollController;
      case PasajTabIds.practiceExams:
        return CikmisSorularController.maybeFind()?.scrollController;
      case PasajTabIds.onlineExam:
        return DenemeSinavlariController.maybeFind()?.scrollController;
      case PasajTabIds.answerKey:
        return AnswerKeyController.maybeFind()?.scrollController;
      case PasajTabIds.tutoring:
        return maybeFindTutoringController()?.scrollController;
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
      case PasajTabIds.practiceExams:
        return (CikmisSorularController.maybeFind()?.scrollOffset.value ?? 0) <=
            350;
      case PasajTabIds.onlineExam:
        return (DenemeSinavlariController.maybeFind()?.scrollOffset.value ??
                0) <=
            350;
      case PasajTabIds.answerKey:
        return (AnswerKeyController.maybeFind()?.scrollOffset.value ?? 0) <=
            350;
      case PasajTabIds.tutoring:
        return (maybeFindTutoringController()?.scrollOffset.value ?? 0) <= 350;
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
}
