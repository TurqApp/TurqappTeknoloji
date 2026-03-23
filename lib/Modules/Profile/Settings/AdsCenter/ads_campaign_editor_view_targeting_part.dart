part of 'ads_campaign_editor_view.dart';

extension _AdsCampaignEditorViewTargetingPart on _AdsCampaignEditorViewState {
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

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _updateViewState(() => _startAt = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _updateViewState(() => _endAt = picked);
    }
  }
}
