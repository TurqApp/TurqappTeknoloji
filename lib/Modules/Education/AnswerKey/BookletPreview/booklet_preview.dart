import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletPreview/booklet_preview_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/report_user.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Themes/app_icons.dart';

class BookletPreview extends StatelessWidget {
  const BookletPreview({required this.model, super.key});

  final BookletModel model;

  bool _isOwner(String userId) => userId == FirebaseAuth.instance.currentUser?.uid;

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'MontserratBold',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF6F7FB),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'MontserratBold',
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAnswerKeysList(BookletPreviewController controller) {
    return Column(
      children: controller.answerKeys.map((item) {
        return GestureDetector(
          onTap: () => controller.navigateToAnswerKey(Get.context!, item),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.14)),
              ),
              child: Row(
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
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.dogruCevaplar.length} soru',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    color: Colors.black45,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildAuthorCard(BookletPreviewController controller) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF6F7FB),
      ),
      child: GestureDetector(
        onTap: _isOwner(controller.model.userID)
            ? null
            : () => Get.to(() => SocialProfile(userID: controller.model.userID)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFE5E7EB),
              backgroundImage: controller.avatarUrl.value.trim().isNotEmpty
                  ? NetworkImage(controller.avatarUrl.value)
                  : null,
              child: controller.avatarUrl.value.trim().isEmpty
                  ? const Icon(
                      CupertinoIcons.person_fill,
                      color: Colors.black54,
                      size: 18,
                    )
                  : null,
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
                              ? 'Turq Kullanıcı'
                              : controller.nickname.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                      ),
                      RozetContent(size: 14, userID: controller.model.userID),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isOwner(controller.model.userID)
                        ? 'Kitap sahibi'
                        : 'Profili görüntüle',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ],
              ),
            ),
            if (!_isOwner(controller.model.userID))
              const Icon(
                CupertinoIcons.chevron_right,
                color: Colors.black45,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _pullDownMenu(BookletPreviewController controller) {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () {
            Get.to(
              () => ReportUser(
                userID: controller.model.userID,
                postID: controller.model.docID,
                commentID: '',
              ),
            );
          },
          title: 'Kitabı Bildir',
          icon: CupertinoIcons.exclamationmark_circle,
        ),
      ],
      buttonBuilder: (context, showMenu) => AppHeaderActionButton(
        onTap: showMenu,
        child: Icon(
          AppIcons.ellipsisVertical,
          color: Colors.black,
          size: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BookletPreviewController(model));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
        ),
        title: const Text(
          'Kitap Detayı',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'MontserratBold',
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Obx(
              () => AppHeaderActionButton(
                onTap: controller.toggleBookmark,
                child: Icon(
                  controller.isBookmarked.value
                      ? CupertinoIcons.bookmark_fill
                      : CupertinoIcons.bookmark,
                  color: controller.isBookmarked.value
                      ? Colors.orange
                      : Colors.black87,
                  size: 20,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _pullDownMenu(controller),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: controller.model.cover,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: CupertinoActivityIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                controller.model.baslik,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${controller.model.yayinEvi}  •  ${controller.model.sinavTuru}',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontFamily: 'MontserratMedium',
                ),
              ),
              const SizedBox(height: 18),
              _infoCard(
                title: 'Kitap Bilgileri',
                children: [
                  _infoRow('Sınav Türü', controller.model.sinavTuru),
                  _infoRow('Yayın Evi', controller.model.yayinEvi),
                  _infoRow('Basım Tarihi', controller.model.basimTarihi),
                  _infoRow('Dil', controller.model.dil.isEmpty ? '-' : controller.model.dil),
                  _infoRow('Görüntülenme', controller.model.viewCount.toString()),
                ],
              ),
              const SizedBox(height: 18),
              _buildAuthorCard(controller),
              const SizedBox(height: 18),
              _infoCard(
                title: 'Cevap Anahtarları',
                children: controller.answerKeys.isEmpty
                    ? const [
                        Text(
                          'Bu kitap için henüz cevap anahtarı bulunmuyor.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                      ]
                    : [_buildAnswerKeysList(controller)],
              ),
              const SizedBox(height: 12),
              const AdmobKare(
                key: ValueKey('answer-key-detail-ad-end'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
