part of 'ads_preview_screen.dart';

extension AdsPreviewScreenFormPart on _AdsPreviewScreenState {
  Widget _buildPreviewForm() {
    return Column(
      children: [
        TextField(controller: _userId, decoration: _d('ads_center.user_id'.tr)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _country,
                decoration: _d('ads_center.country'.tr),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _city,
                decoration: _d('ads_center.city'.tr),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _age,
                decoration: _d('ads_center.age'.tr),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<AdPlacementType>(
          initialValue: _placement,
          decoration: _d('ads_center.placement'.tr),
          items: AdPlacementType.values.map((placement) {
            return DropdownMenuItem(
              value: placement,
              child: Text(placement.name),
            );
          }).toList(growable: false),
          onChanged: (value) {
            if (value != null) {
              _updateViewState(() {
                _placement = value;
              });
            }
          },
        ),
        const SizedBox(height: 12),
        Obx(_buildRunButton),
      ],
    );
  }

  Widget _buildRunButton() {
    return ElevatedButton.icon(
      onPressed: _controller.previewLoading.value
          ? null
          : () async {
              await _controller.runPreview(
                placement: _placement,
                country: _country.text.trim(),
                city: _city.text.trim(),
                age: int.tryParse(_age.text.trim()),
                userId: _userId.text.trim(),
              );
            },
      icon: _controller.previewLoading.value
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.play_arrow),
      label: Text('ads_center.run_simulation'.tr),
    );
  }

  InputDecoration _d(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
