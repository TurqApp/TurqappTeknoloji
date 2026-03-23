part of 'ads_campaign_editor_view.dart';

extension _AdsCampaignEditorViewSectionsPart on _AdsCampaignEditorViewState {
  Widget _buildCampaignSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
      ],
    );
  }

  Widget _buildTargetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildCreativeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildSubmitActions() {
    return Column(
      children: [
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
      ],
    );
  }
}
