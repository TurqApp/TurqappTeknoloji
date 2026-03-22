part of 'answer_key_content.dart';

extension AnswerKeyContentListPart on _AnswerKeyContentState {
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
}
