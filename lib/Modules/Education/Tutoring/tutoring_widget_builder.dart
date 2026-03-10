import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Widgets/education_share_icon_button.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/saved_tutorings_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

String? getCurrentUserId() {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  return (userId != null && userId.isNotEmpty) ? userId : null;
}

class TutoringWidgetBuilder extends StatelessWidget {
  final List<TutoringModel> tutoringList;
  final Map<String, Map<String, dynamic>> users;
  final bool isGridView;
  final Widget? infoMessage;

  const TutoringWidgetBuilder({
    super.key,
    required this.tutoringList,
    required this.users,
    required this.isGridView,
    this.infoMessage,
  });

  @override
  Widget build(BuildContext context) {
    final SavedTutoringsController savedController =
        Get.isRegistered<SavedTutoringsController>()
            ? Get.find<SavedTutoringsController>()
            : Get.put(SavedTutoringsController());
    final TutoringController tutoringController =
        Get.isRegistered<TutoringController>()
            ? Get.find<TutoringController>()
            : Get.put(TutoringController());
    final String? currentUserId = getCurrentUserId();

    if (tutoringList.isEmpty) {
      return Center(child: infoMessage ?? SizedBox());
    }

    return isGridView
        ? GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: tutoringList.length,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: MediaQuery.of(context).size.width * 0.5,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.620,
            ),
            itemBuilder: (context, index) {
              final tutoring = tutoringList[index];
              final user = users[tutoring.userID] ?? {};
              final String firstName = (user['firstName'] ?? '').toString();
              final String lastName = (user['lastName'] ?? '').toString();
              final String nickname = (user['nickname'] ??
                      user['username'] ??
                      user['displayName'] ??
                      '')
                  .toString()
                  .trim();
              final String shownName = nickname.isNotEmpty
                  ? nickname
                  : '$firstName $lastName'.trim();
              final String userID = tutoring.userID;
              final bool canShareFeed = AdminAccessService.isKnownAdminSync() ||
                  currentUserId == tutoring.userID;

              return GestureDetector(
                onTap: () =>
                    Get.to(() => TutoringDetail(), arguments: tutoring),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      tutoring.imgs != null && tutoring.imgs!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8.0),
                              ),
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: CachedNetworkImage(
                                  imageUrl: tutoring.imgs!.first,
                                  placeholder: (context, url) =>
                                      CupertinoActivityIndicator(),
                                  errorWidget: (context, url, error) =>
                                      Icon(AppIcons.photo),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: Icon(CupertinoIcons.photo, size: 50),
                            ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    tutoring.baslik,
                                    style: TextStyles.bold16Black,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                if (canShareFeed)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: EducationShareIconButton(
                                      onTap: () => _shareTutoring(tutoring),
                                    ),
                                  ),
                                Obx(() {
                                  final isSaved = savedController
                                      .savedTutoringIds
                                      .contains(tutoring.docID);
                                  return EducationActionIconButton(
                                    onTap: () async {
                                      if (currentUserId != null) {
                                        if (isSaved) {
                                          savedController.removeSavedTutoring(
                                            tutoring.docID,
                                          );
                                        } else {
                                          savedController.addSavedTutoring(
                                            tutoring.docID,
                                          );
                                        }
                                        await tutoringController.toggleFavorite(
                                          tutoring.docID,
                                          currentUserId,
                                          isSaved,
                                        );
                                        if (isSaved) {
                                          savedController.removeSavedTutoring(
                                            tutoring.docID,
                                          );
                                        } else if (!tutoring.favorites.contains(
                                          currentUserId,
                                        )) {
                                          savedController.addSavedTutoring(
                                            tutoring.docID,
                                          );
                                        }
                                      } else {
                                        log("User ID not found");
                                      }
                                    },
                                    icon: isSaved
                                        ? AppIcons.saved
                                        : AppIcons.save,
                                    iconSize: 18,
                                    iconColor: isSaved
                                        ? Colors.orange
                                        : Colors.black87,
                                  );
                                }),
                              ],
                            ),
                            4.ph,
                            GestureDetector(
                              onTap: () {
                                if (currentUserId != null &&
                                    currentUserId != userID) {
                                  Get.to(() => SocialProfile(userID: userID));
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    shownName,
                                    style: TextStyles.bold16Black,
                                  ),
                                  4.pw,
                                  RozetContent(size: 14, userID: userID),
                                ],
                              ),
                            ),
                            4.ph,
                            Text(
                              tutoring.brans,
                              style: TextStyles.tutoringBranch,
                            ),
                            4.ph,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "${tutoring.sehir}/${tutoring.ilce}",
                                  style: TextStyles.tutoringLocation,
                                ),
                                2.pw,
                                Icon(
                                  AppIcons.locationSolid,
                                  size: 14,
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        : ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: tutoringList.length,
            itemBuilder: (context, index) {
              final tutoring = tutoringList[index];
              final user = users[tutoring.userID] ?? {};
              final String firstName = (user['firstName'] ?? '').toString();
              final String lastName = (user['lastName'] ?? '').toString();
              final String nickname = (user['nickname'] ??
                      user['username'] ??
                      user['displayName'] ??
                      '')
                  .toString()
                  .trim();
              final String shownName = nickname.isNotEmpty
                  ? nickname
                  : '$firstName $lastName'.trim();
              final String userID = tutoring.userID;
              final bool canShareFeed = AdminAccessService.isKnownAdminSync() ||
                  currentUserId == tutoring.userID;

              return Column(
                children: [
                  GestureDetector(
                    onTap: () =>
                        Get.to(() => TutoringDetail(), arguments: tutoring),
                    child: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Görsel
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: CachedNetworkImage(
                              imageUrl: tutoring.imgs != null &&
                                      tutoring.imgs!.isNotEmpty
                                  ? tutoring.imgs!.first
                                  : '',
                              placeholder: (context, url) =>
                                  CupertinoActivityIndicator(),
                              errorWidget: (context, url, error) =>
                                  Icon(CupertinoIcons.photo),
                              fit: BoxFit.cover,
                              width: 65,
                              height: 65,
                            ),
                          ),
                          12.pw,
                          // İçerik
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        tutoring.baslik,
                                        style: TextStyles.bold15Black,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    if (canShareFeed)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: EducationShareIconButton(
                                          onTap: () => _shareTutoring(tutoring),
                                        ),
                                      ),
                                    Obx(() {
                                      final isSaved = savedController
                                          .savedTutoringIds
                                          .contains(tutoring.docID);
                                      return EducationActionIconButton(
                                        onTap: () async {
                                          if (currentUserId != null) {
                                            if (isSaved) {
                                              savedController
                                                  .removeSavedTutoring(
                                                tutoring.docID,
                                              );
                                            } else {
                                              savedController.addSavedTutoring(
                                                tutoring.docID,
                                              );
                                            }
                                            await tutoringController
                                                .toggleFavorite(
                                              tutoring.docID,
                                              currentUserId,
                                              isSaved,
                                            );
                                            if (isSaved) {
                                              savedController
                                                  .removeSavedTutoring(
                                                tutoring.docID,
                                              );
                                            } else if (!tutoring.favorites
                                                .contains(currentUserId)) {
                                              savedController.addSavedTutoring(
                                                tutoring.docID,
                                              );
                                            }
                                          } else {
                                            log("User ID not found");
                                          }
                                        },
                                        icon: isSaved
                                            ? AppIcons.saved
                                            : AppIcons.save,
                                        iconSize: 18,
                                        iconColor: isSaved
                                            ? Colors.orange
                                            : Colors.black87,
                                      );
                                    }),
                                  ],
                                ),
                                4.ph,
                                GestureDetector(
                                  onTap: () {
                                    if (currentUserId != null &&
                                        currentUserId != userID) {
                                      Get.to(
                                          () => SocialProfile(userID: userID));
                                    }
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        shownName,
                                        style: TextStyles.medium15Black,
                                      ),
                                      4.pw,
                                      RozetContent(size: 14, userID: userID),
                                    ],
                                  ),
                                ),
                                4.ph,
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      tutoring.brans,
                                      style: TextStyles.tutoringBranch,
                                    ),
                                    Text(
                                      "${tutoring.sehir}/${tutoring.ilce}",
                                      style: TextStyles.tutoringLocation,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 90),
                    child: SizedBox(
                      height: 1,
                      child: Divider(color: Colors.grey.withAlpha(20)),
                    ),
                  ),
                ],
              );
            },
          );
  }

  Future<void> _shareTutoring(TutoringModel tutoring) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final canShareFeed =
        AdminAccessService.isKnownAdminSync() || tutoring.userID == currentUid;
    if (!canShareFeed) {
      AppSnackbar("Yetki", "Sadece admin ve ilan sahibi paylaşabilir.");
      return;
    }
    await ShareActionGuard.run(() async {
      var shortUrl = '';
      try {
        shortUrl = await ShortLinkService().getInternalEducationPublicUrl(
          shareId: 'tutoring:${tutoring.docID}',
          title: tutoring.baslik,
          desc: tutoring.aciklama,
          imageUrl: tutoring.imgs != null && tutoring.imgs!.isNotEmpty
              ? tutoring.imgs!.first
              : null,
        );
      } catch (_) {}

      if (shortUrl.trim().isEmpty) {
        shortUrl = 'https://turqapp.com/i/tutoring:${tutoring.docID}';
      }

      await ShareLinkService.shareUrl(
        url: shortUrl,
        title: tutoring.baslik,
        subject: tutoring.baslik,
      );
    });
  }
}
