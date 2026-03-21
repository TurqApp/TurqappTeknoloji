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
import 'package:turqappv2/Core/Widgets/pasaj_grid_card.dart';
import 'package:turqappv2/Core/Widgets/pasaj_list_card_metrics.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyContent/answer_key_content_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class AnswerKeyContent extends StatefulWidget {
  const AnswerKeyContent({
    required this.model,
    required this.onUpdate,
    this.isListLayout = false,
    super.key,
  });

  final BookletModel model;
  final Function(bool) onUpdate;
  final bool isListLayout;

  @override
  State<AnswerKeyContent> createState() => _AnswerKeyContentState();
}

class _AnswerKeyContentState extends State<AnswerKeyContent> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final AnswerKeyContentController controller;

  BookletModel get model => widget.model;
  Function(bool) get onUpdate => widget.onUpdate;
  bool get isListLayout => widget.isListLayout;

  String get _currentUid {
    final serviceUid = CurrentUserService.instance.userId.trim();
    if (serviceUid.isNotEmpty) return serviceUid;
    return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'answer_key_content_${model.docID}_${identityHashCode(this)}';
    _ownsController =
        AnswerKeyContentController.maybeFind(tag: _controllerTag) == null;
    controller = AnswerKeyContentController.ensure(
      model,
      onUpdate,
      tag: _controllerTag,
    );
    controller.syncModel(model);
  }

  @override
  void didUpdateWidget(covariant AnswerKeyContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller.syncModel(model);
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = AnswerKeyContentController.maybeFind(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<AnswerKeyContentController>(tag: _controllerTag);
      }
    }
    super.dispose();
  }

  void _openOwner(BuildContext context, AnswerKeyContentController controller) {
    controller.openBooklet(context);
  }

  String _publisherLine(AnswerKeyContentController controller) {
    final publisher = controller.model.yayinEvi.trim();
    final publishDate = controller.model.basimTarihi.trim();
    if (publisher.isNotEmpty && publishDate.isNotEmpty) {
      return '$publisher • $publishDate';
    }
    if (publisher.isNotEmpty) return publisher;
    if (publishDate.isNotEmpty) return publishDate;
    return 'answer_key.answer_key_label'.tr;
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
    return PasajGridCard(
      onTap: () => _openOwner(context, controller),
      media: _buildMedia(12),
      overlay: _buildGridBookmarkOverlay(controller),
      lines: [
        Text(
          controller.model.baslik,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.lineOne,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                controller.model.sinavTuru,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PasajCardStyles.gridLineTwo(
                  PasajCardStyles.lineTwoColor,
                ),
              ),
            ),
          ],
        ),
        Text(
          _publisherLine(controller),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.detail,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                controller.model.dil.isNotEmpty
                    ? controller.model.dil
                    : controller.model.yayinEvi,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PasajCardStyles.gridLineFour(
                  PasajCardStyles.lineFourColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(
              'assets/icons/statsyeni.svg',
              height: 16,
              colorFilter: const ColorFilter.mode(
                PasajCardStyles.lineFourColor,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              NumberFormatter.format(controller.model.viewCount),
              style: PasajCardStyles.gridLineFour(
                PasajCardStyles.lineFourColor,
              ),
            ),
          ],
        ),
      ],
      cta: _buildPrimaryButton(
        context,
        controller,
        height: PasajListCardMetrics.gridCtaHeight,
        fontSize: PasajListCardMetrics.gridCtaFontSize,
      ),
    );
  }

  Widget _buildGridBookmarkOverlay(AnswerKeyContentController controller) {
    return Obx(
      () => GestureDetector(
        onTap: controller.toggleBookmark,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: PasajListCardMetrics.gridOverlayButtonSize,
          height: PasajListCardMetrics.gridOverlayButtonSize,
          child: Center(
            child: Icon(
              controller.isBookmarked.value
                  ? CupertinoIcons.bookmark_fill
                  : CupertinoIcons.bookmark,
              color: Colors.white,
              size: PasajListCardMetrics.gridOverlayIconSize,
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
    );
  }

  Widget _buildListBookmarkAction(
    AnswerKeyContentController controller,
    PasajListCardMetrics metrics,
  ) {
    return Obx(
      () => AppHeaderActionButton(
        onTap: controller.toggleBookmark,
        size: metrics.actionButtonSize,
        child: Icon(
          controller.isBookmarked.value
              ? CupertinoIcons.bookmark_fill
              : CupertinoIcons.bookmark,
          color: controller.isBookmarked.value ? Colors.orange : Colors.black87,
          size: metrics.actionIconSize,
        ),
      ),
    );
  }

  Widget _buildListCard(
    BuildContext context,
    AnswerKeyContentController controller,
  ) {
    const metrics = PasajListCardMetrics.regular;
    final canShareFeed = AdminAccessService.isKnownAdminSync() ||
        controller.model.userID == _currentUid;
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
                            _publisherLine(controller),
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
                        _buildListBookmarkAction(controller, metrics),
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
    return isListLayout
        ? _buildListCard(context, controller)
        : _buildGridCard(context, controller);
  }
}
