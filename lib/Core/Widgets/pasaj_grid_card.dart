import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Widgets/pasaj_list_card_metrics.dart';

class PasajGridCard extends StatelessWidget {
  const PasajGridCard({
    super.key,
    required this.media,
    required this.lines,
    required this.cta,
    this.onTap,
    this.onLongPress,
    this.overlay,
  }) : assert(lines.length == 4, 'PasajGridCard requires exactly 4 lines.');

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget media;
  final Widget? overlay;
  final List<Widget> lines;
  final Widget cta;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(PasajListCardMetrics.gridRadius),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(
              Radius.circular(PasajListCardMetrics.gridRadius),
            ),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: PasajListCardMetrics.gridMediaAspectRatio,
                child: Stack(
                  children: [
                    Positioned.fill(child: media),
                    if (overlay != null)
                      Positioned(
                        top: PasajListCardMetrics.gridOverlayInset,
                        right: PasajListCardMetrics.gridOverlayInset,
                        child: overlay!,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PasajListCardMetrics.gridContentHorizontalPadding,
                  PasajListCardMetrics.gridContentTopPadding,
                  PasajListCardMetrics.gridContentHorizontalPadding,
                  PasajListCardMetrics.gridContentBottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    lines[0],
                    const SizedBox(height: PasajListCardMetrics.gridLineGap),
                    lines[1],
                    const SizedBox(height: PasajListCardMetrics.gridLineGap),
                    lines[2],
                    const SizedBox(height: PasajListCardMetrics.gridLineGap),
                    lines[3],
                    const SizedBox(height: PasajListCardMetrics.gridCtaTopGap),
                    SizedBox(
                      width: double.infinity,
                      child: cta,
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
