import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg_flutter.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/education_share_icon_button.dart';
import 'package:turqappv2/Core/Widgets/pasaj_card_styles.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/Widgets/pasaj_list_card_metrics.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyContent/answer_key_content_controller.dart';

class AnswerKeyContent extends StatelessWidget {
  const AnswerKeyContent({
    required this.model,
    required this.onUpdate,
    this.isListLayout = false,
    super.key,
  });

  final BookletModel model;
  final Function(bool) onUpdate;
  final bool isListLayout;

  void _openOwner(BuildContext context, AnswerKeyContentController controller) {
    controller.openBooklet(context);
  }

  Widget _buildMedia(double radius) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        color: Colors.orange.withValues(alpha: 0.08),
        child: CachedNetworkImage(
          imageUrl: model.cover,
          key: ValueKey(model.cover),
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => const Center(
            child: Icon(
              Icons.menu_book_rounded,
              color: Colors.indigo,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(
    BuildContext context,
    AnswerKeyContentController controller, {
    double height = 30,
    double fontSize = 15,
  }) {
    return GestureDetector(
      onTap: () => controller.openBooklet(context),
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: Text(
          'answer_key.inspect'.tr,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontFamily: 'MontserratMedium',
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(
    BuildContext context,
    AnswerKeyContentController controller,
  ) {
    const metrics = PasajListCardMetrics.regular;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final canShareFeed = AdminAccessService.isKnownAdminSync() ||
        controller.model.userID == currentUid;
    return GestureDetector(
      onTap: () => _openOwner(context, controller),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: PasajListCardMetrics.gridMediaAspectRatio,
              child: Stack(
                children: [
                  Positioned.fill(child: _buildMedia(12)),
                  Positioned(
                    top: PasajListCardMetrics.gridOverlayInset,
                    right: PasajListCardMetrics.gridOverlayInset,
                    child: Column(
                      children: [
                        if (canShareFeed)
                          EducationShareIconButton(
                            onTap: controller.shareBooklet,
                            size: PasajListCardMetrics.gridOverlayButtonSize,
                            iconSize: PasajListCardMetrics.gridOverlayIconSize,
                          ),
                        if (canShareFeed) const SizedBox(height: 6),
                        AppHeaderActionButton(
                          onTap: controller.toggleBookmark,
                          size: PasajListCardMetrics.gridOverlayButtonSize,
                          child: Icon(
                            controller.isBookmarked.value
                                ? CupertinoIcons.bookmark_fill
                                : CupertinoIcons.bookmark,
                            color: controller.isBookmarked.value
                                ? Colors.orange
                                : Colors.black87,
                            size: PasajListCardMetrics.gridOverlayIconSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.model.baslik,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          controller.model.sinavTuru,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PasajCardStyles.detail,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        controller.model.basimTarihi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PasajCardStyles.detail,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.model.yayinEvi.trim().isNotEmpty
                        ? controller.model.yayinEvi.trim()
                        : 'answer_key.answer_key_label'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PasajCardStyles.detail,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          controller.model.dil.isNotEmpty
                              ? controller.model.dil
                              : controller.model.yayinEvi,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PasajCardStyles.detail,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SvgPicture.asset(
                        'assets/icons/statsyeni.svg',
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          Colors.black,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        NumberFormatter.format(controller.model.viewCount),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: metrics.railWidth,
                      child: _buildPrimaryButton(
                        context,
                        controller,
                        height: metrics.ctaHeight,
                        fontSize: metrics.ctaFontSize,
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
  }

  Widget _buildListCard(
    BuildContext context,
    AnswerKeyContentController controller,
  ) {
    const metrics = PasajListCardMetrics.regular;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final canShareFeed = AdminAccessService.isKnownAdminSync() ||
        controller.model.userID == currentUid;
    return GestureDetector(
      onTap: () => _openOwner(context, controller),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
            color: Colors.white,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: metrics.mediaSize,
                height: metrics.mediaSize,
                child: _buildMedia(10),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: metrics.railHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: metrics.detailRowHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            controller.model.baslik,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PasajCardStyles.lineOne,
                          ),
                        ),
                      ),
                      SizedBox(height: metrics.contentGap),
                      SizedBox(
                        height: metrics.detailRowHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            controller.model.sinavTuru,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PasajCardStyles.lineTwo,
                          ),
                        ),
                      ),
                      SizedBox(height: metrics.contentGap),
                      SizedBox(
                        height: metrics.detailRowHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            controller.model.yayinEvi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PasajCardStyles.detail,
                          ),
                        ),
                      ),
                      SizedBox(height: metrics.contentGap),
                      SizedBox(
                        height: metrics.ctaHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/statsyeni.svg',
                                height: 14,
                                colorFilter: const ColorFilter.mode(
                                  PasajCardStyles.lineFourColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'answer_key.views'.trParams({
                                    'count': NumberFormatter.format(
                                      controller.model.viewCount,
                                    ),
                                  }),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PasajCardStyles.lineFour,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: metrics.railWidth,
                height: metrics.railHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canShareFeed) ...[
                          EducationShareIconButton(
                            onTap: controller.shareBooklet,
                            size: metrics.actionButtonSize,
                            iconSize: metrics.actionIconSize,
                          ),
                          SizedBox(width: metrics.railActionGap),
                        ],
                        AppHeaderActionButton(
                          onTap: controller.toggleBookmark,
                          size: metrics.actionButtonSize,
                          child: Icon(
                            controller.isBookmarked.value
                                ? CupertinoIcons.bookmark_fill
                                : CupertinoIcons.bookmark,
                            color: controller.isBookmarked.value
                                ? Colors.orange
                                : Colors.black87,
                            size: metrics.actionIconSize,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: metrics.railSectionGap),
                    SizedBox(height: metrics.middleSlotHeight),
                    const Spacer(),
                    SizedBox(
                      width: metrics.railWidth,
                      child: _buildPrimaryButton(
                        context,
                        controller,
                        height: metrics.ctaHeight,
                        fontSize: metrics.ctaFontSize,
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
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      AnswerKeyContentController(model, onUpdate),
      tag: model.docID,
    );
    controller.syncModel(model);

    return Obx(
      () => isListLayout
          ? _buildListCard(context, controller)
          : _buildGridCard(context, controller),
    );
  }
}
