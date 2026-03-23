import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'ads_preview_screen_lifecycle_part.dart';
part 'ads_preview_screen_content_part.dart';
part 'ads_preview_screen_result_part.dart';
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
    _initLifecycle();
  }

  @override
  void dispose() {
    _disposeLifecycle();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);

  void _updateViewState(VoidCallback updater) {
    if (!mounted) return;
    setState(updater);
  }
}
