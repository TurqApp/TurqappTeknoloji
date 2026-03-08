import 'package:flutter/material.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';

class AdRenderer extends StatelessWidget {
  const AdRenderer({
    super.key,
    required this.slot,
    this.title = 'Sponsorlu',
  });

  final AdSlot slot;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (!slot.enabled) {
      return const SizedBox.shrink();
    }

    // Public rollout kapalıyken burada görünmez; açıldığında placement bazlı
    // gerçek creative render bu bileşene bağlanacak.
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_outlined, size: 18),
          const SizedBox(width: 8),
          Text(
            '$title • ${slot.placement.name.toUpperCase()}',
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
