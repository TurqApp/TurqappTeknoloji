import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import 'package:turqappv2/Modules/InAppNotifications/in_app_notifications_controller.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/following_followers_controller.dart';
import 'package:turqappv2/Modules/Profile/LikedPosts/liked_posts_controller.dart';
import 'package:turqappv2/Modules/Profile/SavedPosts/saved_posts_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/SocialProfileFollowers/social_profile_followers_controller.dart';
import 'package:turqappv2/Themes/app_fonts.dart';

part 'page_line_bar_controller_part.dart';
part 'page_line_bar_controller_fields_part.dart';
part 'page_line_bar_controller_support_part.dart';

const String kExplorePageLineBarTag = 'explore_page_line_bar';
const String kSavedPostsPageLineBarTag = 'saved_posts_page_line_bar';
const String kLikedPostsPageLineBarTag = 'liked_posts_page_line_bar';
const String kNotificationsPageLineBarTag = 'notifications_page_line_bar';
const String kDeletedStoriesPageLineBarTag = 'deleted_stories_page_line_bar';
const String kFollowersPageLineBarTag = 'followers_page_line_bar';
const String kFollowersSocialProfilePageLineBarTag =
    'followers_social_profile_page_line_bar';

PageLineBarController? maybeFindPageLineBarController(String tag) {
  final isRegistered = Get.isRegistered<PageLineBarController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<PageLineBarController>(tag: tag);
}

void syncPageLineBarSelection(String tag, int index) {
  maybeFindPageLineBarController(tag)?.selection.value = index;
}

class PageLineBar extends StatefulWidget {
  final List<String> barList;
  final String pageName;
  final int initialIndex;
  final double fontSize;
  final bool isScrollable;
  final EdgeInsetsGeometry scrollablePadding;
  final double scrollableTabHorizontalPadding;
  final PageController? pageController; // optional: direct control of PageView

  const PageLineBar({
    super.key,
    required this.barList,
    required this.pageName,
    this.initialIndex = 0,
    this.fontSize = 15,
    this.isScrollable = false,
    this.scrollablePadding = EdgeInsets.zero,
    this.scrollableTabHorizontalPadding = 14,
    this.pageController,
  });

  @override
  State<PageLineBar> createState() => _PageLineBarState();
}

class _PageLineBarState extends State<PageLineBar> {
  late PageLineBarController controller;
  final ScrollController _scrollController = ScrollController();
  late List<GlobalKey> _tabKeys;
  bool _didInit = false;
  bool _ownsController = false;
  int? _lastRevealedIndex;

  void _syncExternalPageController(
    int index, {
    required bool animate,
  }) {
    final pageController = widget.pageController;
    if (pageController == null) {
      controller.setSelectionTo(index);
      return;
    }

    void syncAfterFrame() {
      if (!mounted) return;
      if (!pageController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) => syncAfterFrame());
        return;
      }
      if (animate) {
        pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        pageController.jumpToPage(index);
      }
    }

    syncAfterFrame();
  }

  @override
  void initState() {
    super.initState();
    _tabKeys = List<GlobalKey>.generate(
      widget.barList.length,
      (_) => GlobalKey(),
    );
    _ownsController = maybeFindPageLineBarController(widget.pageName) == null;
    controller = ensurePageLineBarController(
      pageName: widget.pageName,
      tag: widget.pageName,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_didInit) return;
      _didInit = true;
      if (widget.initialIndex != controller.selection.value) {
        controller.selection.value = widget.initialIndex;
        _syncExternalPageController(
          widget.initialIndex,
          animate: false,
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant PageLineBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.barList.length != widget.barList.length) {
      _tabKeys = List<GlobalKey>.generate(
        widget.barList.length,
        (_) => GlobalKey(),
      );
      _lastRevealedIndex = null;
    }
  }

  void _scheduleSelectedTabReveal(int index) {
    if (!widget.isScrollable || _lastRevealedIndex == index) return;
    _lastRevealedIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index < 0 || index >= _tabKeys.length) return;
      final targetContext = _tabKeys[index].currentContext;
      if (targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (_ownsController &&
        maybeFindPageLineBarController(widget.pageName) == controller) {
      Get.delete<PageLineBarController>(
        tag: widget.pageName,
        force: true,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final selectedIndex = controller.selection.value;
        _scheduleSelectedTabReveal(selectedIndex);
        final items = List.generate(
          widget.barList.length,
          (index) => _buildTabItem(index, scrollable: widget.isScrollable),
        );
        if (widget.isScrollable) {
          return SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: widget.scrollablePadding,
              child: Row(children: items),
            ),
          );
        }
        return Row(children: items);
      },
    );
  }

  Widget _buildTabItem(
    int index, {
    required bool scrollable,
  }) {
    final item = widget.barList[index];
    final content = KeyedSubtree(
      key: _tabKeys[index],
      child: GestureDetector(
        key: ValueKey(
          IntegrationTestKeys.pageLineBarItem(widget.pageName, index),
        ),
        onTap: () {
          controller.selection.value = index;
          _syncExternalPageController(index, animate: true);
        },
        child: Container(
          height: 40,
          color: Colors.white,
          padding: scrollable
              ? EdgeInsets.symmetric(
                  horizontal: widget.scrollableTabHorizontalPadding,
                )
              : null,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: scrollable
                      ? Text(
                          item,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: widget.fontSize,
                            fontFamily: controller.selection.value == index
                                ? AppFontFamilies.mbold
                                : AppFontFamilies.mmedium,
                          ),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: widget.fontSize,
                              fontFamily: controller.selection.value == index
                                  ? AppFontFamilies.mbold
                                  : AppFontFamilies.mmedium,
                            ),
                          ),
                        ),
                ),
              ),
              if (controller.selection.value == index)
                Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (scrollable) {
      return content;
    }
    return Expanded(child: content);
  }
}
