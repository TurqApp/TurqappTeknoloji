part of 'tutoring_widget_builder.dart';

extension _TutoringWidgetBuilderListPart on TutoringWidgetBuilder {
  Widget _buildListLayout({
    required String? currentUserId,
    required SavedTutoringsController savedController,
    required TutoringController tutoringController,
    required MyTutoringsController? myTutoringsController,
  }) {
    return Column(
      children: PasajListingAdLayout.buildListChildren(
        items: tutoringList,
        itemBuilder: (tutoring, index) {
          final lessonPlace = _lessonPlaceText(tutoring);
          final imageUrl = _imageUrl(tutoring);
          const metrics = PasajListCardMetrics.regular;
          return Padding(
            padding:
                const EdgeInsets.only(left: 15, right: 15, bottom: 6, top: 6),
            child: GestureDetector(
              onTap: () => _openTutoringDetail(
                tutoring,
                myTutoringsController: myTutoringsController,
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.grey.withValues(alpha: 0.18)),
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
                        child: imageUrl.isNotEmpty
                            ? CacheFirstNetworkImage(
                                imageUrl: imageUrl,
                                cacheManager: TurqImageCacheManager.instance,
                                fit: BoxFit.cover,
                                memCacheWidth: (metrics.mediaSize * 2).round(),
                                memCacheHeight:
                                    (metrics.railHeight * 2).round(),
                                fallback: _fallbackImage(),
                              )
                            : _fallbackImage(),
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
                                  tutoring.baslik,
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
                                  tutoring.brans,
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
                                  lessonPlace,
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
                                  _cityDistrictText(tutoring),
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
                                onTap: () => _shareExternally(tutoring),
                                size: metrics.actionButtonSize,
                                radius: 6,
                                child: Icon(
                                  AppIcons.share,
                                  size: metrics.actionIconSize,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(width: metrics.railActionGap),
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
                                  size: metrics.actionButtonSize,
                                  radius: 6,
                                  child: Icon(
                                    isSaved ? AppIcons.saved : AppIcons.save,
                                    size: metrics.actionIconSize,
                                    color: isSaved
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
                              onTap: () => _openTutoringDetail(
                                tutoring,
                                myTutoringsController: myTutoringsController,
                              ),
                              child: Container(
                                height: metrics.ctaHeight,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                ),
                                child: Text(
                                  allowReactivate && tutoring.ended == true
                                      ? 'admin.reports.restore'.tr
                                      : 'common.view'.tr,
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
          );
        },
        adBuilder: (slot) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: AdmobKare(
            key: ValueKey('tutoring-list-ad-$slot'),
            suggestionPlacementId: 'tutoring',
          ),
        ),
      ),
    );
  }
}
