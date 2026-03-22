part of 'ads_campaign_editor_view.dart';

extension _AdsCampaignEditorViewContentPart on _AdsCampaignEditorViewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(
        () => ListView(
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
              onChanged: (v) => _updateViewState(() => _status = v),
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
                    onChanged: (v) => _updateViewState(() => _budgetType = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _enumDropdown<AdBidType>(
                    label: 'ads_center.bid_type'.tr,
                    value: _bidType,
                    values: AdBidType.values,
                    onChanged: (v) => _updateViewState(() => _bidType = v),
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
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _txt(
                    _dailyBudget,
                    'ads_center.daily_budget'.tr,
                    numOnly: true,
                  ),
                ),
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
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _txt(
                    _priority,
                    'ads_center.priority'.tr,
                    numOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _dateRow(),
            const SizedBox(height: 10),
            _switch(
              'ads_center.test_campaign'.tr,
              _isTestCampaign,
              (v) => _updateViewState(() => _isTestCampaign = v),
            ),
            _switch(
              'ads_center.delivery_enabled'.tr,
              _deliveryEnabled,
              (v) => _updateViewState(() => _deliveryEnabled = v),
            ),
            const SizedBox(height: 8),
            _section('ads_center.targeting'.tr),
            _txt(_countries, 'ads_center.countries'.tr),
            const SizedBox(height: 8),
            _txt(_cities, 'ads_center.cities'.tr),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _txt(
                    _minAge,
                    'ads_center.min_age'.tr,
                    numOnly: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _txt(
                    _maxAge,
                    'ads_center.max_age'.tr,
                    numOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _txt(_appVersions, 'ads_center.app_versions'.tr),
            const SizedBox(height: 8),
            Text(
              'ads_center.device_platform_ios'.tr,
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 12,
              ),
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
                    onChanged: (v) => _updateViewState(() => _creativeType = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _txt(
                    _creativeDuration,
                    'ads_center.duration_seconds'.tr,
                    numOnly: true,
                  ),
                ),
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
                style: const TextStyle(fontFamily: 'MontserratMedium'),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
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
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'MontserratMedium',
          fontSize: 13,
        ),
      ),
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
          onSelected: (v) => _updateViewState(() {
            if (v) {
              _placements.add(p);
            } else {
              _placements.remove(p);
              if (_placements.isEmpty) {
                _placements.add(AdPlacementType.feed);
              }
            }
          }),
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
        onChanged: (v) => _updateViewState(() => _advertiserId = v ?? ''),
      );
    });
  }

  Widget _dateRow() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _pickStartDate,
            child: InputDecorator(
              decoration: _d('ads_center.start_date'.tr),
              child: Text(_formatDate(_startAt)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: _pickEndDate,
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
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text((e as dynamic).name.toString()),
            ),
          )
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
}
