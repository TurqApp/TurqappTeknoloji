import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';

class AdsCreativeReviewView extends StatelessWidget {
  const AdsCreativeReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdsCenterController>();

    return Obx(() {
      final list = controller.creatives;
      if (list.isEmpty) {
        return const Center(
          child: Text(
            'Kreatif bulunamadı.',
            style: TextStyle(fontFamily: 'MontserratMedium'),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final c = list[index];
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.headline.isEmpty ? '(başlıksız kreatif)' : c.headline,
                    style: const TextStyle(
                      fontFamily: 'MontserratBold',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Type: ${c.type.name} • Moderation: ${c.moderationStatus.name}',
                    style: const TextStyle(
                        fontFamily: 'MontserratMedium', fontSize: 12),
                  ),
                  Text(
                    'Campaign: ${c.campaignId} • Duration: ${c.durationSec}s',
                    style: const TextStyle(
                        fontFamily: 'MontserratMedium', fontSize: 12),
                  ),
                  if (c.mediaURL.isNotEmpty)
                    Text(
                      'Media: ${c.mediaURL}',
                      style: const TextStyle(
                          fontFamily: 'MontserratMedium', fontSize: 12),
                    ),
                  if (c.hlsMasterURL.isNotEmpty)
                    Text(
                      'HLS: ${c.hlsMasterURL}',
                      style: const TextStyle(
                          fontFamily: 'MontserratMedium', fontSize: 12),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final note =
                                await _askNote(context, title: 'Reject Notu');
                            if (note == null) return;
                            await controller.reviewCreative(
                              creativeId: c.id,
                              status: AdModerationStatus.rejected,
                              note: note,
                            );
                          },
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final note =
                                await _askNote(context, title: 'Approve Notu');
                            if (note == null) return;
                            await controller.reviewCreative(
                              creativeId: c.id,
                              status: AdModerationStatus.approved,
                              note: note,
                            );
                          },
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Future<String?> _askNote(BuildContext context,
      {required String title}) async {
    final c = TextEditingController();
    final out = await showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: c,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Review notu'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal')),
            TextButton(
                onPressed: () => Navigator.pop(context, c.text.trim()),
                child: const Text('Kaydet')),
          ],
        );
      },
    );
    c.dispose();
    return out;
  }
}
