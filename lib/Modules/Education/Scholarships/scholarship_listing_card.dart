import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/pasaj_card_styles.dart';
import 'package:turqappv2/Core/Widgets/pasaj_list_card_metrics.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Themes/app_icons.dart';

class ScholarshipListingCard extends StatelessWidget {
  const ScholarshipListingCard({
    super.key,
    required this.scholarshipData,
    required this.isSaved,
    required this.onOpen,
    required this.onToggleSaved,
    required this.onShare,
  });

  final Map<String, dynamic> scholarshipData;
  final bool isSaved;
  final Future<void> Function() onOpen;
  final Future<void> Function() onToggleSaved;
  final Future<void> Function() onShare;

  static const TextStyle _titleStyle = PasajCardStyles.lineOne;
  static const TextStyle _descriptionStyle = PasajCardStyles.lineTwo;
  static const TextStyle _deadlineStyle = PasajCardStyles.detail;

  @override
  Widget build(BuildContext context) {
    final burs = scholarshipData['model'] as IndividualScholarshipsModel;
    final logoUrl = burs.img.trim().isNotEmpty
        ? burs.img.trim()
        : (burs.img2.trim().isNotEmpty ? burs.img2.trim() : burs.logo.trim());
    final description = burs.shortDescription.trim().isNotEmpty
        ? burs.shortDescription.trim()
        : burs.aciklama.trim();
    final deadlineLabel = burs.bitisTarihi.trim().isNotEmpty
        ? 'education_feed.application_deadline'
            .trParams({'date': burs.bitisTarihi.trim()})
        : '';
    final audience = burs.sehirler.isNotEmpty
        ? burs.sehirler.take(2).join(', ')
        : (burs.universiteler.isNotEmpty
            ? burs.universiteler.take(2).join(', ')
            : burs.egitimKitlesi.trim());

    return GestureDetector(
      onTap: () async => onOpen(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
            color: Colors.white,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final metrics = PasajListCardMetrics.forWidth(
                constraints.maxWidth,
              );
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScholarshipListLogo(
                    imageUrl: logoUrl,
                    width: metrics.mediaSize,
                    height: metrics.mediaSize,
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
                                burs.baslik,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _titleStyle,
                              ),
                            ),
                          ),
                          SizedBox(height: metrics.contentGap),
                          SizedBox(
                            height: metrics.detailRowHeight,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: description.isNotEmpty
                                  ? Text(
                                      description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _descriptionStyle,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                          SizedBox(height: metrics.contentGap),
                          SizedBox(
                            height: metrics.detailRowHeight,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: deadlineLabel.isNotEmpty
                                  ? Text(
                                      deadlineLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _deadlineStyle,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                          SizedBox(height: metrics.contentGap),
                          SizedBox(
                            height: metrics.ctaHeight,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                audience.isNotEmpty
                                    ? audience
                                    : 'scholarship.target_audience_label'.tr,
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
                            AppHeaderActionButton(
                              onTap: () async => onShare(),
                              size: metrics.actionButtonSize,
                              child: Icon(
                                AppIcons.share,
                                color: Colors.black.withValues(alpha: 0.85),
                                size: metrics.actionIconSize,
                              ),
                            ),
                            const SizedBox(width: 6),
                            AppHeaderActionButton(
                              onTap: () async => onToggleSaved(),
                              size: metrics.actionButtonSize,
                              child: Icon(
                                isSaved
                                    ? CupertinoIcons.bookmark_fill
                                    : CupertinoIcons.bookmark,
                                color: isSaved
                                    ? Colors.orange
                                    : Colors.grey.shade600,
                                size: metrics.actionIconSize,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: metrics.railSectionGap),
                        SizedBox(height: metrics.middleSlotHeight),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async => onOpen(),
                          child: Container(
                            constraints: BoxConstraints(
                              minWidth: metrics.railWidth,
                            ),
                            height: metrics.ctaHeight,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
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
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ScholarshipListLogo extends StatelessWidget {
  const _ScholarshipListLogo({
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  final String imageUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clean = imageUrl.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFFF8F8F8),
        child: clean.isEmpty
            ? const Icon(
                CupertinoIcons.building_2_fill,
                color: Colors.grey,
              )
            : CachedNetworkImage(
                imageUrl: clean,
                width: width,
                height: height,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CupertinoActivityIndicator(),
                ),
                errorWidget: (_, __, ___) => const Icon(
                  CupertinoIcons.building_2_fill,
                  color: Colors.grey,
                ),
              ),
      ),
    );
  }
}
