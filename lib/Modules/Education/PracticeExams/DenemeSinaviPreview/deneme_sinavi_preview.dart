import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Services/education_feed_post_share_service.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/Widgets/education_share_icon_button.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeSinaviPreview/deneme_sinavi_preview_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeSinaviYap/deneme_sinavi_yap.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/report_user.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class DenemeSinaviPreview extends StatelessWidget {
  const DenemeSinaviPreview({super.key, required this.model});

  final SinavModel model;
  final EducationFeedPostShareService shareService =
      const EducationFeedPostShareService();

  bool _isOwner(String userId) =>
      userId == FirebaseAuth.instance.currentUser?.uid;

  Future<void> _handlePrimaryAction(
    DenemeSinaviPreviewController controller,
  ) async {
    if (controller.currentTime.value <
        controller.examTime.value - controller.fifteenMinutes) {
      await controller.addBasvuru();
      return;
    }
    if (controller.currentTime.value >=
            controller.examTime.value - controller.fifteenMinutes &&
        controller.currentTime.value < controller.examTime.value) {
      AppSnackbar(
        'Başvuruya Kapanmıştır!',
        'Başvurular sınav tarihinden 15 dk önce kapanacaktır.',
      );
      return;
    }
    if (controller.currentTime.value >= controller.examTime.value &&
        controller.currentTime.value < controller.model.bitis) {
      if (controller.sinavaGirebilir.value) {
        if (controller.dahaOnceBasvurdu.value) {
          Get.to(
            () => DenemeSinaviYap(
              model: controller.model,
              sinaviBitir: controller.sinaviBitirAlert,
              showGecersizAlert: controller.showGecersizAlert,
              uyariAtla: false,
            ),
          );
        } else {
          AppSnackbar(
            'Başvuru Yapmadın!',
            'Başvuru yapılmayan sınavlara katılamazsın. Sadece başvuru yapanlar katılabilir.',
          );
        }
      } else {
        AppSnackbar(
          'Sınava Giremezsiniz!',
          'Bu sınava giriş hakkınız bulunmuyor. Daha önce bu sınavda geçersiz sayıldınız. Sınav sonlanmadan sınava bir daha giremezsiniz!',
        );
      }
      return;
    }
    if (controller.model.public) {
      Get.to(
        () => DenemeSinaviYap(
          model: controller.model,
          sinaviBitir: controller.sinaviBitirAlert,
          showGecersizAlert: controller.showGecersizAlert,
          uyariAtla: true,
        ),
      );
      return;
    }
    AppSnackbar(
      'Sınav Bitti!',
      'Bir sonraki sınavlara başvurabilirsiniz. Bu sınav sonlanmıştır.',
    );
  }

  Color _ctaColor(DenemeSinaviPreviewController controller) {
    if (controller.currentTime.value <
        controller.examTime.value - controller.fifteenMinutes) {
      return Colors.teal;
    }
    if (controller.currentTime.value >=
            controller.examTime.value - controller.fifteenMinutes &&
        controller.currentTime.value < controller.examTime.value) {
      return Colors.purple;
    }
    if (controller.currentTime.value >= controller.examTime.value &&
        controller.currentTime.value < controller.model.bitis) {
      return Colors.black;
    }
    if (controller.currentTime.value >= controller.examTime.value &&
        controller.currentTime.value > controller.model.bitis &&
        controller.model.public == false) {
      return Colors.red;
    }
    return Colors.indigo;
  }

  String _ctaLabel(DenemeSinaviPreviewController controller) {
    if (controller.currentTime.value <
        controller.examTime.value - controller.fifteenMinutes) {
      return controller.dahaOnceBasvurdu.value
          ? 'Başvuru Yapıldı'
          : 'Hemen Başvur';
    }
    if (controller.currentTime.value >=
            controller.examTime.value - controller.fifteenMinutes &&
        controller.currentTime.value < controller.examTime.value) {
      final minutes = ((controller.examTime.value -
                  controller.currentTime.value) /
              (60 * 1000))
          .floor();
      return 'Başvuruya Kapandı.\n$minutes dk sonra başlayacak.';
    }
    if (controller.currentTime.value >= controller.examTime.value &&
        controller.currentTime.value < controller.model.bitis) {
      return 'Sınav Başladı';
    }
    if (controller.currentTime.value >= controller.examTime.value &&
        controller.currentTime.value > controller.model.bitis &&
        controller.model.public == false) {
      return 'Sınav Bitti';
    }
    return 'Hemen Başla';
  }

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

  Widget _buildAuthorCard(DenemeSinaviPreviewController controller) {
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
                        ? 'Sınav sahibi'
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

  Widget _buildSuccessSheet(DenemeSinaviPreviewController controller) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        GestureDetector(
          onTap: () => controller.showSucces.value = false,
          child: Container(
            color: Colors.black.withValues(alpha: 0.2),
          ),
        ),
        Container(
          height: (Get.height * 0.28).clamp(190.0, 220.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(18),
              topLeft: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Başvurun Tamamlandı!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'MontserratBold',
                  ),
                ),
                15.ph,
                const Text(
                  'Sınavdan önce size bildirim göndererek gerekli hatırlatmaları yapacağız. Başarılar diliyoruz!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
                15.ph,
                GestureDetector(
                  onTap: Get.back,
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: const Text(
                      'Tamam',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pullDownMenu(DenemeSinaviPreviewController controller) {
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
          title: 'Sınavı Bildir',
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
    final controller = Get.put(DenemeSinaviPreviewController(model: model));

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
          'Sınav Detayı',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'MontserratBold',
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: EducationFeedShareIconButton(
              onTap: () => shareService.sharePracticeExam(model),
              size: 36,
              iconSize: 20,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Obx(
              () => AppHeaderActionButton(
                onTap: controller.toggleSaved,
                child: Icon(
                  controller.isSaved.value
                      ? CupertinoIcons.bookmark_fill
                      : CupertinoIcons.bookmark,
                  size: 20,
                  color: controller.isSaved.value
                      ? Colors.orange
                      : Colors.black87,
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
        child: Stack(
          children: [
            Obx(
              () {
                if (controller.isLoading.value) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                if (controller.isInitialized.value &&
                    controller.nickname.value.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Kullanıcı bilgileri yüklenemedi. Lütfen tekrar deneyin veya sınav sahibini kontrol edin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: controller.refreshData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: CachedNetworkImage(
                            imageUrl: controller.model.cover,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Center(
                              child: Text(
                                'Kapak resmi yüklenemedi.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                  fontFamily: 'MontserratMedium',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        controller.model.sinavAdi,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${controller.model.sinavTuru}  •  ${formatTimestamp(controller.model.timeStamp.toInt())}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Açıklama',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.model.sinavAciklama.isEmpty
                            ? 'Bu sınav için açıklama eklenmemiş.'
                            : controller.model.sinavAciklama,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          height: 1.45,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                      const SizedBox(height: 18),
                      _infoCard(
                        title: 'Sınav Bilgileri',
                        children: [
                          _infoRow(
                            'Sınav Türü',
                            '${controller.model.sinavTuru} Sınavı',
                          ),
                          _infoRow(
                            'Sınav Tarihi ve Saati',
                            formatTimestamp(controller.model.timeStamp.toInt()),
                          ),
                          _infoRow(
                            'Sınav Süresi',
                            '${controller.model.bitisDk} dk',
                          ),
                          Obx(
                            () => _infoRow(
                              'Başvuru',
                              '${controller.basvuranSayisi.value} kişi',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Obx(() => _buildAuthorCard(controller)),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: () => _handlePrimaryAction(controller),
                        child: Obx(
                          () => Container(
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _ctaColor(controller),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _ctaLabel(controller),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                height: 1.5,
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: 'MontserratMedium',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const AdmobKare(
                        key: ValueKey('practice-exam-detail-ad-end'),
                      ),
                    ],
                  ),
                );
              },
            ),
            Obx(
              () => controller.showSucces.value
                  ? _buildSuccessSheet(controller)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
