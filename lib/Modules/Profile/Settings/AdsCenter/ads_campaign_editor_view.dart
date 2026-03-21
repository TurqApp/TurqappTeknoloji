import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

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
    _controller = Get.find<AdsCenterController>();

    final c = widget.initialCampaign;
    _name = TextEditingController(text: c?.name ?? '');
    _totalBudget =
        TextEditingController(text: (c?.totalBudget ?? 0).toString());
    _dailyBudget =
        TextEditingController(text: (c?.dailyBudget ?? 0).toString());
    _bidAmount = TextEditingController(text: (c?.bidAmount ?? 0).toString());
    _priority = TextEditingController(text: (c?.priority ?? 0).toString());
    _minAge =
        TextEditingController(text: c?.targeting.minAge?.toString() ?? '');
    _maxAge =
        TextEditingController(text: c?.targeting.maxAge?.toString() ?? '');
    _countries =
        TextEditingController(text: c?.targeting.countries.join(',') ?? '');
    _cities = TextEditingController(text: c?.targeting.cities.join(',') ?? '');
    _appVersions =
        TextEditingController(text: c?.targeting.appVersions.join(',') ?? '');
    _ctaText = TextEditingController();
    _destinationUrl = TextEditingController();
    _creativeMediaUrl = TextEditingController();
    _creativeHlsUrl = TextEditingController();
    _creativeThumbUrl = TextEditingController();
    _creativeHeadline = TextEditingController();
    _creativeBody = TextEditingController();
    _creativeDuration = TextEditingController();
    _creativeStoragePath = TextEditingController();

    _status = c?.status ?? AdCampaignStatus.draft;
    _budgetType = c?.budgetType ?? AdBudgetType.daily;
    _bidType = c?.bidType ?? AdBidType.cpm;
    _placements
      ..clear()
      ..addAll(c?.placementTypes ?? const [AdPlacementType.feed]);
    _advertiserId = c?.advertiserId ?? '';
    _isTestCampaign = c?.isTestCampaign ?? true;
    _deliveryEnabled = c?.deliveryEnabled ?? false;
    _startAt = c?.startAt ?? DateTime.now();
    _endAt = c?.endAt ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    for (final c in [
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
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _section('ads_center.campaign_info'.tr),
            _txt(_name, 'ads_center.campaign_name'.tr),
            const SizedBox(height: 8),
            _advertiserDropdown(),
            const SizedBox(height: 8),
            _enumDropdown<AdCampaignStatus>(
              label: 'ads_center.status'.tr,
              value: _status,
              values: AdCampaignStatus.values,
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 8),
            _placementSelector(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _enumDropdown<AdBudgetType>(
                    label: 'ads_center.budget_type'.tr,
                    value: _budgetType,
                    values: AdBudgetType.values,
                    onChanged: (v) => setState(() => _budgetType = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _enumDropdown<AdBidType>(
                    label: 'ads_center.bid_type'.tr,
                    value: _bidType,
                    values: AdBidType.values,
                    onChanged: (v) => setState(() => _bidType = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _txt(
                      _totalBudget,
                      'ads_center.total_budget'.tr,
                      numOnly: true,
                    )),
                const SizedBox(width: 8),
                Expanded(
                    child: _txt(
                      _dailyBudget,
                      'ads_center.daily_budget'.tr,
                      numOnly: true,
                    )),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _txt(
                      _bidAmount,
                      'ads_center.bid_amount'.tr,
                      numOnly: true,
                    )),
                const SizedBox(width: 8),
                Expanded(
                    child: _txt(
                      _priority,
                      'ads_center.priority'.tr,
                      numOnly: true,
                    )),
              ],
            ),
            const SizedBox(height: 10),
            _dateRow(),
            const SizedBox(height: 10),
            _switch('ads_center.test_campaign'.tr, _isTestCampaign,
                (v) => setState(() => _isTestCampaign = v)),
            _switch('ads_center.delivery_enabled'.tr, _deliveryEnabled,
                (v) => setState(() => _deliveryEnabled = v)),
            const SizedBox(height: 8),
            _section('ads_center.targeting'.tr),
            _txt(_countries, 'ads_center.countries'.tr),
            const SizedBox(height: 8),
            _txt(_cities, 'ads_center.cities'.tr),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _txt(_minAge, 'ads_center.min_age'.tr, numOnly: true)),
                const SizedBox(width: 8),
                Expanded(
                    child: _txt(_maxAge, 'ads_center.max_age'.tr, numOnly: true)),
              ],
            ),
            const SizedBox(height: 8),
            _txt(_appVersions, 'ads_center.app_versions'.tr),
            const SizedBox(height: 8),
            Text(
              'ads_center.device_platform_ios'.tr,
              style: TextStyle(fontFamily: 'MontserratMedium', fontSize: 12),
            ),
            const SizedBox(height: 14),
            _section('ads_center.creative_attachment'.tr),
            Row(
              children: [
                Expanded(
                  child: _enumDropdown<AdCreativeType>(
                    label: 'ads_center.creative_type'.tr,
                    value: _creativeType,
                    values: AdCreativeType.values,
                    onChanged: (v) => setState(() => _creativeType = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: _txt(
                      _creativeDuration,
                      'ads_center.duration_seconds'.tr,
                      numOnly: true,
                    )),
              ],
            ),
            const SizedBox(height: 8),
            _txt(_creativeStoragePath, 'ads_center.storage_path'.tr),
            const SizedBox(height: 8),
            _txt(_creativeMediaUrl, 'ads_center.media_url'.tr),
            const SizedBox(height: 8),
            _txt(_creativeHlsUrl, 'ads_center.hls_master_url'.tr),
            const SizedBox(height: 8),
            _txt(_creativeThumbUrl, 'ads_center.thumbnail_url'.tr),
            const SizedBox(height: 8),
            _txt(_creativeHeadline, 'ads_center.headline'.tr),
            const SizedBox(height: 8),
            _txt(_creativeBody, 'ads_center.body_text'.tr),
            const SizedBox(height: 8),
            _txt(_ctaText, 'ads_center.cta_text'.tr),
            const SizedBox(height: 8),
            _txt(_destinationUrl, 'ads_center.destination_url'.tr),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(
                widget.initialCampaign == null
                    ? 'ads_center.create_campaign'.tr
                    : 'ads_center.update_campaign'.tr,
                style: const TextStyle(fontFamily: 'MontserratBold'),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _saveCreativeOnly,
              icon: const Icon(Icons.video_collection_outlined),
              label: Text(
                'ads_center.save_creative'.tr,
                style: TextStyle(fontFamily: 'MontserratMedium'),
              ),
            ),
            const SizedBox(height: 28),
          ],
        );
      }),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'MontserratBold',
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _switch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: const TextStyle(fontFamily: 'MontserratMedium', fontSize: 13)),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _placementSelector() {
    return Wrap(
      spacing: 8,
      children: AdPlacementType.values.map((p) {
        final selected = _placements.contains(p);
        return FilterChip(
          label: Text(p.name),
          selected: selected,
          onSelected: (v) {
            setState(() {
              if (v) {
                _placements.add(p);
              } else {
                _placements.remove(p);
                if (_placements.isEmpty) {
                  _placements.add(AdPlacementType.feed);
                }
              }
            });
          },
        );
      }).toList(growable: false),
    );
  }

  Widget _advertiserDropdown() {
    return Obx(() {
      final items = _controller.advertisers;
      return DropdownButtonFormField<String>(
        initialValue: _advertiserId.isEmpty ? null : _advertiserId,
        decoration: _d('ads_center.advertiser'.tr),
        items: items
            .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
            .toList(growable: false),
        onChanged: (v) => setState(() => _advertiserId = v ?? ''),
      );
    });
  }

  Widget _dateRow() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startAt,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _startAt = picked);
            },
            child: InputDecorator(
              decoration: _d('ads_center.start_date'.tr),
              child: Text(_formatDate(_startAt)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _endAt,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _endAt = picked);
            },
            child: InputDecorator(
              decoration: _d('ads_center.end_date'.tr),
              child: Text(_formatDate(_endAt)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _txt(TextEditingController c, String hint, {bool numOnly = false}) {
    return TextField(
      controller: c,
      keyboardType: numOnly ? TextInputType.number : TextInputType.text,
      decoration: _d(hint),
    );
  }

  Widget _enumDropdown<T>({
    required String label,
    required T value,
    required List<T> values,
    required ValueChanged<T> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: _d(label),
      items: values
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text((e as dynamic).name.toString()),
              ))
          .toList(growable: false),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  InputDecoration _d(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );

  String get _currentUid {
    final serviceUid = CurrentUserService.instance.userId.trim();
    if (serviceUid.isNotEmpty) return serviceUid;
    return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  }

  List<String> _splitComma(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  AdTargeting _buildTargeting() {
    return AdTargeting(
      countries: _splitComma(_countries.text),
      cities: _splitComma(_cities.text),
      minAge: int.tryParse(_minAge.text.trim()),
      maxAge: int.tryParse(_maxAge.text.trim()),
      devicePlatforms: const ['ios'],
      appVersions: _splitComma(_appVersions.text),
    );
  }

  Future<void> _save() async {
    final uid = _currentUid;
    final base = widget.initialCampaign ?? AdCampaign.empty(createdBy: uid);

    final campaign = base.copyWith(
      advertiserId: _advertiserId,
      name: _name.text.trim(),
      status: _status,
      placementTypes: _placements.toList(growable: false),
      budgetType: _budgetType,
      totalBudget: double.tryParse(_totalBudget.text.trim()) ?? 0,
      dailyBudget: double.tryParse(_dailyBudget.text.trim()) ?? 0,
      bidType: _bidType,
      bidAmount: double.tryParse(_bidAmount.text.trim()) ?? 0,
      priority: int.tryParse(_priority.text.trim()) ?? 0,
      isTestCampaign: _isTestCampaign,
      deliveryEnabled: _deliveryEnabled,
      startAt: _startAt,
      endAt: _endAt,
      targeting: _buildTargeting(),
      updatedAt: DateTime.now(),
    );

    final id = await _controller.saveCampaign(campaign);
    await _attachCreativeIfFilled(id);

    if (!mounted) return;
    AppSnackbar(
      'ads_center.campaign_saved_title'.tr,
      'ads_center.campaign_saved_body'.trParams({'id': id}),
    );
  }

  Future<void> _saveCreativeOnly() async {
    final campaignId = widget.initialCampaign?.id ?? '';
    if (campaignId.isEmpty) {
      AppSnackbar(
        'common.info'.tr,
        'ads_center.save_campaign_first'.tr,
      );
      return;
    }
    await _attachCreativeIfFilled(campaignId);
    AppSnackbar(
      'ads_center.creative_saved_title'.tr,
      'ads_center.creative_saved_body'.tr,
    );
  }

  Future<void> _attachCreativeIfFilled(String campaignId) async {
    final headline = _creativeHeadline.text.trim();
    final mediaUrl = _creativeMediaUrl.text.trim();
    final destination = _destinationUrl.text.trim();

    if (headline.isEmpty && mediaUrl.isEmpty && destination.isEmpty) {
      return;
    }

    final creative = AdCreative.empty().copyWith(
      campaignId: campaignId,
      type: _creativeType,
      storagePath: _creativeStoragePath.text.trim(),
      mediaURL: mediaUrl,
      hlsMasterURL: _creativeHlsUrl.text.trim(),
      thumbnailURL: _creativeThumbUrl.text.trim(),
      durationSec: int.tryParse(_creativeDuration.text.trim()) ?? 0,
      headline: headline,
      bodyText: _creativeBody.text.trim(),
      ctaText: _ctaText.text.trim(),
      destinationURL: destination,
      moderationStatus: AdModerationStatus.pending,
      updatedAt: DateTime.now(),
    );

    final creativeId = await _controller.saveCreative(creative);

    final currentCampaign = widget.initialCampaign;
    final existing = currentCampaign?.creativeIds ?? const <String>[];
    final merged = <String>{...existing, creativeId}.toList(growable: false);

    if (currentCampaign != null) {
      await _controller.saveCampaign(
        currentCampaign.copyWith(
          creativeIds: merged,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      final saved =
          _controller.campaigns.firstWhereOrNull((c) => c.id == campaignId);
      if (saved != null) {
        await _controller.saveCampaign(
            saved.copyWith(creativeIds: merged, updatedAt: DateTime.now()));
      }
    }
  }
}
