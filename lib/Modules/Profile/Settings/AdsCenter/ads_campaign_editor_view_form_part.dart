part of 'ads_campaign_editor_view.dart';

extension _AdsCampaignEditorViewFormPart on _AdsCampaignEditorViewState {
  Widget _sectionCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 15,
            ),
          ),
          if (subtitle != null && subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...children,
        ],
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

  Widget _compactInfo(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'MontserratMedium',
        fontSize: 12,
        color: Colors.black54,
      ),
    );
  }

  Widget _placementSelector() {
    return Wrap(
      spacing: 8,
      children: AdPlacementType.values.map((p) {
        final selected = _placements.contains(p);
        return FilterChip(
          label: Text(p.displayName),
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
              child: Text(_enumLabel(e)),
            ),
          )
          .toList(growable: false),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  String _enumLabel<T>(T value) {
    if (value is AdCampaignStatus) {
      return value.displayName;
    }
    if (value is AdBidType) {
      return value.displayName;
    }
    if (value is AdBudgetType) {
      return value.displayName;
    }
    if (value is AdCreativeType) {
      return value.displayName;
    }
    return (value as dynamic).name.toString();
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
      devicePlatforms: const <String>[],
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
