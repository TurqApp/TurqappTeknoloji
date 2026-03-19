import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/user_moderation_guard.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/app_icon_surface.dart';
import 'package:turqappv2/Core/Widgets/pasaj_listing_ad_layout.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutorings/my_tutorings_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/saved_tutorings_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Themes/app_icons.dart';

String? getCurrentUserId() {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  return (userId != null && userId.isNotEmpty) ? userId : null;
}

class TutoringWidgetBuilder extends StatelessWidget {
  final List<TutoringModel> tutoringList;
  final Map<String, Map<String, dynamic>> users;
  final bool isGridView;
  final Widget? infoMessage;
  final bool allowReactivate;

  const TutoringWidgetBuilder({
    super.key,
    required this.tutoringList,
    required this.users,
    required this.isGridView,
    this.infoMessage,
    this.allowReactivate = false,
  });

  Future<void> _shareExternally(TutoringModel tutoring) async {
    await ShareActionGuard.run(() async {
      final shareId = 'tutoring:${tutoring.docID}';
      final shortTail = tutoring.docID.length >= 8
          ? tutoring.docID.substring(0, 8)
          : tutoring.docID;
      final fallbackId = 'tutoring-$shortTail';
      final fallbackUrl = 'https://turqapp.com/e/$fallbackId';

      String shortUrl = fallbackUrl;
      try {
        shortUrl = await ShortLinkService().getEducationPublicUrl(
          shareId: shareId,
          title: tutoring.baslik,
          desc: tutoring.brans.isNotEmpty ? tutoring.brans : 'Özel ders ilanı',
          imageUrl: tutoring.imgs != null && tutoring.imgs!.isNotEmpty
              ? tutoring.imgs!.first
              : null,
        );
      } catch (_) {
        shortUrl = fallbackUrl;
      }

      if (shortUrl.trim().isEmpty ||
          shortUrl.trim() == 'https://turqapp.com') {
        shortUrl = fallbackUrl;
      }

      await ShareLinkService.shareUrl(
        url: shortUrl,
        title: tutoring.baslik,
        subject: tutoring.baslik,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final savedController = Get.isRegistered<SavedTutoringsController>()
        ? Get.find<SavedTutoringsController>()
        : Get.put(SavedTutoringsController());
    final tutoringController = Get.isRegistered<TutoringController>()
        ? Get.find<TutoringController>()
        : Get.put(TutoringController());
    final myTutoringsController = Get.isRegistered<MyTutoringsController>()
        ? Get.find<MyTutoringsController>()
        : null;
    final currentUserId = getCurrentUserId();

    if (tutoringList.isEmpty) {
      return Center(child: infoMessage ?? const SizedBox.shrink());
    }

    if (isGridView) {
      return Column(
        children: PasajListingAdLayout.buildTwoColumnGridChildren(
          items: tutoringList,
          horizontalSpacing: 8,
          rowSpacing: 8,
          itemBuilder: (tutoring, index) {
            final lessonPlace = _lessonPlaceText(tutoring);
            final imageUrl = _imageUrl(tutoring);
            final teacherName = _teacherName(tutoring);
            return GestureDetector(
              onTap: () async {
                if (allowReactivate &&
                    tutoring.ended == true &&
                    myTutoringsController != null) {
                  await myTutoringsController.reactivateEndedTutoring(tutoring);
                  return;
                }
                await Get.to(() => TutoringDetail(), arguments: tutoring);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  border: Border.all(color: Colors.grey.withAlpha(50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                topLeft: Radius.circular(8),
                              ),
                              child: imageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) =>
                                          _fallbackImage(),
                                    )
                                  : _fallbackImage(),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Obx(
                              () => GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _toggleSave(
                                  tutoring: tutoring,
                                  currentUserId: currentUserId,
                                  controller: tutoringController,
                                  savedController: savedController,
                                ),
                                child: SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: Center(
                                    child: Icon(
                                      savedController.savedTutoringIds
                                              .contains(tutoring.docID)
                                          ? AppIcons.saved
                                          : AppIcons.save,
                                      size: 24,
                                      color: Colors.white,
                                      shadows: const [
                                        Shadow(
                                          color: Color(0x66000000),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 7, 8, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tutoring.baslik,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                          Text(
                            teacherName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                          Text(
                            lessonPlace,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.pinkAccent,
                              fontSize: 12,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                          Text(
                            "${tutoring.sehir}, ${tutoring.ilce}",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontFamily: "MontserratMedium",
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: () => Get.to(
                                () => TutoringDetail(),
                                arguments: tutoring,
                              ),
                              child: Container(
                                height: 30,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                ),
                                child: Text(
                                  allowReactivate && tutoring.ended == true
                                      ? 'Yayına Al'
                                      : 'İncele',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontFamily: 'MontserratMedium',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          adBuilder: (slot) => AdmobKare(
            key: ValueKey('tutoring-grid-ad-$slot'),
          ),
        ),
      );
    }

    return Column(
      children: PasajListingAdLayout.buildListChildren(
        items: tutoringList,
        itemBuilder: (tutoring, index) {
        final lessonPlace = _lessonPlaceText(tutoring);
        final imageUrl = _imageUrl(tutoring);
        return Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 6, top: 6),
          child: GestureDetector(
            onTap: () async {
              if (allowReactivate &&
                  tutoring.ended == true &&
                  myTutoringsController != null) {
                await myTutoringsController.reactivateEndedTutoring(tutoring);
                return;
              }
              await Get.to(() => TutoringDetail(), arguments: tutoring);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
                color: Colors.white,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _fallbackImage(),
                            )
                          : _fallbackImage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 96,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tutoring.baslik,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tutoring.brans,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lessonPlace,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "${tutoring.sehir}, ${tutoring.ilce}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                    fontFamily: "MontserratMedium",
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 108,
                    height: 96,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppHeaderActionButton(
                              onTap: () => _shareExternally(tutoring),
                              child: Icon(
                                AppIcons.share,
                                size: AppIconSurface.kIconSize,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Obx(() {
                              final isSaved = savedController.savedTutoringIds
                                  .contains(tutoring.docID);
                              return AppHeaderActionButton(
                                onTap: () => _toggleSave(
                                  tutoring: tutoring,
                                  currentUserId: currentUserId,
                                  controller: tutoringController,
                                  savedController: savedController,
                                ),
                                child: Icon(
                                  isSaved ? AppIcons.saved : AppIcons.save,
                                  size: AppIconSurface.kIconSize,
                                  color: isSaved
                                      ? Colors.orange
                                      : Colors.black87,
                                ),
                              );
                            }),
                          ],
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 108,
                          child: GestureDetector(
                            onTap: () async {
                              if (allowReactivate &&
                                  tutoring.ended == true &&
                                  myTutoringsController != null) {
                                await myTutoringsController
                                    .reactivateEndedTutoring(tutoring);
                                return;
                              }
                              await Get.to(
                                () => TutoringDetail(),
                                arguments: tutoring,
                              );
                            },
                            child: Container(
                              height: 30,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                              child: Text(
                                allowReactivate && tutoring.ended == true
                                    ? 'Yayına Al'
                                    : 'İncele',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontFamily: 'MontserratMedium',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        },
        adBuilder: (slot) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: AdmobKare(
            key: ValueKey('tutoring-list-ad-$slot'),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleSave({
    required TutoringModel tutoring,
    required String? currentUserId,
    required TutoringController controller,
    required SavedTutoringsController savedController,
  }) async {
    if (!UserModerationGuard.ensureAllowed(RestrictedAction.saveTutoring)) {
      return;
    }
    if (currentUserId == null) return;
    final isSaved = savedController.savedTutoringIds.contains(tutoring.docID);
    final success = await controller.toggleFavorite(
      tutoring.docID,
      currentUserId,
      isSaved,
    );
    if (!success) return;
    if (isSaved) {
      savedController.removeSavedTutoring(tutoring.docID);
    } else {
      savedController.addSavedTutoring(tutoring.docID);
    }
  }

  String _teacherName(TutoringModel tutoring) {
    if (tutoring.displayName.trim().isNotEmpty) {
      return tutoring.displayName.trim();
    }
    if (tutoring.nickname.trim().isNotEmpty) {
      return tutoring.nickname.trim();
    }
    final user = users[tutoring.userID];
    final displayName = (user?['displayName'] ?? '').toString().trim();
    if (displayName.isNotEmpty) return displayName;
    final nickname = (user?['nickname'] ?? '').toString().trim();
    if (nickname.isNotEmpty) return nickname;
    return 'Öğretmen';
  }

  String _lessonPlaceText(TutoringModel tutoring) {
    if (tutoring.dersYeri.isEmpty) return 'Ders Yeri Belirtilmedi';
    final first = tutoring.dersYeri.first;
    if (tutoring.dersYeri.length == 1) return first;
    return '$first +${tutoring.dersYeri.length - 1}';
  }

  String _imageUrl(TutoringModel tutoring) {
    if (tutoring.imgs == null || tutoring.imgs!.isEmpty) return '';
    return tutoring.imgs!.first;
  }

  Widget _fallbackImage() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(CupertinoIcons.photo, color: Colors.grey),
    );
  }
}
