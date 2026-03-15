import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../Models/posts_model.dart';
import 'package:turqappv2/Core/Helpers/GlobalLoader/global_loader.dart';
import 'package:turqappv2/Modules/Agenda/ClassicContent/classic_content.dart';
import 'package:turqappv2/Modules/PostCreator/post_creator.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import '../../Themes/app_fonts.dart';
import '../../Themes/app_colors.dart';
import '../../Core/Helpers/GlobalLoader/global_loader_controller.dart';
import '../../Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import '../../Core/Widgets/app_icon_surface.dart';
import '../../Core/Widgets/Ads/ad_placement_hooks.dart';
import '../Chat/ChatListing/chat_listing.dart';
import '../InAppNotifications/in_app_notifications.dart';
import '../InAppNotifications/in_app_notifications_controller.dart';
import '../RecommendedUserList/recommended_user_list.dart';
import '../RecommendedUserList/recommended_user_list_controller.dart';
import '../Story/StoryRow/story_row_controller.dart';
import 'AgendaContent/agenda_content.dart';

class AgendaView extends StatelessWidget {
  AgendaView({super.key});
  static bool _androidVisibilityTuned = false;

  AgendaController get controller {
    if (Get.isRegistered<AgendaController>()) {
      return Get.find<AgendaController>();
    } else {
      return Get.put(AgendaController());
    }
  }

  GlobalLoaderController get loader {
    if (Get.isRegistered<GlobalLoaderController>()) {
      return Get.find<GlobalLoaderController>();
    }
    return Get.put(GlobalLoaderController(), permanent: true);
  }

  // ⚠️ CRITICAL FIX: Safe lazy loading for UnreadMessagesController
  UnreadMessagesController get unreadController {
    if (Get.isRegistered<UnreadMessagesController>()) {
      return Get.find<UnreadMessagesController>();
    } else {
      return Get.put(UnreadMessagesController());
    }
  }

  RecommendedUserListController get recommendedController {
    if (Get.isRegistered<RecommendedUserListController>()) {
      return Get.find<RecommendedUserListController>();
    } else {
      return Get.put(RecommendedUserListController());
    }
  }

  InAppNotificationsController get notificationsController {
    if (Get.isRegistered<InAppNotificationsController>()) {
      return Get.find<InAppNotificationsController>();
    } else {
      return Get.put(InAppNotificationsController());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (GetPlatform.isAndroid && !_androidVisibilityTuned) {
      // Feed'de fazla sık visibility callback'i scroll sırasında jank üretebiliyor.
      VisibilityDetectorController.instance.updateInterval =
          const Duration(milliseconds: 120);
      _androidVisibilityTuned = true;
    }

    // Feed açıldığında unread listener kesin aktif olsun (idempotent guard var)
    unreadController.startListeners();
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: topInset + 7,
              color: Colors.white,
            ),
          ),
          SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    backgroundColor: Colors.black,
                    color: Colors.white,
                    onRefresh: () async {
                      await controller.refreshAgenda();
                      try {
                        await unreadController.refreshUnreadCount();
                      } catch (e) {
                        print("Unread messages refresh error: $e");
                      }
                      try {
                        final storyController = Get.find<StoryRowController>();
                        await storyController.loadStories();
                      } catch (e) {
                        print("Story refresh error: $e");
                      }
                      try {
                        await recommendedController.getUsers();
                      } catch (_) {}
                    },
                    child: Obx(() {
                      final _ = controller.mergedFeedEntries.length;
                      final __ = controller.filteredFeedEntries.length;
                      controller.feedViewMode.value;
                      final List<Map<String, dynamic>> display =
                          controller.mergedFeedEntries.toList(growable: false);
                      List<Map<String, dynamic>> filteredDisplay =
                          controller.filteredFeedEntries.toList(growable: false);

                      final bool shouldFallbackToForYou =
                          display.isNotEmpty &&
                          filteredDisplay.isEmpty &&
                          !controller.isLoading.value &&
                          (controller.isFollowingMode || controller.isCityMode);
                      if (shouldFallbackToForYou) {
                        filteredDisplay = display;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!Get.isRegistered<AgendaController>()) return;
                          final agendaController = Get.find<AgendaController>();
                          if (agendaController.feedViewMode.value !=
                              FeedViewMode.forYou) {
                            agendaController.setFeedViewMode(FeedViewMode.forYou);
                          }
                        });
                      }

                      if (display.isEmpty) {
                        unawaited(controller.ensureInitialFeedLoaded());
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              header(),
                              const SizedBox(height: 18),
                              _feedLoadingSkeleton(context),
                              _feedLoadingSkeleton(context),
                              _feedLoadingSkeleton(context),
                              const SizedBox(height: 70),
                            ],
                          ),
                        );
                      }

                      if (filteredDisplay.isEmpty) {
                        final emptyText = controller.isCityMode
                            ? "Şehrinde henüz gönderi yok"
                            : "Takip ettiklerinden henüz gönderi yok";
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              header(),
                              const SizedBox(height: 32),
                              const Icon(
                                CupertinoIcons.person_2_fill,
                                color: Colors.black26,
                                size: 34,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                emptyText,
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                  fontFamily: AppFontFamilies.mmedium,
                                ),
                              ),
                              const SizedBox(height: 220),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: controller.scrollController,
                        physics: GetPlatform.isAndroid
                            ? const ClampingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              )
                            : const AlwaysScrollableScrollPhysics(),
                        cacheExtent: GetPlatform.isIOS ? 180.0 : 220.0,
                        padding: EdgeInsets.only(
                          bottom: kBottomNavigationBarHeight + 16,
                        ),
                        itemCount: filteredDisplay.length + 2,
                        itemBuilder: (context, index) {
                          if (index == 0) return header();
                          if (index == 1) {
                            return FeedAdPlacementHook(index: 1);
                          }

                          final actualIndex = index - 2;

                          if (actualIndex >= filteredDisplay.length) {
                            if (controller.hasMore.value) {
                              if (!controller.isLoading.value) {
                                controller.fetchAgendaBigData();
                              }
                            }
                            return const SizedBox.shrink();
                          }

                          final item = filteredDisplay[actualIndex];
                          final model = item['model'] as PostsModel;
                          final isReshare = (item['reshare'] == true);
                          final reshareUserID =
                              item['reshareUserID'] as String?;
                          final agendaIndex =
                              (item['agendaIndex'] ?? -1) as int;

                          final List<Widget> columnChildren = [];
                          Widget postWidget;
                          // Stabil key için sadece gerekli bilgiyi kullan
                          final String stableKeyString = isReshare
                              ? "${model.docID}_reshare_$reshareUserID"
                              : "${model.docID}_original";

                          // centeredIndex'i her post için ayrı Obx ile dinle
                          // Video olmayan postlar centeredIndex'i dinlemesin:
                          // Android'de gereksiz global rebuild/jank'ı azaltır.
                          Widget buildPostContent() {
                            if (!model.hasPlayableVideo) {
                              return Obx(() {
                                final viewSelection = CurrentUserService
                                    .instance.effectiveViewSelection;
                                if (viewSelection == 1) {
                                  return AgendaContent(
                                    key: ValueKey(stableKeyString),
                                    model: model,
                                    isPreview: false,
                                    shouldPlay: false,
                                    isYenidenPaylasilanPost: isReshare,
                                    reshareUserID: reshareUserID,
                                  );
                                } else {
                                  return ClassicContent(
                                    key: ValueKey(stableKeyString),
                                    model: model,
                                    isPreview: false,
                                    shouldPlay: false,
                                    isYenidenPaylasilanPost: isReshare,
                                    reshareUserID: reshareUserID,
                                  );
                                }
                              });
                            }

                            return Obx(() {
                              final isCentered =
                                  controller.centeredIndex.value == agendaIndex;
                              final viewSelection = CurrentUserService
                                  .instance.effectiveViewSelection;
                              if (viewSelection == 1) {
                                return AgendaContent(
                                  key: ValueKey(stableKeyString),
                                  model: model,
                                  isPreview: false,
                                  shouldPlay: isCentered,
                                  isYenidenPaylasilanPost: isReshare,
                                  reshareUserID: reshareUserID,
                                );
                              } else {
                                return ClassicContent(
                                  key: ValueKey(stableKeyString),
                                  model: model,
                                  isPreview: false,
                                  shouldPlay: isCentered,
                                  isYenidenPaylasilanPost: isReshare,
                                  reshareUserID: reshareUserID,
                                );
                              }
                            });
                          }

                          postWidget = VisibilityDetector(
                            key: Key('visibility_$stableKeyString'),
                            onVisibilityChanged: (info) {
                              if (model.hasPlayableVideo) return;
                              final modelIndex = agendaIndex;
                              if (modelIndex < 0) return;
                              controller.onPostVisibilityChanged(
                                modelIndex,
                                info.visibleFraction,
                              );
                            },
                            child: buildPostContent(),
                          );

                          final basePostWidget = postWidget;
                          postWidget = Obx(() {
                            final isHighlighted =
                                controller.highlightDocIDs.contains(model.docID);
                            if (!isHighlighted) {
                              return basePostWidget;
                            }

                            return TweenAnimationBuilder<double>(
                              key: ValueKey('hl-${model.docID}'),
                              tween: Tween(begin: 1.0, end: 0.0),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              builder: (context, t, child) {
                                final dy = -12.0 * t;
                                return Stack(
                                  children: [
                                    Transform.translate(
                                      offset: Offset(0, dy),
                                      child: child!,
                                    ),
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                AppColors.textBlue.withValues(
                                                    alpha: 0.10 * t),
                                                AppColors.textPink.withValues(
                                                    alpha: 0.10 * t),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                              child: basePostWidget,
                            );
                          });

                          columnChildren.add(postWidget);

                          columnChildren.add(
                            Divider(
                              color: Colors.grey.withAlpha(20),
                              height: 3,
                            ),
                          );

                          // Her 5 gönderiden sonra: önerilen kişiler + altına reklam
                          if ((actualIndex + 1) % 5 == 0) {
                            final slot = ((actualIndex + 1) ~/ 5);
                            columnChildren.add(
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 2, bottom: 10),
                                child: RecommendedUserList(
                                  key: ValueKey('recommendedUserList-$slot'),
                                  batch: slot,
                                ),
                              ),
                            );
                            columnChildren.add(
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: AdmobKare(
                                  key: ValueKey('agenda-ad-$slot'),
                                ),
                              ),
                            );
                          }

                          // RepaintBoundary ile her postu izole et - scroll sırasında
                          // sadece görünür postların repaint'ini sağlar
                          return RepaintBoundary(
                            child: Padding(
                              key: ValueKey('row-$stableKeyString'),
                              padding: const EdgeInsets.only(bottom: 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: columnChildren,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            if (controller.showFAB.value) {
              return Positioned(
                bottom: 82,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    final prevIndex = controller.lastCenteredIndex;
                    controller.centeredIndex.value = -1;
                    Get.to(() => PostCreator())?.then((_) {
                      controller.centeredIndex.value = prevIndex ?? 0;
                    });
                  },
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 16,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          CupertinoIcons.add,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          }),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlobalLoader(),
          ),
        ],
      ),
    );
  }

  Widget header({bool lightweight = false}) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: 15,
            right: 10,
            top: Get.mediaQuery.padding.top + 3,
            bottom: 8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Obx(() {
                final title = controller.feedTitle;
                final isDefaultTitle = !controller.isFollowingMode;
                final fontSize = isDefaultTitle
                    ? (GetPlatform.isAndroid ? 31.0 : 27.0)
                    : (GetPlatform.isAndroid ? 24.0 : 21.0);

                return PopupMenuButton<FeedViewMode>(
                  tooltip: '',
                  padding: EdgeInsets.zero,
                  position: PopupMenuPosition.under,
                  color: Colors.white,
                  elevation: 10,
                  offset: const Offset(0, 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: controller.setFeedViewMode,
                  itemBuilder: (context) => [
                    const PopupMenuItem<FeedViewMode>(
                      value: FeedViewMode.forYou,
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.sparkles, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Sana Özel',
                            style: TextStyle(
                              fontFamily: AppFontFamilies.mmedium,
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem<FeedViewMode>(
                      value: FeedViewMode.following,
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.person_2, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Takip Ettiklerin',
                            style: TextStyle(
                              fontFamily: AppFontFamilies.mmedium,
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem<FeedViewMode>(
                      value: FeedViewMode.city,
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.location_solid, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Şehrim',
                            style: TextStyle(
                              fontFamily: AppFontFamilies.mmedium,
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            AppColors.primaryColor,
                            AppColors.secondColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontFamily: AppFontFamilies.mbold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              AppColors.primaryColor,
                              AppColors.secondColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(
                            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Spacer(),
              Obx(() {
                final userService = CurrentUserService.instance;
                final currentSelection = userService.viewSelectionRx.value;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    final nextSelection = currentSelection == 1 ? 0 : 1;
                    await userService.updateFields({
                      "viewSelection": nextSelection,
                    });
                  },
                  child: const AppIconSurface(
                    child: Icon(
                      CupertinoIcons.rectangle_grid_1x2,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                );
              }),
              const SizedBox(width: AppIconSurface.kGap),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final unreadChatIds = notificationsController.list
                      .where((n) => n.postType == "Chat" && !n.isRead)
                      .map((n) => n.docID)
                      .toList(growable: false);
                  if (unreadChatIds.isNotEmpty) {
                    await notificationsController.markManyAsRead(unreadChatIds);
                  }
                  final prevIndex = controller.lastCenteredIndex;
                  controller.centeredIndex.value = -1;
                  Get.to(() => ChatListing())?.then((_) {
                    controller.centeredIndex.value = prevIndex ?? 0;
                    try {
                      recommendedController.getUsers();
                    } catch (_) {}
                  });
                },
                child: AppIconSurface(
                  child: Obx(() {
                    final conversationUnreadCount =
                        unreadController.totalUnreadCount.value;
                    final hasUnread = conversationUnreadCount > 0;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          CupertinoIcons.mail,
                          color: Colors.black,
                          size: AppIconSurface.kIconSize,
                        ),
                        if (hasUnread)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C853),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(width: AppIconSurface.kGap),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  final prevIndex = controller.lastCenteredIndex;
                  controller.centeredIndex.value = -1;
                  Get.to(() => InAppNotifications())?.then((_) {
                    controller.centeredIndex.value = prevIndex ?? 0;
                    try {
                      recommendedController.getUsers();
                    } catch (_) {}
                  });
                },
                child: AppIconSurface(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        CupertinoIcons.bell,
                        color: Colors.black,
                        size: AppIconSurface.kIconSize,
                      ),
                      Obx(() {
                        final hasUnread =
                            notificationsController.unreadCount > 0;
                        if (!hasUnread) {
                          return const SizedBox.shrink();
                        }
                        return Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              // 12.pw,
              // GestureDetector(
              //   onTap: () {
              //     Get.to(() => TestFirebase());
              //   },
              //   child: Icon(CupertinoIcons.settings),
              // )
            ],
          ),
        ),
        StoryRow(),
        5.ph,
      ],
    );
  }

  Widget _feedLoadingSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFECECEC),
                  borderRadius: BorderRadius.circular(19),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 110,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9E9E9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 72,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: MediaQuery.of(context).size.width * 0.62,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 360,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ],
      ),
    );
  }
}
