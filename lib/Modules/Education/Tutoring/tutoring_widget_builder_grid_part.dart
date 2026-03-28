part of 'tutoring_widget_builder.dart';

extension _TutoringWidgetBuilderGridPart on TutoringWidgetBuilder {
  Widget _buildGridLayout({
    required String? currentUserId,
    required SavedTutoringsController savedController,
    required TutoringController tutoringController,
    required MyTutoringsController? myTutoringsController,
  }) {
    return Column(
      children: PasajListingAdLayout.buildTwoColumnGridChildren(
        items: tutoringList,
        horizontalSpacing: 8,
        rowSpacing: 8,
        itemBuilder: (tutoring, index) {
          final lessonPlace = _lessonPlaceText(tutoring);
          final imageUrl = _imageUrl(tutoring);
          return PasajGridCard(
            onTap: () => _openTutoringDetail(
              tutoring,
              myTutoringsController: myTutoringsController,
            ),
            media: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _fallbackImage(),
                    )
                  : _fallbackImage(),
            ),
            overlay: Obx(
              () => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _toggleSave(
                  tutoring: tutoring,
                  currentUserId: currentUserId,
                  controller: tutoringController,
                  savedController: savedController,
                ),
                child: SizedBox(
                  width: PasajListCardMetrics.gridOverlayButtonSize,
                  height: PasajListCardMetrics.gridOverlayButtonSize,
                  child: Center(
                    child: Icon(
                      savedController.savedTutoringIds.contains(tutoring.docID)
                          ? AppIcons.saved
                          : AppIcons.save,
                      size: PasajListCardMetrics.gridOverlayIconSize,
                      color: Colors.white,
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
            ),
            lines: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      tutoring.baslik,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PasajCardStyles.lineOne,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AppHeaderActionButton(
                    onTap: () => _shareExternally(tutoring),
                    size: 24,
                    radius: 8,
                    child: const Icon(
                      AppIcons.share,
                      color: Colors.black87,
                      size: 16,
                    ),
                  ),
                ],
              ),
              Text(
                tutoring.brans,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PasajCardStyles.gridLineTwo(
                  PasajCardStyles.lineTwoColor,
                ),
              ),
              Text(
                lessonPlace,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PasajCardStyles.detail,
              ),
              Text(
                _cityDistrictText(tutoring),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: PasajCardStyles.gridLineFour(
                  PasajCardStyles.lineFourColor,
                ),
              ),
            ],
            cta: GestureDetector(
              onTap: () => _openTutoringDetail(
                tutoring,
                myTutoringsController: myTutoringsController,
              ),
              child: Container(
                height: PasajListCardMetrics.gridCtaHeight,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.all(
                    Radius.circular(PasajListCardMetrics.gridCtaRadius),
                  ),
                ),
                child: Text(
                  allowReactivate && tutoring.ended == true
                      ? 'admin.reports.restore'.tr
                      : 'common.view'.tr,
                  style: PasajCardStyles.gridCta,
                ),
              ),
            ),
          );
        },
        adBuilder: (slot) => AdmobKare(
          key: ValueKey('tutoring-grid-ad-$slot'),
          suggestionPlacementId: 'tutoring',
        ),
      ),
    );
  }
}
