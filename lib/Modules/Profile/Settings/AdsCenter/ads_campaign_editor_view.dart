import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'ads_campaign_editor_view_actions_part.dart';
part 'ads_campaign_editor_view_creative_part.dart';
part 'ads_campaign_editor_view_content_part.dart';
part 'ads_campaign_editor_view_form_part.dart';
part 'ads_campaign_editor_view_sections_part.dart';
part 'ads_campaign_editor_view_targeting_part.dart';
part 'ads_campaign_editor_view_lifecycle_part.dart';

class AdsCampaignEditorView extends StatefulWidget {
  const AdsCampaignEditorView({super.key, this.initialCampaign});

  final AdCampaign? initialCampaign;

  @override
  State<AdsCampaignEditorView> createState() => _AdsCampaignEditorViewState();
}

class _AdsCampaignEditorViewState extends State<AdsCampaignEditorView> {
  late final AdsCenterController _controller;

  late final TextEditingController _name;
  late final TextEditingController _totalBudget;
  late final TextEditingController _dailyBudget;
  late final TextEditingController _bidAmount;
  late final TextEditingController _priority;
  late final TextEditingController _minAge;
  late final TextEditingController _maxAge;
  late final TextEditingController _countries;
  late final TextEditingController _cities;
  late final TextEditingController _appVersions;
  late final TextEditingController _ctaText;
  late final TextEditingController _destinationUrl;
  late final TextEditingController _creativeMediaUrl;
  late final TextEditingController _creativeHlsUrl;
  late final TextEditingController _creativeThumbUrl;
  late final TextEditingController _creativeHeadline;
  late final TextEditingController _creativeBody;
  late final TextEditingController _creativeDuration;
  late final TextEditingController _creativeStoragePath;

  AdCampaignStatus _status = AdCampaignStatus.draft;

  String _formatDate(DateTime date) {
    final localeTag = Get.locale?.toLanguageTag();
    return DateFormat.yMd(localeTag).format(date);
  }

  AdBudgetType _budgetType = AdBudgetType.daily;
  AdBidType _bidType = AdBidType.cpm;
  AdCreativeType _creativeType = AdCreativeType.image;
  final Set<AdPlacementType> _placements = {AdPlacementType.feed};
  String _advertiserId = '';
  bool _isTestCampaign = true;
  bool _deliveryEnabled = false;
  DateTime _startAt = DateTime.now();
  DateTime _endAt = DateTime.now().add(const Duration(days: 7));

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

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  void _updateViewState(VoidCallback updater) {
    if (!mounted) return;
    setState(updater);
  }
}
