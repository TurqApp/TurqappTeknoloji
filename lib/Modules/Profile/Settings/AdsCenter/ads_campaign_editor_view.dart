import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'ads_campaign_editor_view_creative_part.dart';
part 'ads_campaign_editor_view_form_part.dart';
part 'ads_campaign_editor_view_sections_part.dart';

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
  bool _showAdvanced = false;
  bool _isTestCampaign = true;
  bool _deliveryEnabled = false;
  DateTime _startAt = DateTime.now();
  DateTime _endAt = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _controller = ensureAdsCenterController();

    final campaign = widget.initialCampaign;
    _name = TextEditingController(text: campaign?.name ?? '');
    _totalBudget =
        TextEditingController(text: (campaign?.totalBudget ?? 0).toString());
    _dailyBudget =
        TextEditingController(text: (campaign?.dailyBudget ?? 0).toString());
    _bidAmount =
        TextEditingController(text: (campaign?.bidAmount ?? 0).toString());
    _priority =
        TextEditingController(text: (campaign?.priority ?? 0).toString());
    _minAge = TextEditingController(
      text: campaign?.targeting.minAge?.toString() ?? '',
    );
    _maxAge = TextEditingController(
      text: campaign?.targeting.maxAge?.toString() ?? '',
    );
    _countries = TextEditingController(
      text: campaign?.targeting.countries.join(',') ?? '',
    );
    _cities = TextEditingController(
      text: campaign?.targeting.cities.join(',') ?? '',
    );
    _appVersions = TextEditingController(
      text: campaign?.targeting.appVersions.join(',') ?? '',
    );
    _ctaText = TextEditingController();
    _destinationUrl = TextEditingController();
    _creativeMediaUrl = TextEditingController();
    _creativeHlsUrl = TextEditingController();
    _creativeThumbUrl = TextEditingController();
    _creativeHeadline = TextEditingController();
    _creativeBody = TextEditingController();
    _creativeDuration = TextEditingController();
    _creativeStoragePath = TextEditingController();

    _status = campaign?.status ?? AdCampaignStatus.draft;
    _budgetType = campaign?.budgetType ?? AdBudgetType.daily;
    _bidType = campaign?.bidType ?? AdBidType.cpm;
    _placements
      ..clear()
      ..addAll(campaign?.placementTypes ?? const [AdPlacementType.feed]);
    _advertiserId = campaign?.advertiserId ?? '';
    _isTestCampaign = campaign?.isTestCampaign ?? true;
    _deliveryEnabled = campaign?.deliveryEnabled ?? false;
    _startAt = campaign?.startAt ?? DateTime.now();
    _endAt = campaign?.endAt ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _totalBudget,
      _dailyBudget,
      _bidAmount,
      _priority,
      _minAge,
      _maxAge,
      _countries,
      _cities,
      _appVersions,
      _ctaText,
      _destinationUrl,
      _creativeMediaUrl,
      _creativeHlsUrl,
      _creativeThumbUrl,
      _creativeHeadline,
      _creativeBody,
      _creativeDuration,
      _creativeStoragePath,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _buildCampaignSection(),
            _buildCreativeSection(),
            _buildBudgetSection(),
            _buildAdvancedSection(),
            _buildSubmitActions(),
            const SizedBox(height: 28),
          ],
        ),
      );

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  void _updateViewState(VoidCallback updater) {
    if (!mounted) return;
    setState(updater);
  }
}
