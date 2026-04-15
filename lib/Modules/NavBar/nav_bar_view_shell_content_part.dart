part of 'nav_bar_view.dart';

extension _NavBarViewShellContentPart on NavBarView {
  Widget _buildNavBarViewContent(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleBackNavigation();
        if (shouldPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        key: const ValueKey(IntegrationTestKeys.navBarRoot),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: _handleRootHorizontalSwipe,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Column(
                children: [
                  const OfflineIndicator(),
                  Expanded(
                    child: Obx(() => _buildSelectedPage()),
                  ),
                ],
              ),
              Obx(() {
                if (controller.selectedIndex.value != 0) {
                  return const SizedBox.shrink();
                }
                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: MediaQuery.of(context).padding.top - 3,
                      color: Colors.white,
                    ),
                  ),
                );
              }),
              Obx(() {
                final showBar = controller.showBar.value;
                return _buildNavBar(context, showBar: showBar);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedPage() {
    final hasEducation = settingController.educationScreenIsOn.value;
    final selected = controller.selectedIndex.value;
    final selectedStackIndex = _stackIndexForSelected(
      selected: selected,
      hasEducation: hasEducation,
    );
    final pages = <Widget>[
      _buildIntegrationSmokeTabPage(
        stackIndex: 0,
        selectedStackIndex: selectedStackIndex,
        child: AgendaView(key: const PageStorageKey<String>('nav-agenda')),
      ),
      _buildIntegrationSmokeTabPage(
        stackIndex: 1,
        selectedStackIndex: selectedStackIndex,
        child: ExploreView(key: const PageStorageKey<String>('nav-explore')),
      ),
      if (hasEducation)
        _buildIntegrationSmokeTabPage(
          stackIndex: 2,
          selectedStackIndex: selectedStackIndex,
          child: EducationView(
            key: const PageStorageKey<String>('nav-education'),
          ),
        ),
      _buildIntegrationSmokeTabPage(
        stackIndex: hasEducation ? 3 : 2,
        selectedStackIndex: selectedStackIndex,
        child: ProfileView(key: const PageStorageKey<String>('nav-profile')),
      ),
    ];

    return IndexedStack(
      index: selectedStackIndex,
      children: pages,
    );
  }

  Widget _buildIntegrationSmokeTabPage({
    required int stackIndex,
    required int selectedStackIndex,
    required Widget child,
  }) {
    if (!IntegrationTestMode.enabled) {
      return child;
    }
    if (stackIndex == selectedStackIndex) {
      return child;
    }
    return const SizedBox.shrink();
  }

  Future<bool> _handleBackNavigation() async {
    final hasEducation = settingController.educationScreenIsOn.value;
    const feedIndex = 0;
    const exploreIndex = 1;
    final profileIndex = hasEducation ? 4 : 3;
    final educationIndex = hasEducation ? 3 : 0;

    if (controller.selectedIndex.value == exploreIndex) {
      controller.changeIndex(feedIndex);
      return false;
    }

    if (hasEducation && controller.selectedIndex.value == educationIndex) {
      final educationController = maybeFindEducationController();
      if (educationController == null) return false;
      if (educationController.canExitToFeed) {
        controller.changeIndex(feedIndex);
      } else {
        educationController.handleBackFromEducation();
      }
      return false;
    }

    if (controller.selectedIndex.value == profileIndex) {
      controller.changeIndex(educationIndex);
      return false;
    }

    return true;
  }

  void _handleRootHorizontalSwipe(DragEndDetails details) async {
    final dx = details.velocity.pixelsPerSecond.dx;
    const exploreIndex = 1;
    const shortIndex = 2;
    const feedIndex = 0;
    final selected = controller.selectedIndex.value;

    if (selected == feedIndex && dx < -700) {
      await _openShortRoute();
      return;
    }

    if (selected == exploreIndex && dx > 700) {
      controller.changeIndex(feedIndex);
      return;
    }

    if (selected == shortIndex && dx > 700) {
      controller.changeIndex(feedIndex);
    }
  }

  Future<void> _openShortRoute() async {
    final shortController = ensureShortController();
    try {
      unawaited(
        shortController.prepareStartupSurface(
          allowBackgroundRefresh: false,
        ),
      );
    } catch (_) {}
    try {
      final initialIndex = shortController.shorts.isEmpty
          ? 0
          : shortController.lastIndex.value.clamp(
              0,
              shortController.shorts.length - 1,
            );
      unawaited(shortController.ensureActiveAdapterReady(initialIndex));
    } catch (_) {}

    controller.suspendFeedForTabExit();
    controller.pauseGlobalTabMedia();
    await Get.to(() => const ShortView());
    maybeFindAgendaController()?.resetVisibleFeedSurfaceAfterShortReturn();
    controller.resumeFeedIfNeeded();
  }

  Widget _buildNavBar(
    BuildContext context, {
    required bool showBar,
  }) {
    final hasEducation = settingController.educationScreenIsOn.value;
    final icons = [
      'assets/icons/house',
      'assets/icons/search',
      'assets/icons/play',
      if (hasEducation) 'assets/icons/sinav',
      'profile_dynamic',
    ];

    return AnimatedSlide(
      offset: showBar ? Offset.zero : const Offset(0, 1.2),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: showBar ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: IgnorePointer(
          ignoring: !showBar,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              0,
              12,
              math.max(
                0.0,
                math.max(8.0, MediaQuery.of(context).viewPadding.bottom) -
                    (GetPlatform.isIOS ? 20 : 10),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    children: List.generate(
                      icons.length,
                      (i) => _buildNavButton(
                        context,
                        index: i,
                        iconPath: icons[i],
                        hasEducation: hasEducation,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required int index,
    required String iconPath,
    required bool hasEducation,
  }) {
    final isSelected = controller.selectedIndex.value == index;
    final navKey = _navKeyForIndex(
      index: index,
      hasEducation: hasEducation,
    );

    return Expanded(
      child: Center(
        child: Semantics(
          label: navKey,
          button: true,
          selected: isSelected,
          child: ExcludeFocus(
            excluding: IntegrationTestMode.enabled,
            child: TextButton(
              key: ValueKey(navKey),
              style: ButtonStyle(
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                padding: WidgetStateProperty.all(EdgeInsets.zero),
              ),
              onPressed: () => _handleNavTap(context, index: index),
              child: iconPath == 'profile_dynamic'
                  ? _buildProfileNavIcon(isSelected: isSelected)
                  : SvgPicture.asset(
                      '$iconPath${isSelected ? '_fill.svg' : '.svg'}',
                      height: index <= 1 ? 25 : 28,
                      colorFilter: ColorFilter.mode(
                        isSelected
                            ? Colors.black
                            : Colors.black.withValues(alpha: 0.5),
                        BlendMode.srcIn,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleNavTap(
    BuildContext context, {
    required int index,
  }) async {
    if (index == 0 && controller.selectedIndex.value == 0) {
      final agendaCtrl = maybeFindAgendaController();
      if (agendaCtrl != null) {
        final scrollController = agendaCtrl.scrollController;
        if (scrollController.hasClients) {
          final currentOffset = scrollController.offset;
          if (currentOffset > 8) {
            await scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOut,
            );
          } else {
            scrollController.jumpTo(0);
          }
        }
        final didShowRefresh = await AgendaView.showFeedRefreshIndicator();
        if (!didShowRefresh) {
          await agendaCtrl.refreshAgenda(
            forceNewLaunchSession: true,
          );
        }
        return;
      }
    }

    if (index == 1 && controller.selectedIndex.value == 1) {
      final explore = maybeFindExploreController();
      if (explore != null) {
        final tab = maybeFindPageLineBarController(kExplorePageLineBarTag)
                ?.selection
                .value ??
            0;
        ScrollController? sc;
        switch (tab) {
          case 0:
            sc = explore.exploreScroll;
            break;
          case 1:
            sc = explore.floodsScroll;
            break;
          case 2:
            sc = explore.videoScroll;
            break;
          case 3:
            sc = explore.photoScroll;
            break;
          default:
            sc = explore.exploreScroll;
        }
        if (sc.hasClients) {
          await sc.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
          return;
        }
      }
    }

    final profileIndex = settingController.educationScreenIsOn.value ? 4 : 3;
    if (index == profileIndex &&
        controller.selectedIndex.value == profileIndex) {
      final profile = ProfileController.maybeFind();
      if (profile != null) {
        await profile.animateCurrentSelectionToTop();
        return;
      }
    }

    if (index != 2) {
      if (index == (settingController.educationScreenIsOn.value ? 3 : 2)) {
        FocusScope.of(context).unfocus();
      }
      controller.changeIndex(index);
      return;
    }

    await _openShortRoute();
  }

  Widget _buildProfileNavIcon({required bool isSelected}) {
    return Obx(() {
      CurrentUserService.instance.currentUserRx.value;
      final userId = CurrentUserService.instance.effectiveUserId;
      final img = CurrentUserService.instance.avatarUrl;
      final uploading = controller.uploadingPosts.value;
      const size = 28.0;
      return AnimatedBuilder(
        animation: controller.animationController.value,
        builder: (_, __) {
          final angle =
              controller.animationController.value.value * 2 * math.pi * 3;
          return _AvatarWithRing(
            userId: userId,
            imageUrl: img,
            size: size,
            isSelected: isSelected,
            uploading: uploading,
            angle: angle,
          );
        },
      );
    });
  }

  String _navKeyForIndex({
    required int index,
    required bool hasEducation,
  }) {
    if (index == 0) return IntegrationTestKeys.navFeed;
    if (index == 1) return IntegrationTestKeys.navExplore;
    if (index == 2) return IntegrationTestKeys.navShort;
    if (hasEducation && index == 3) {
      return IntegrationTestKeys.navEducation;
    }
    return IntegrationTestKeys.navProfile;
  }
}
