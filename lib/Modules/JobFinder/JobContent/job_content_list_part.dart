part of 'job_content.dart';

extension _JobContentListPart on _JobContentState {
  Widget _buildListingView(JobContentController controller) {
    const metrics = PasajListCardMetrics.regular;
    return GestureDetector(
      key: ValueKey(IntegrationTestKeys.jobItem(_baseTag)),
      onLongPress: () => controller.reactivateEndedJob(model),
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 6, top: 6),
        child: GestureDetector(
          onTap: _openDetails,
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
                    width: metrics.mediaSize,
                    height: metrics.railHeight,
                    child: _buildLogo(
                      imageUrl: model.logo.trim(),
                      width: metrics.mediaSize,
                      height: metrics.railHeight,
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                              model.ilanBasligi.isNotEmpty
                                  ? model.meslek
                                  : model.brand,
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
                              model.ilanBasligi.isNotEmpty
                                  ? model.ilanBasligi
                                  : model.meslek,
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
                              _workTypeText,
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
                            child: Text(
                              _cityTownText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PasajCardStyles.lineFour,
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
                          AppHeaderActionButton(
                            onTap: () => controller.shareJob(model),
                            size: metrics.actionButtonSize,
                            child: Icon(
                              AppIcons.share,
                              size: metrics.actionIconSize,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(width: metrics.railActionGap),
                          Obx(() {
                            return AppHeaderActionButton(
                              onTap: model.docID.trim().isEmpty
                                  ? null
                                  : () => controller.toggleSave(model.docID),
                              size: metrics.actionButtonSize,
                              child: Icon(
                                controller.saved.value
                                    ? AppIcons.saved
                                    : AppIcons.save,
                                size: metrics.actionIconSize,
                                color: controller.saved.value
                                    ? Colors.orange
                                    : Colors.black87,
                              ),
                            );
                          }),
                        ],
                      ),
                      SizedBox(height: metrics.railSectionGap),
                      SizedBox(height: metrics.middleSlotHeight),
                      const Spacer(),
                      SizedBox(
                        width: metrics.railWidth,
                        child: GestureDetector(
                          onTap: _openDetails,
                          child: Container(
                            height: metrics.ctaHeight,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                            ),
                            child: Text(
                              'pasaj.market.inspect'.tr,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: metrics.ctaFontSize,
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
      ),
    );
  }
}
