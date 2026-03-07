import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletPreview/booklet_preview_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class BookletPreview extends StatelessWidget {
  final BookletModel model;

  const BookletPreview({required this.model, super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BookletPreviewController(model));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(
          () => Column(
            children: [
              _buildHeader(context, controller),
              Expanded(
                child: ListView(
                  children: [
                    _buildCoverImage(context, controller),
                    _buildContent(context, controller),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    BookletPreviewController controller,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        BackButtons(text: controller.model.yayinEvi),
        IconButton(
          onPressed: controller.toggleBookmark,
          icon: Icon(
            controller.isBookmarked.value ? AppIcons.save : AppIcons.saved,
            color: controller.isBookmarked.value ? Colors.black : Colors.orange,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildCoverImage(
    BuildContext context,
    BookletPreviewController controller,
  ) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.width,
      child: CachedNetworkImage(
        imageUrl: controller.model.cover,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            const Center(child: CupertinoActivityIndicator()),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    BookletPreviewController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.model.baslik,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: "MontserratBold",
            ),
          ),
          const SizedBox(height: 5),
          Text(
            controller.model.yayinEvi,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 15,
              fontFamily: "MontserratBold",
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                controller.model.sinavTuru,
                style: const TextStyle(
                  color: Colors.indigo,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
              Text(
                controller.model.basimTarihi,
                style: const TextStyle(
                  color: Colors.indigo,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ],
          ),
          8.ph,
          _buildUserInfo(controller),
          8.ph,
          const Text(
            "Cevap Anahtarları",
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: "MontserratBold",
            ),
          ),
          const SizedBox(height: 15),
          _buildAnswerKeysList(controller),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BookletPreviewController controller) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return GestureDetector(
      onTap: () {
        if (currentUserId != null && currentUserId != controller.model.userID) {
          Get.to(() => SocialProfile(userID: controller.model.userID));
        }
      },
      child: Container(
        decoration: BoxDecoration(
            color: Colors.grey.withAlpha(20),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(color: Colors.black, width: 1)),
        // Keep X axis unchanged; only reduce vertical scale slightly.
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13.5),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              child: SizedBox(
                width: 40,
                height: 40,
                child: controller.avatarUrl.value.isNotEmpty
                    ? Image.network(
                        controller.avatarUrl.value,
                        fit: BoxFit.cover,
                      )
                    : const CupertinoActivityIndicator(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          controller.nickname.value.isEmpty
                              ? ''
                              : controller.nickname.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      RozetContent(size: 14, userID: controller.model.userID),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_ios, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerKeysList(BookletPreviewController controller) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.answerKeys.length,
      itemBuilder: (context, index) {
        final item = controller.answerKeys[index];
        return GestureDetector(
          onTap: () => controller.navigateToAnswerKey(context, item),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.baslik,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${item.dogruCevaplar.length} Soru",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.indigo,
                      size: 15,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
