part of 'deneme_grid.dart';

extension _DenemeGridListPart on DenemeGrid {
  Widget _buildListCard(
    DenemeGridController controller,
    SavedPracticeExamsController savedController,
  ) {
    const metrics = PasajListCardMetrics.regular;
    return GestureDetector(
      onTap: _openCard,
      child: Semantics(
        label: IntegrationTestKeys.practiceExamOpen(model.docID),
        button: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            key: ValueKey(
              IntegrationTestKeys.practiceExamOpen(model.docID),
            ),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
              color: Colors.white,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMedia(
                  width: metrics.mediaSize,
                  height: metrics.mediaSize,
                  radius: 10,
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
                              model.sinavAdi,
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
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.calendar,
                                  size: 14,
                                  color: PasajCardStyles.lineTwoColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    formatTimestamp(model.timeStamp.toInt()),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: PasajCardStyles.lineTwo,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: metrics.contentGap),
                        SizedBox(
                          height: metrics.detailRowHeight,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.doc_text,
                                  size: 14,
                                  color: PasajCardStyles.lineFourColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    model.sinavTuru,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: PasajCardStyles.detail,
                                  ),
                                ),
                              ],
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
                                Icon(
                                  CupertinoIcons.person_2_fill,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _formattedApplicationText(
                                      controller.toplamBasvuru.value,
                                    ),
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
                const SizedBox(width: 8),
                SizedBox(
                  width: metrics.railWidth,
                  height: metrics.railHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          EducationShareIconButton(
                            onTap: _shareExternally,
                            size: metrics.actionButtonSize,
                            iconSize: metrics.actionIconSize,
                          ),
                          SizedBox(width: metrics.railActionGap),
                          Obx(
                            () => AppHeaderActionButton(
                              onTap: model.docID.trim().isEmpty
                                  ? null
                                  : () => savedController.toggleSavedExam(
                                        model.docID,
                                      ),
                              size: metrics.actionButtonSize,
                              child: Icon(
                                savedController.savedExamIds.contains(
                                  model.docID,
                                )
                                    ? AppIcons.saved
                                    : AppIcons.save,
                                size: metrics.actionIconSize,
                                color: savedController.savedExamIds.contains(
                                  model.docID,
                                )
                                    ? Colors.orange
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: metrics.railSectionGap),
                      SizedBox(height: metrics.middleSlotHeight),
                      const Spacer(),
                      SizedBox(
                        width: metrics.railWidth,
                        child: Semantics(
                          label: IntegrationTestKeys.practiceExamCta(
                            model.docID,
                          ),
                          button: true,
                          child: Container(
                            key: ValueKey(
                              IntegrationTestKeys.practiceExamCta(model.docID),
                            ),
                            height: metrics.ctaHeight,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _ctaColor(controller),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _ctaLabel(controller),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: metrics.ctaFontSize,
                                  fontFamily: 'MontserratMedium',
                                ),
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
