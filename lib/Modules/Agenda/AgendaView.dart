import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../Models/PostsModel.dart';
import 'package:turqappv2/Core/Helpers/GlobalLoader/GlobalLoader.dart';
import 'package:turqappv2/Modules/Agenda/ClassicContent/ClassicContent.dart';
import 'package:turqappv2/Modules/Agenda/TopTags/TopTags.dart';
import 'package:turqappv2/Modules/PostCreator/PostCreator.dart';
import 'package:turqappv2/Modules/Agenda/AgendaController.dart';
import 'package:turqappv2/Modules/Story/StoryRow/StoryRow.dart';
import 'package:turqappv2/Services/FirebaseMyStore.dart';
import 'package:turqappv2/TestFirebase.dart';
import 'package:turqappv2/Utils/EmptyPadding.dart';
import 'package:turqappv2/Ads/AdmobKare.dart';
import '../../Core/Buttons/IconButtons.dart';
import '../../Themes/AppFonts.dart';
import '../../Themes/AppColors.dart';
import '../../Core/Helpers/GlobalLoader/GlobalLoaderController.dart';
import '../../Core/Helpers/UnreadMessagesController/UnreadMessagesController.dart';
import '../Chat/ChatListing/ChatListing.dart';
import '../InAppNotifications/InAppNotifications.dart';
import '../InAppNotifications/InAppNotificationsController.dart';
import '../RecommendedUserList/RecommendedUserList.dart';
import '../RecommendedUserList/RecommendedUserListController.dart';
import '../Story/StoryRow/StoryRowController.dart';
import 'AgendaContent/AgendaContent.dart';

class AgendaView extends StatelessWidget {
  AgendaView({super.key});

  AgendaController get controller {
    if (Get.isRegistered<AgendaController>()) {
      return Get.find<AgendaController>();
    } else {
      return Get.put(AgendaController());
    }
  }

  final user = Get.find<FirebaseMyStore>();
  final loader = Get.find<GlobalLoaderController>();

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
              height: topInset + 12,
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
                      final centeredIndex = controller.centeredIndex.value;
                      // Rebuild when my reshare map changes
                      controller.lastCenteredIndex = centeredIndex;

                      final Map<String, int> agendaIndexByDoc = {
                        for (int i = 0; i < controller.agendaList.length; i++)
                          controller.agendaList[i].docID: i,
                      };

                      // Tekilleştirilmiş görüntü listesi: aynı post için tek satır.
                      // Reshare varsa normal satırı override eder.
                      final Map<String, Map<String, dynamic>> displayByDoc = {};

                      for (int i = 0; i < controller.agendaList.length; i++) {
                        final m = controller.agendaList[i];
                        displayByDoc[m.docID] = {
                          'type': 'normal',
                          'model': m,
                          'reshare': false,
                          'reshareUserID': null,
                          'timestamp': m.timeStamp,
                          'agendaIndex': i,
                        };
                      }

                      for (final reshareEntry
                          in controller.feedReshareEntries) {
                        final post = reshareEntry['post'] as PostsModel;
                        final idx = agendaIndexByDoc[post.docID];
                        if (idx == null || idx < 0) continue;
                        final modelRef = controller.agendaList[idx];
                        final reshareTimestamp =
                            (reshareEntry['reshareTimestamp'] ?? 0) as int;
                        final reshareUserID =
                            reshareEntry['reshareUserID'] as String?;

                        final existing = displayByDoc[post.docID];
                        final existingTs = (existing?['timestamp'] ?? 0) as int;
                        if (existing == null ||
                            reshareTimestamp >= existingTs) {
                          displayByDoc[post.docID] = {
                            'type': 'reshare',
                            'model': modelRef,
                            'reshare': true,
                            'reshareUserID': reshareUserID,
                            'timestamp': reshareTimestamp,
                            'agendaIndex': idx,
                          };
                        }
                      }

                      final List<Map<String, dynamic>> display = displayByDoc
                          .values
                          .toList()
                        ..sort((a, b) => (b['timestamp'] as int)
                            .compareTo(a['timestamp'] as int));

                      return ListView.builder(
                        controller: controller.scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        cacheExtent: 1000.0,
                        padding: EdgeInsets.only(
                          bottom: kBottomNavigationBarHeight + 16,
                        ),
                        itemCount: display.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) return header();

                          final actualIndex = index - 1;

                          if (actualIndex >= display.length) {
                            if (controller.hasMore.value) {
                              if (!controller.isLoading.value) {
                                controller.fetchAgendaBigData();
                              }
                            }
                            return const SizedBox.shrink();
                          }

                          final item = display[actualIndex];
                          final model = item['model'] as PostsModel;
                          final isReshare = (item['reshare'] == true);
                          final reshareUserID =
                              item['reshareUserID'] as String?;
                          final agendaIndex =
                              (item['agendaIndex'] ?? -1) as int;
                          final isCentered = centeredIndex == agendaIndex;

                          final List<Widget> columnChildren = [];
                          Widget postWidget;
                          // Stabil key için sadece gerekli bilgiyi kullan
                          final String stableKeyString = isReshare
                              ? "${model.docID}_reshare_$reshareUserID"
                              : "${model.docID}_original";

                          // VisibilityDetector ile sarmalayarak görünürlük tespiti yap
                          Widget buildPostContent() {
                            if (user.viewSelection.value == 1) {
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
                          }

                          postWidget = VisibilityDetector(
                            key: Key('visibility_$stableKeyString'),
                            onVisibilityChanged: (info) {
                              final modelIndex = agendaIndex;
                              if (modelIndex < 0) return;

                              // 🎯 INSTAGRAM STYLE: Fiziksel görünürlük = gerçek kontrol
                              // %80+ görünür -> Video OYNAT (merkeze yakın)
                              // %40- görünür -> Video DURDUR (ekrandan uzak/RecommendedUserList kapatmış)

                              if (info.visibleFraction >= 0.80) {
                                // Video ekranın çoğunu kaplıyor - OYNAT
                                if (controller.centeredIndex.value !=
                                    modelIndex) {
                                  controller.centeredIndex.value = modelIndex;
                                  controller.lastCenteredIndex = modelIndex;
                                }
                              } else if (info.visibleFraction < 0.40) {
                                // Video ekranın azını kaplıyor veya RecommendedUserList engelliyor - DURDUR
                                if (controller.centeredIndex.value ==
                                    modelIndex) {
                                  controller.centeredIndex.value = -1;
                                }
                              }
                            },
                            child: buildPostContent(),
                          );

                          // Yeni yüklenen gönderiler için kısa vurgulu fade overlay
                          final isHighlighted =
                              controller.highlightDocIDs.contains(model.docID);
                          if (isHighlighted) {
                            postWidget = TweenAnimationBuilder<double>(
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
                                                AppColors.textBlue
                                                    .withOpacity(0.10 * t),
                                                AppColors.textPink
                                                    .withOpacity(0.10 * t),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                              child: postWidget,
                            );
                          }

                          columnChildren.add(postWidget);

                          // originalUserID: boş değilse sol altta göster
                          // Not: Etiket artık içerik bileşenlerinde (Classic/AgendaContent) butonların üstünde gösteriliyor.

                          columnChildren.add(
                            Divider(color: Colors.grey.withAlpha(20)),
                          );

                          // Her 5 gönderiden sonra: önerilen kişiler + altına reklam
                          if ((actualIndex + 1) % 5 == 0) {
                            final slot = ((actualIndex + 1) ~/ 5);
                            // Önerilen kişiler
                            columnChildren.add(
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: RecommendedUserList(
                                  key: ValueKey('recommendedUserList-$slot'),
                                  batch: slot,
                                ),
                              ),
                            );
                            // Reklam
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

                          return Padding(
                            key: ValueKey('row-$stableKeyString'),
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: columnChildren,
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
            final offset = controller.scrollOffset.value;
            if (offset <= 1000) {
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
                          color: Colors.white.withOpacity(0.88),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withOpacity(0.06),
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
            right: 15,
            top: Get.mediaQuery.padding.top + 18,
            bottom: 8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Renkli TurqApp yazısı
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [AppColors.primaryColor, AppColors.secondColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                child: Text(
                  'TurqApp',
                  style: TextStyle(
                    fontSize: GetPlatform.isAndroid ? 31 : 27,
                    fontFamily: AppFontFamilies.mbold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  final prevIndex = controller.lastCenteredIndex;
                  controller.centeredIndex.value = -1;
                  Get.to(() => TopTags())?.then((_) {
                    // Feed odagini geri yukle
                    controller.centeredIndex.value = prevIndex ?? 0;
                    // Uygulama içinde gezinip geri dönünce önerileri yenile
                    try {
                      recommendedController.getUsers();
                    } catch (_) {}
                  });
                },
                child: const Icon(
                  CupertinoIcons.number,
                  color: Colors.black,
                  size: 20,
                ),
              ),
              12.pw,
              GestureDetector(
                onTap: () {
                  final prevIndex = controller.lastCenteredIndex;
                  controller.centeredIndex.value = -1;
                  Get.to(() => ChatListing())?.then((_) {
                    controller.centeredIndex.value = prevIndex ?? 0;
                    try {
                      recommendedController.getUsers();
                    } catch (_) {}
                  });
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      CupertinoIcons.mail,
                      color: Colors.black,
                      size: 20,
                    ),
                    Obx(() {
                      final hasUnread =
                          unreadController.totalUnreadCount.value > 0;
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
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              12.pw,
              GestureDetector(
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
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      CupertinoIcons.bell,
                      color: Colors.black,
                      size: 20,
                    ),
                    Obx(() {
                      final hasUnread = notificationsController.unreadCount > 0;
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
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      );
                    }),
                  ],
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
        15.ph,
      ],
    );
  }
}
