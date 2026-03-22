part of 'education_view.dart';

extension EducationViewBodyPart on EducationView {
  Widget _buildEducationScaffold(BuildContext context) {
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenEducation),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: _buildSearchRow(context),
                ),
                _buildTabStrip(),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                Expanded(child: _buildEducationContent()),
              ],
            ),
            _buildFloatingOverlay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return Obx(() {
      final marketController = _activeMarketController();
      final showMarketActions =
          marketController != null && _showInlineMarketActions();
      final jobController = _activeJobFinderController();
      final showJobActions = jobController != null && _showInlineJobActions();
      final practiceExamController = _activePracticeExamController();
      final showPracticeExamActions =
          practiceExamController != null && _showInlinePracticeExamActions();
      final answerKeyController = _activeAnswerKeyController();
      final showAnswerKeyActions =
          answerKeyController != null && _showInlineAnswerKeyActions();
      final tutoringController = _activeTutoringController();
      final tutoringFilterController = _activeTutoringFilterController();
      final showTutoringActions = tutoringController != null &&
          tutoringFilterController != null &&
          _showInlineTutoringActions();

      return Row(
        children: [
          Expanded(
            child: TurqSearchBar(
              controller: controller.searchController,
              focusNode: controller.searchFocus,
              hintText: 'common.search'.tr,
              onTap: () {
                if (_tabIdForIndex(controller.selectedTab.value) ==
                    PasajTabIds.market) {
                  Get.to(() => const MarketSearchView());
                  return;
                }
                controller.isSearchMode.value = true;
              },
              onChanged: controller.updateSearchText,
            ),
          ),
          if (showMarketActions) ...[
            const SizedBox(width: 8),
            _marketTopActionButton(
              icon: marketController.listingSelection.value == 1
                  ? Icons.view_agenda_outlined
                  : Icons.grid_view_rounded,
              onTap: marketController.toggleListingSelection,
              semanticsLabel: IntegrationTestKeys.marketTopActionViewMode,
            ),
            const SizedBox(width: 6),
            _marketTopActionButton(
              icon: Icons.swap_vert_rounded,
              onTap: () => _openMarketSortSheet(context, marketController),
              semanticsLabel: IntegrationTestKeys.marketTopActionSort,
            ),
            const SizedBox(width: 6),
            _marketTopActionButton(
              icon: Icons.filter_alt_outlined,
              active: marketController.hasAdvancedFilters,
              semanticsLabel: IntegrationTestKeys.marketTopActionFilter,
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => MarketFilterSheet(controller: marketController),
              ),
            ),
          ],
          if (showJobActions) ...[
            const SizedBox(width: 8),
            _marketTopActionButton(
              icon: jobController.listingSelection.value == 1
                  ? Icons.view_agenda_outlined
                  : Icons.grid_view_rounded,
              onTap: jobController.toggleListingSelection,
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
              icon: practiceExamController.listingSelection.value == 1
                  ? Icons.view_agenda_outlined
                  : Icons.grid_view_rounded,
              onTap: practiceExamController.toggleListingSelection,
            ),
          ],
          if (showAnswerKeyActions) ...[
            const SizedBox(width: 8),
            _marketTopActionButton(
              icon: answerKeyController.listingSelection.value == 1
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
              onTap: _viewModeController().toggleView,
            ),
            const SizedBox(width: 6),
            _marketTopActionButton(
              icon: Icons.swap_vert_rounded,
              active: tutoringFilterController.selectedLessonPlace.value!.any(
                (value) =>
                    value == 'En Yeniler' ||
                    value == 'Fiyat: Düşükten Yükseğe' ||
                    value == 'Fiyat: Yüksekten Düşüğe',
              ),
              onTap: () =>
                  _openTutoringFilterSheet(context, tutoringController),
            ),
            const SizedBox(width: 6),
            _marketTopActionButton(
              icon: Icons.filter_alt_outlined,
              active: (tutoringFilterController
                          .selectedBranch.value?.isNotEmpty ??
                      false) ||
                  (tutoringFilterController.selectedCity.value?.isNotEmpty ??
                      false) ||
                  (tutoringFilterController
                          .selectedDistrict.value?.isNotEmpty ??
                      false) ||
                  (tutoringFilterController.selectedGender.value?.isNotEmpty ??
                      false) ||
                  tutoringFilterController
                      .selectedLessonPlace.value!.isNotEmpty ||
                  tutoringFilterController.maxPrice.value != null ||
                  tutoringFilterController.minPrice.value != null,
              onTap: () =>
                  _openTutoringFilterSheet(context, tutoringController),
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
    });
  }

  Widget _buildTabStrip() {
    return Obx(() {
      if (!controller.hasVisibleTabs && controller.pasajConfigLoaded.value) {
        return const SizedBox(height: 45);
      }

      return SizedBox(
        height: 45,
        child: SingleChildScrollView(
          controller: controller.tabScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: List.generate(controller.visibleTabIndexes.length,
                (visibleIndex) {
              final actualIndex =
                  controller.actualIndexForVisible(visibleIndex);
              final tabId = controller.titles[actualIndex];
              final isSelected = controller.selectedTab.value == actualIndex;
              return GestureDetector(
                key: ValueKey(IntegrationTestKeys.educationTab(tabId)),
                onTap: () => controller.onTabTap(visibleIndex),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    _localizedPasajTitle(tabId),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily:
                          isSelected ? 'MontserratBold' : 'MontserratMedium',
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      );
    });
  }

  Widget _buildEducationContent() {
    return Obx(() {
      if (!controller.hasVisibleTabs && controller.pasajConfigLoaded.value) {
        return Center(
          child: Text(
            'pasaj.closed'.tr,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontFamily: 'MontserratMedium',
            ),
          ),
        );
      }

      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is UserScrollNotification &&
              notification.metrics.axis == Axis.vertical) {
            controller.onVerticalScrollDirection(notification.direction);
          }
          return controller.handleEducationBoundarySwipe(notification);
        },
        child: PageView.builder(
          controller: controller.pageController,
          onPageChanged: controller.onPageChanged,
          itemCount: controller.visibleTabIndexes.length,
          itemBuilder: (context, visibleIndex) {
            final actualIndex = controller.actualIndexForVisible(visibleIndex);
            return _buildTabPage(actualIndex);
          },
        ),
      );
    });
  }

  Widget _buildTabPage(int actualIndex) {
    switch (_tabIdForIndex(actualIndex)) {
      case PasajTabIds.scholarships:
        return ScholarshipsView(
          embedded: true,
          showEmbeddedControls: false,
        );
      case PasajTabIds.market:
        final marketController = MarketController.ensure(permanent: true);
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
  }

  Widget _buildFloatingOverlay(BuildContext context) {
    return Obx(() {
      if (!controller.hasVisibleTabs) {
        return const SizedBox.shrink();
      }

      final scrollController = _activeScrollController();
      final showMenu = _showMenuByScrollOffset();
      final menuItems = _menuItemsForActiveTab(context);
      final tabBarVisible = NavBarController.maybeFind()?.showBar.value ?? true;
      final searchActive =
          controller.isKeyboardOpen.value || controller.isSearchMode.value;

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
    });
  }
}
