import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyContent/answer_key_content_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';

class AnswerKeyContent extends StatelessWidget {
  final BookletModel model;
  final Function(bool) onUpdate;

  const AnswerKeyContent({
    required this.model,
    required this.onUpdate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      AnswerKeyContentController(model, onUpdate),
      tag: model.docID,
    );
    controller.syncModel(model);

    return Obx(
      () => GestureDetector(
        onTap: () => controller.openBooklet(context),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8)),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize:
                MainAxisSize.min, // Solution 1: Use minimum space needed
            children: [
              _buildHeader(context, controller),
              Flexible(
                // Solution 2: Make image flexible
                child: _buildImage(context, controller),
              ),
              _buildContent(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AnswerKeyContentController controller,
  ) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final canShareFeed = AdminAccessService.isKnownAdminSync() ||
        controller.model.userID == currentUid;
    return Container(
      height: 40,
      padding: EdgeInsets.only(left: 10, right: 5),
      child: Row(
        children: [
          GestureDetector(
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              child: SizedBox(
                width: 23,
                height: 23,
                child: controller.avatarUrl.value.isNotEmpty
                    ? Image.network(
                        controller.avatarUrl.value,
                        fit: BoxFit.cover,
                      )
                    : Center(child: CupertinoActivityIndicator()),
              ),
            ),
          ),
          SizedBox(width: 7),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  if (controller.model.userID != currentUid) {
                    Get.to(
                        () => SocialProfile(userID: controller.model.userID));
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        controller.nickname.value.isEmpty
                            ? ''
                            : controller.nickname.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    RozetContent(size: 13, userID: controller.model.userID),
                  ],
                ),
              ),
            ),
          ),
          if (canShareFeed)
            GestureDetector(
              onTap: controller.shareBooklet,
              child: Icon(
                CupertinoIcons.share_up,
                color: Colors.grey,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(
    BuildContext context,
    AnswerKeyContentController controller,
  ) {
    return GestureDetector(
      onTap: () => controller.openBooklet(context),
      child: AspectRatio(
        aspectRatio: 1 / 1.3,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          child: Image.network(
            controller.model.cover,
            key: ValueKey(controller.model.cover),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AnswerKeyContentController controller,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7, horizontal: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:
            MainAxisSize.min, // Solution 3: Use minimum space in content column
        children: [
          SizedBox(
            height: 40,
            child: Text(
              controller.model.baslik,
              maxLines: 2,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratBold",
              ),
            ),
          ),
          SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  controller.model.sinavTuru,
                  style: TextStyle(
                    color: Colors.indigo,
                    fontSize: 13,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ),
              Text(
                NumberFormatter.format(controller.model.goruntuleme.length),
                style: TextStyle(color: Colors.black, fontSize: 13),
              ),
              SizedBox(width: 3),
              SvgPicture.asset(
                "assets/icons/statsyeni.svg",
                height: 20,
                colorFilter:
                    const ColorFilter.mode(Colors.black, BlendMode.srcIn),
              ),
              SizedBox(width: 3),
              GestureDetector(
                onTap: controller.toggleBookmark,
                child: Icon(
                  controller.isBookmarked.value
                      ? CupertinoIcons.bookmark_fill
                      : CupertinoIcons.bookmark,
                  color: controller.isBookmarked.value
                      ? Colors.orange
                      : Colors.black,
                  size: 20,
                ),
              ),
            ],
          ),
          SizedBox(height: 3),
          Text(
            controller.model.yayinEvi,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontFamily: "MontserratBold",
            ),
          ),
          SizedBox(height: 3),
          GestureDetector(
            onTap: () => controller.openBooklet(context),
            child: Container(
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.pink,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Text(
                "Hemen Başla",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: "MontserratBold",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
