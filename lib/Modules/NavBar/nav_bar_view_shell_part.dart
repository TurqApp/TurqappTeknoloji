part of 'nav_bar_view.dart';

extension _NavBarViewShellPart on NavBarView {
  Widget _buildSelectedPage() {
    final hasEducation = settingController.educationScreenIsOn.value;
    final selected = controller.selectedIndex.value;
    final pages = <Widget>[
      AgendaView(key: const PageStorageKey<String>('nav-agenda')),
      ExploreView(key: const PageStorageKey<String>('nav-explore')),
      if (hasEducation)
        EducationView(key: const PageStorageKey<String>('nav-education')),
      ProfileView(key: const PageStorageKey<String>('nav-profile')),
    ];

    return IndexedStack(
      index: _stackIndexForSelected(
        selected: selected,
        hasEducation: hasEducation,
      ),
      children: pages,
    );
  }

  Future<bool> _handleBackNavigation() async {
    final hasEducation = settingController.educationScreenIsOn.value;
    final profileIndex = hasEducation ? 4 : 3;
    final educationIndex = hasEducation ? 3 : 0;

    if (hasEducation && controller.selectedIndex.value == educationIndex) {
      final educationController = EducationController.maybeFind();
      if (educationController == null) return false;
      if (educationController.canExitToFeed) {
        controller.changeIndex(0);
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

  void _handleRootHorizontalSwipe(DragEndDetails details) {
    final dx = details.velocity.pixelsPerSecond.dx;
    const shortIndex = 2;
    const feedIndex = 0;
    final selected = controller.selectedIndex.value;

    if (selected == feedIndex && dx < -700) {
      controller.changeIndex(shortIndex);
      return;
    }

    if (selected == shortIndex && dx > 700) {
      controller.changeIndex(feedIndex);
    }
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
    );
  }

  Future<void> _handleNavTap(
    BuildContext context, {
    required int index,
  }) async {
    if (index == 0 && controller.selectedIndex.value == 0) {
      final agendaCtrl = maybeFindAgendaController();
      if (agendaCtrl != null && agendaCtrl.scrollController.hasClients) {
        await agendaCtrl.scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
        return;
      }
    }

    if (index == 1 && controller.selectedIndex.value == 1) {
      final explore = ExploreController.maybeFind();
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

    final shortController = ShortController.ensure();
    if (shortController.shorts.isEmpty) {
      shortController.backgroundPreload().catchError((_) {});
    }

    controller.suspendFeedForTabExit();
    controller.pauseGlobalTabMedia();
    await Get.to(() => const ShortView());
    controller.resumeFeedIfNeeded();
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
