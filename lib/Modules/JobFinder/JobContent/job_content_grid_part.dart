part of 'job_content.dart';

extension _JobContentGridPart on _JobContentState {
  Widget _buildGridView(JobContentController controller) {
    return PasajGridCard(
      key: ValueKey(IntegrationTestKeys.jobItem(_baseTag)),
      onTap: _openDetails,
      onLongPress: () => controller.reactivateEndedJob(model),
      media: _buildLogo(
        imageUrl: model.logo.trim(),
        width: null,
        height: null,
        borderRadius: const BorderRadius.all(
          Radius.circular(12),
        ),
      ),
      overlay: Obx(
        () => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: model.docID.trim().isEmpty
              ? null
              : () => controller.toggleSave(model.docID),
          child: SizedBox(
            width: PasajListCardMetrics.gridOverlayButtonSize,
            height: PasajListCardMetrics.gridOverlayButtonSize,
            child: Center(
              child: Icon(
                controller.saved.value ? AppIcons.saved : AppIcons.save,
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
                model.ilanBasligi.isNotEmpty ? model.meslek : model.brand,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PasajCardStyles.lineOne,
              ),
            ),
            const SizedBox(width: 6),
            AppHeaderActionButton(
              onTap: () => controller.shareJob(model),
              size: 24,
              radius: 8,
              child: const Icon(
                AppIcons.share,
                color: Colors.black87,
                size: 14,
              ),
            ),
          ],
        ),
        Text(
          model.ilanBasligi.isNotEmpty ? model.ilanBasligi : model.meslek,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.gridLineTwo(PasajCardStyles.lineTwoColor),
        ),
        Text(
          _workTypeText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.detail,
        ),
        Text(
          _cityTownText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.gridLineFour(PasajCardStyles.lineFourColor),
        ),
      ],
      cta: GestureDetector(
        onTap: _openDetails,
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
            'pasaj.market.inspect'.tr,
            style: PasajCardStyles.gridCta,
          ),
        ),
      ),
    );
  }
}
