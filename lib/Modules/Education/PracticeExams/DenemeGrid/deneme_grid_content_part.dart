part of 'deneme_grid.dart';

extension _DenemeGridContentPart on DenemeGrid {
  Widget _buildBody({
    required DenemeGridController controller,
    required SavedPracticeExamsController savedController,
  }) {
    return isListLayout
        ? _buildListCard(controller, savedController)
        : _buildGridCard(controller, savedController);
  }

  Widget _buildMedia({double? width, double? height, double radius = 12}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        color: Colors.indigo.withValues(alpha: 0.08),
        child: model.cover.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: model.cover,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => const Center(
                  child: CupertinoActivityIndicator(color: Colors.black),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.quiz_outlined,
                  color: Colors.indigo,
                  size: 30,
                ),
              )
            : const Center(
                child: Icon(
                  Icons.quiz_outlined,
                  color: Colors.indigo,
                  size: 30,
                ),
              ),
      ),
    );
  }

  Widget _buildGridCard(
    DenemeGridController controller,
    SavedPracticeExamsController savedController,
  ) {
    return PasajGridCard(
      onTap: _openCard,
      media: _buildMedia(radius: 12),
      overlay: Obx(
        () => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _shareExternally,
              child: SizedBox(
                width: PasajListCardMetrics.gridOverlayButtonSize,
                height: PasajListCardMetrics.gridOverlayButtonSize,
                child: Center(
                  child: Icon(
                    AppIcons.share,
                    color: Colors.white,
                    size: PasajListCardMetrics.gridOverlayIconSize,
                    shadows: const [
                      Shadow(
                        color: Color(0x55000000),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: model.docID.trim().isEmpty
                  ? null
                  : () => savedController.toggleSavedExam(model.docID),
              child: SizedBox(
                width: PasajListCardMetrics.gridOverlayButtonSize,
                height: PasajListCardMetrics.gridOverlayButtonSize,
                child: Center(
                  child: Icon(
                    savedController.savedExamIds.contains(model.docID)
                        ? AppIcons.saved
                        : AppIcons.save,
                    color: Colors.white,
                    size: PasajListCardMetrics.gridOverlayIconSize,
                    shadows: const [
                      Shadow(
                        color: Color(0x55000000),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      lines: [
        Text(
          model.sinavAdi,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.lineOne,
        ),
        Text(
          formatTimestamp(model.timeStamp.toInt()),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.gridLineTwo(Colors.indigo),
        ),
        Text(
          model.sinavTuru,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.detail,
        ),
        Row(
          children: [
            Icon(
              CupertinoIcons.person_2_fill,
              size: 13,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _formattedApplicationText(controller.toplamBasvuru.value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PasajCardStyles.gridLineFour(
                  PasajCardStyles.lineFourColor,
                ),
              ),
            ),
          ],
        ),
      ],
      cta: Container(
        height: PasajListCardMetrics.gridCtaHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _ctaColor(controller),
          borderRadius: const BorderRadius.all(
            Radius.circular(PasajListCardMetrics.gridCtaRadius),
          ),
        ),
        child: Text(
          _ctaLabel(controller),
          style: PasajCardStyles.gridCta,
        ),
      ),
    );
  }

  String _formattedApplicationText(int count) {
    final scaled = count * 3;
    String value;
    if (scaled / 1000000 > 1) {
      value = '${(scaled / 1000000).toStringAsFixed(2)}M';
    } else if (scaled / 1000 > 1) {
      value = '${(scaled / 1000).toStringAsFixed(1)}B';
    } else {
      value = '$scaled';
    }
    return '${'practice.application_count'.tr}: $value';
  }

  Color _ctaColor(DenemeGridController controller) {
    if (_isOwner) {
      return Colors.indigo;
    }
    if (controller.currentTime.value <
        controller.examTime.value - controller.fifteenMinutes) {
      return Colors.green;
    }
    if (controller.currentTime.value >=
            controller.examTime.value - controller.fifteenMinutes &&
        controller.currentTime.value < controller.examTime.value) {
      return Colors.purple;
    }
    if (controller.currentTime.value >= controller.examTime.value &&
        controller.currentTime.value < model.bitis) {
      return Colors.black;
    }
    return Colors.pink;
  }

  String _ctaLabel(DenemeGridController controller) {
    if (_isOwner) {
      return 'common.view'.tr;
    }
    if (controller.currentTime.value <
        controller.examTime.value - controller.fifteenMinutes) {
      return 'practice.apply_now'.tr;
    }
    if (controller.currentTime.value >=
            controller.examTime.value - controller.fifteenMinutes &&
        controller.currentTime.value < controller.examTime.value) {
      return 'scholarship.closed'.tr;
    }
    if (controller.currentTime.value >= controller.examTime.value &&
        controller.currentTime.value < model.bitis) {
      return 'practice.started'.tr;
    }
    return 'practice.start_now'.tr;
  }
}
