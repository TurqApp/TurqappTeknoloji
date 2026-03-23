part of 'ads_campaign_editor_view.dart';

extension _AdsCampaignEditorViewActionsPart on _AdsCampaignEditorViewState {
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
}
