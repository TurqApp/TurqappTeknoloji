part of 'ads_campaign_editor_view.dart';

extension _AdsCampaignEditorViewLifecyclePart on _AdsCampaignEditorViewState {
  void _initLifecycle() {
    _controller = AdsCenterController.ensure();

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

  void _disposeLifecycle() {
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
  }
}
