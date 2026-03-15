import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';

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
            _section('Kampanya Bilgisi'),
            _txt(_name, 'Campaign Name'),
            const SizedBox(height: 8),
            _advertiserDropdown(),
            const SizedBox(height: 8),
            _enumDropdown<AdCampaignStatus>(
              label: 'Status',
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
                    label: 'Budget Type',
                    value: _budgetType,
                    values: AdBudgetType.values,
                    onChanged: (v) => setState(() => _budgetType = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _enumDropdown<AdBidType>(
                    label: 'Bid Type',
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
                    child: _txt(_totalBudget, 'Total Budget', numOnly: true)),
                const SizedBox(width: 8),
                Expanded(
                    child: _txt(_dailyBudget, 'Daily Budget', numOnly: true)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _txt(_bidAmount, 'Bid Amount', numOnly: true)),
                const SizedBox(width: 8),
                Expanded(child: _txt(_priority, 'Priority', numOnly: true)),
              ],
            ),
            const SizedBox(height: 10),
            _dateRow(),
            const SizedBox(height: 10),
            _switch('Test Campaign', _isTestCampaign,
                (v) => setState(() => _isTestCampaign = v)),
            _switch('Delivery Enabled', _deliveryEnabled,
                (v) => setState(() => _deliveryEnabled = v)),
            const SizedBox(height: 8),
            _section('Targeting'),
            _txt(_countries, 'Countries (TR,US,...)'),
            const SizedBox(height: 8),
            _txt(_cities, 'Cities (Istanbul,Konya,...)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _txt(_minAge, 'Min Age', numOnly: true)),
                const SizedBox(width: 8),
                Expanded(child: _txt(_maxAge, 'Max Age', numOnly: true)),
              ],
            ),
            const SizedBox(height: 8),
            _txt(_appVersions, 'App Versions (1.1.4,...)'),
            const SizedBox(height: 8),
            const Text(
              'Device Platform: iOS (ilk faz sabit)',
              style: TextStyle(fontFamily: 'MontserratMedium', fontSize: 12),
            ),
            const SizedBox(height: 14),
            _section('Creative Attachment'),
            Row(
              children: [
                Expanded(
                  child: _enumDropdown<AdCreativeType>(
                    label: 'Creative Type',
                    value: _creativeType,
                    values: AdCreativeType.values,
                    onChanged: (v) => setState(() => _creativeType = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child:
                        _txt(_creativeDuration, 'Duration Sec', numOnly: true)),
              ],
            ),
            const SizedBox(height: 8),
            _txt(_creativeStoragePath, 'Storage Path'),
            const SizedBox(height: 8),
            _txt(_creativeMediaUrl, 'Media URL'),
            const SizedBox(height: 8),
            _txt(_creativeHlsUrl, 'HLS Master URL'),
            const SizedBox(height: 8),
            _txt(_creativeThumbUrl, 'Thumbnail URL'),
            const SizedBox(height: 8),
            _txt(_creativeHeadline, 'Headline'),
            const SizedBox(height: 8),
            _txt(_creativeBody, 'Body Text'),
            const SizedBox(height: 8),
            _txt(_ctaText, 'CTA Text'),
            const SizedBox(height: 8),
            _txt(_destinationUrl, 'Destination URL'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(
                widget.initialCampaign == null
                    ? 'Kampanya Oluştur'
                    : 'Kampanyayı Güncelle',
                style: const TextStyle(fontFamily: 'MontserratBold'),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _saveCreativeOnly,
              icon: const Icon(Icons.video_collection_outlined),
              label: const Text(
                'Kreatif Kaydet',
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
        decoration: _d('Advertiser'),
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
              decoration: _d('Start Date'),
              child: Text('${_startAt.year}-${_startAt.month}-${_startAt.day}'),
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
              decoration: _d('End Date'),
              child: Text('${_endAt.year}-${_endAt.month}-${_endAt.day}'),
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
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
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
    AppSnackbar('Kampanya Kaydedildi', 'Kampanya kimliği: $id');
  }

  Future<void> _saveCreativeOnly() async {
    final campaignId = widget.initialCampaign?.id ?? '';
    if (campaignId.isEmpty) {
      AppSnackbar('Bilgilendirme', 'Lütfen önce kampanyayı kaydedin.');
      return;
    }
    await _attachCreativeIfFilled(campaignId);
    AppSnackbar('Kreatif Kaydedildi', 'Reklam kreatifi başarıyla kaydedildi.');
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
