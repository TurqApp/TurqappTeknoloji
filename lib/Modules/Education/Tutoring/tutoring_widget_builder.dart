import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/user_moderation_guard.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/pasaj_card_styles.dart';
import 'package:turqappv2/Core/Widgets/pasaj_grid_card.dart';
import 'package:turqappv2/Core/Widgets/pasaj_list_card_metrics.dart';
import 'package:turqappv2/Core/Widgets/pasaj_listing_ad_layout.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutorings/my_tutorings_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/saved_tutorings_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Themes/app_icons.dart';

part 'tutoring_widget_builder_grid_part.dart';
part 'tutoring_widget_builder_list_part.dart';

String? getCurrentUserId() {
  final userId = CurrentUserService.instance.effectiveUserId;
  return userId.isNotEmpty ? userId : null;
}

class TutoringWidgetBuilder extends StatelessWidget {
  final List<TutoringModel> tutoringList;
  final bool isGridView;
  final Widget? infoMessage;
  final bool allowReactivate;

  const TutoringWidgetBuilder({
    super.key,
    required this.tutoringList,
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

      if (shortUrl.trim().isEmpty || shortUrl.trim() == 'https://turqapp.com') {
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
    final savedController = ensureSavedTutoringsController();
    final tutoringController = ensureTutoringController();
    final myTutoringsController = MyTutoringsController.maybeFind();
    final currentUserId = getCurrentUserId();

    if (tutoringList.isEmpty) {
      return Center(child: infoMessage ?? const SizedBox.shrink());
    }

    if (isGridView) {
      return _buildGridLayout(
        currentUserId: currentUserId,
        savedController: savedController,
        tutoringController: tutoringController,
        myTutoringsController: myTutoringsController,
      );
    }

    return _buildListLayout(
      currentUserId: currentUserId,
      savedController: savedController,
      tutoringController: tutoringController,
      myTutoringsController: myTutoringsController,
    );
  }

  Future<void> _openTutoringDetail(
    TutoringModel tutoring, {
    MyTutoringsController? myTutoringsController,
  }) async {
    if (allowReactivate &&
        tutoring.ended == true &&
        myTutoringsController != null) {
      await myTutoringsController.reactivateEndedTutoring(tutoring);
      return;
    }
    await Get.to(() => TutoringDetail(), arguments: tutoring);
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

  String _lessonPlaceText(TutoringModel tutoring) {
    if (tutoring.dersYeri.isEmpty) return 'Ders Yeri Belirtilmedi';
    final first = tutoring.dersYeri.first;
    if (tutoring.dersYeri.length == 1) return first;
    return '$first +${tutoring.dersYeri.length - 1}';
  }

  String _cityDistrictText(TutoringModel tutoring) {
    final city = tutoring.sehir.trim();
    final district = tutoring.ilce.trim();
    if (city.isNotEmpty && district.isNotEmpty) return '$city, $district';
    if (city.isNotEmpty) return city;
    if (district.isNotEmpty) return district;
    return 'pasaj.market.location_missing'.tr;
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
