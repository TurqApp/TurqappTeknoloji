part of 'market_create_view.dart';

extension _MarketCreateViewFormPart on _MarketCreateViewState {
  Widget _buildMarketCreateScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const AppBackButton(),
        title: AppPageTitle(
          widget.initialItem == null
              ? 'pasaj.market.add_listing'.tr
              : 'common.edit'.tr,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppStateView.loading();
        }
        final leaf = controller.selectedLeaf.value;
        return ListView(
          padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
          children: [
            _sectionTitle('pasaj.market.create.images'.tr),
            const SizedBox(height: 8),
            _buildImagePicker(),
            const SizedBox(height: 18),
            _sectionTitle('pasaj.market.create.basic_info'.tr),
            const SizedBox(height: 8),
            TextField(
              controller: controller.titleController,
              decoration: _inputDecoration('pasaj.market.create.title_hint'.tr),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.descriptionController,
              minLines: 4,
              maxLines: 6,
              decoration:
                  _inputDecoration('pasaj.market.create.description_hint'.tr),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration('pasaj.market.create.price_hint'.tr),
            ),
            const SizedBox(height: 18),
            _sectionTitle('pasaj.market.create.location'.tr),
            const SizedBox(height: 8),
            _buildLocationSelectors(),
            const SizedBox(height: 18),
            _sectionTitle('pasaj.market.create.category'.tr),
            const SizedBox(height: 8),
            _buildTopCategories(),
            const SizedBox(height: 12),
            _buildCategoryLevels(),
            if (leaf != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  controller.selectedCategoryPathText.isEmpty
                      ? leaf.pathText
                      : controller.selectedCategoryPathText,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            _sectionTitle('pasaj.market.create.features'.tr),
            const SizedBox(height: 8),
            if (leaf == null)
              _infoBox('pasaj.market.create.fields_after_category'.tr)
            else if (leaf.fields.isEmpty)
              _infoBox('pasaj.market.create.no_extra_fields'.tr)
            else
              ..._visibleDynamicFields(leaf.fields).map(_buildDynamicField),
            const SizedBox(height: 18),
            _sectionTitle('pasaj.market.create.contact_preference'.tr),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _contactChip(
                    label: 'common.message'.tr,
                    value: 'message_only',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _contactChip(
                    label: 'common.phone'.tr,
                    value: 'phone',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isSubmitting.value
                    ? null
                    : controller.publishPreview,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  controller.isSubmitting.value
                      ? 'common.loading'.tr
                      : 'common.publish'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'MontserratBold',
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDynamicField(Map<String, dynamic> field) {
    final key = (field['key'] ?? '').toString();
    final label = (field['label'] ?? key).toString();
    final isSelect = !controller.fieldUsesTextInput(field);
    if (isSelect) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () => _openDynamicFieldSheet(field),
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x22000000)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.fieldValue(key).isEmpty
                        ? (field['required'] == true ? '$label *' : label)
                        : controller.fieldValue(key),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: controller.fieldValue(key).isEmpty
                          ? Colors.grey
                          : Colors.black,
                      fontSize: 15,
                      fontFamily: controller.fieldValue(key).isEmpty
                          ? 'MontserratMedium'
                          : 'MontserratBold',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.chevron_down,
                  size: 18,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller.controllerForField(key),
        onChanged: (_) => _updateMarketCreateState(() {}),
        decoration: _inputDecoration(
          field['required'] == true ? '$label *' : label,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _visibleDynamicFields(
    List<Map<String, dynamic>> fields,
  ) {
    final visible = <Map<String, dynamic>>[];
    for (final field in fields) {
      visible.add(field);
      final key = (field['key'] ?? '').toString();
      if (controller.fieldValue(key).trim().isEmpty) {
        break;
      }
    }
    return visible;
  }

  Widget _buildLocationSelectors() {
    return Column(
      children: [
        _buildLocationSelector(
          label: 'common.city'.tr,
          value: controller.selectedCity.value,
          isLoading: controller.isResolvingLocation.value,
          onTap: _openCitySheet,
        ),
        const SizedBox(height: 8),
        _buildLocationSelector(
          label: 'common.district'.tr,
          value: controller.selectedDistrict.value,
          onTap:
              controller.selectedCity.value.isEmpty ? null : _openDistrictSheet,
        ),
      ],
    );
  }

  Widget _buildLocationSelector({
    required String label,
    required String value,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x22000000)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.isEmpty ? label : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value.isEmpty ? Colors.grey : Colors.black,
                  fontSize: 15,
                  fontFamily:
                      value.isEmpty ? 'MontserratMedium' : 'MontserratBold',
                ),
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(
                CupertinoIcons.chevron_down,
                size: 18,
                color: Colors.black54,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCitySheet() async {
    await ListBottomSheet.show(
      context: context,
      items: controller.cities,
      title: 'common.city'.tr,
      selectedItem: controller.selectedCity.value.isEmpty
          ? null
          : controller.selectedCity.value,
      onSelect: (selectedCity) {
        controller.setCity(selectedCity.toString());
        Future.delayed(const Duration(milliseconds: 180), _openDistrictSheet);
      },
    );
  }

  Future<void> _openDistrictSheet() async {
    final districts = controller.districtOptions;
    if (districts.isEmpty) return;
    await ListBottomSheet.show(
      context: context,
      items: districts,
      title: 'common.district'.tr,
      selectedItem: controller.selectedDistrict.value.isEmpty
          ? null
          : controller.selectedDistrict.value,
      onSelect: (selectedDistrict) {
        controller.setDistrict(selectedDistrict.toString());
      },
    );
  }

  Future<void> _openDynamicFieldSheet(Map<String, dynamic> field) async {
    final key = (field['key'] ?? '').toString();
    final label = (field['label'] ?? key).toString();
    final items = controller.fieldOptions(field);
    if (items.isEmpty) return;

    final selectedValue =
        controller.fieldValue(key).isEmpty ? null : controller.fieldValue(key);

    await ListBottomSheet.show(
      context: context,
      items: items,
      title: label,
      selectedItem: selectedValue,
      onSelect: (selectedOption) {
        controller.setFieldValue(key, selectedOption.toString());
        Future.delayed(
          const Duration(milliseconds: 180),
          () => _openNextDynamicFieldSheet(afterKey: key),
        );
      },
    );
  }

  Future<void> _openNextDynamicFieldSheet({required String afterKey}) async {
    final leaf = controller.selectedLeaf.value;
    if (leaf == null) return;
    final fields = leaf.fields;
    final currentIndex = fields.indexWhere(
      (field) => (field['key'] ?? '').toString() == afterKey,
    );
    if (currentIndex == -1) return;

    for (var i = currentIndex + 1; i < fields.length; i++) {
      final field = fields[i];
      if (controller.fieldUsesTextInput(field)) continue;
      final key = (field['key'] ?? '').toString();
      if (controller.fieldValue(key).isNotEmpty) continue;
      await _openDynamicFieldSheet(field);
      return;
    }
  }

  Widget _contactChip({
    required String label,
    required String value,
  }) {
    final selected = value == 'message_only'
        ? true
        : controller.contactPreference.value == 'phone';
    return GestureDetector(
      onTap: () => controller.setContactPreference(value),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.black : const Color(0x22000000),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontSize: 13,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontFamily: 'MontserratBold',
      ),
    );
  }

  Widget _infoBox(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 13,
          fontFamily: 'MontserratMedium',
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.black45,
        fontSize: 13,
        fontFamily: 'MontserratMedium',
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x22000000)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x22000000)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black),
      ),
    );
  }
}
