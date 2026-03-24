import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'ads_preview_screen_form_part.dart';

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

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  @override
  void initState() {
    super.initState();
    _controller = AdsCenterController.ensure();
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

  Widget _buildPage(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text(
          'ads_center.delivery_simulation'.tr,
          style: const TextStyle(fontFamily: 'MontserratBold', fontSize: 16),
        ),
        const SizedBox(height: 8),
        _buildPreviewForm(),
        const SizedBox(height: 16),
        Obx(_buildPreviewResult),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);

  void _updateViewState(VoidCallback updater) {
    if (!mounted) return;
    setState(updater);
  }
}
