import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class AdsPreviewScreen extends StatefulWidget {
  const AdsPreviewScreen({super.key});

  @override
  State<AdsPreviewScreen> createState() => _AdsPreviewScreenState();
}

class _AdsPreviewScreenState extends State<AdsPreviewScreen> {
  late final AdsCenterController _controller;
  final _country = TextEditingController(text: 'TR');
  final _city = TextEditingController(text: 'Istanbul');
  final _age = TextEditingController(text: '28');
  final _userId = TextEditingController();
  AdPlacementType _placement = AdPlacementType.feed;

  String get _currentUid {
    final serviceUid = CurrentUserService.instance.userId.trim();
    if (serviceUid.isNotEmpty) return serviceUid;
    return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AdsCenterController>();
    _userId.text = _currentUid;
  }

  @override
  void dispose() {
    _country.dispose();
    _city.dispose();
    _age.dispose();
    _userId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text(
          'ads_center.delivery_simulation'.tr,
          style: TextStyle(fontFamily: 'MontserratBold', fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(controller: _userId, decoration: _d('ads_center.user_id'.tr)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: TextField(
                    controller: _country,
                    decoration: _d('ads_center.country'.tr))),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    controller: _city, decoration: _d('ads_center.city'.tr))),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    controller: _age, decoration: _d('ads_center.age'.tr))),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<AdPlacementType>(
          initialValue: _placement,
          decoration: _d('ads_center.placement'.tr),
          items: AdPlacementType.values
              .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
              .toList(growable: false),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _placement = v;
              });
            }
          },
        ),
        const SizedBox(height: 12),
        Obx(() {
          return ElevatedButton.icon(
            onPressed: _controller.previewLoading.value
                ? null
                : () async {
                    await _controller.runPreview(
                      placement: _placement,
                      country: _country.text.trim(),
                      city: _city.text.trim(),
                      age: int.tryParse(_age.text.trim()),
                      userId: _userId.text.trim(),
                    );
                  },
            icon: _controller.previewLoading.value
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text('ads_center.run_simulation'.tr),
          );
        }),
        const SizedBox(height: 16),
        Obx(() {
          final result = _controller.previewResult.value;
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.hasAd
                      ? 'ads_center.eligible_ad_found'.tr
                      : 'ads_center.no_eligible_ad'.tr,
                  style: const TextStyle(
                      fontFamily: 'MontserratBold', fontSize: 14),
                ),
                const SizedBox(height: 6),
                if (result.message.isNotEmpty)
                  Text(
                    result.message,
                    style: const TextStyle(
                        fontFamily: 'MontserratMedium', fontSize: 12),
                  ),
                if (result.campaign != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${'ads_center.campaign'.tr}: ${result.campaign!.name} (${result.campaign!.id})',
                    style: const TextStyle(
                        fontFamily: 'MontserratMedium', fontSize: 12),
                  ),
                ],
                if (result.creative != null)
                  Text(
                    '${'ads_center.creative'.tr}: ${result.creative!.headline} (${result.creative!.id})',
                    style: const TextStyle(
                        fontFamily: 'MontserratMedium', fontSize: 12),
                  ),
                if (result.decisions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'ads_center.reasons'.tr,
                    style:
                        TextStyle(fontFamily: 'MontserratBold', fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  ...result.decisions.map((d) {
                    final reasons = d.reasons.isEmpty
                        ? 'common.ok'.tr
                        : d.reasons.map((e) => e.name).join(', ');
                    return Text(
                      '${d.campaignId}: $reasons',
                      style: const TextStyle(
                        fontFamily: 'MontserratMedium',
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    );
                  }),
                ]
              ],
            ),
          );
        }),
      ],
    );
  }

  InputDecoration _d(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
