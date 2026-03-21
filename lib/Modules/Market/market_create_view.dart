import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_create_controller.dart';

class MarketCreateView extends StatefulWidget {
  const MarketCreateView({
    super.key,
    this.initialItem,
  });

  final MarketItemModel? initialItem;

  @override
  State<MarketCreateView> createState() => _MarketCreateViewState();
}

class _MarketCreateViewState extends State<MarketCreateView> {
  late final String _controllerTag;
  late final MarketCreateController controller;
  bool _ownsController = false;
  final PageController _imagePreviewController = PageController();
  int _imagePreviewIndex = 0;

  String _categoryLabel(Map<String, dynamic> category) {
    return (category['localizedLabel'] ?? category['label'] ?? '').toString();
  }

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'market_create_${widget.initialItem?.id ?? 'new'}_${identityHashCode(this)}';
    final existing = MarketCreateController.maybeFind(tag: _controllerTag);
    if (existing != null) {
      controller = existing;
    } else {
      controller = MarketCreateController.ensure(
        initialItem: widget.initialItem,
        tag: _controllerTag,
      );
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    _imagePreviewController.dispose();
    final existing = MarketCreateController.maybeFind(tag: _controllerTag);
    if (_ownsController && identical(existing, controller)) {
      Get.delete<MarketCreateController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          return const Center(child: CircularProgressIndicator());
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

  Widget _buildTopCategories() {
    String? selectedLabel;
    for (final category in controller.topCategories) {
      final key = (category['key'] ?? '').toString();
      if (key == controller.selectedTopKey.value) {
        selectedLabel = _categoryLabel(category);
        break;
      }
    }

    return GestureDetector(
      onTap: _openTopCategorySheet,
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
                selectedLabel ?? 'pasaj.market.create.main_category'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selectedLabel == null ? Colors.grey : Colors.black,
                  fontSize: 15,
                  fontFamily: selectedLabel == null
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
    );
  }

  Future<void> _openTopCategorySheet() async {
    final displayToKey = <String, String>{
      for (final category in controller.topCategories)
        _categoryLabel(category): (category['key'] ?? '').toString(),
    };
    String? selectedDisplay;
    for (final entry in displayToKey.entries) {
      if (entry.value == controller.selectedTopKey.value) {
        selectedDisplay = entry.key;
        break;
      }
    }

    await ListBottomSheet.show(
      context: context,
      items: displayToKey.keys.toList(growable: false),
      title: 'pasaj.market.create.main_category'.tr,
      searchHintText: 'pasaj.market.create.main_category_search'.tr,
      searchTextBuilder: (item) =>
          _topCategorySearchText(displayToKey[item.toString()] ?? ''),
      selectedItem: selectedDisplay,
      onSelect: (selectedLabel) {
        final key = displayToKey[selectedLabel.toString()];
        if (key != null) {
          controller.selectTopCategory(key);
          Future.delayed(
            const Duration(milliseconds: 180),
            () => _openNextCategoryLevelSheet(fromLevel: -1),
          );
        }
      },
    );
  }

  String _topCategorySearchText(String topKey) {
    final category = controller.topCategories.firstWhereOrNull(
      (item) => (item['key'] ?? '').toString() == topKey,
    );
    if (category == null) return '';
    final parts = <String>[];
    void walk(dynamic node) {
      if (node is Map) {
        final label =
            (node['localizedLabel'] ?? node['label'] ?? '').toString().trim();
        final key = (node['key'] ?? '').toString().trim();
        if (label.isNotEmpty) parts.add(label);
        if (key.isNotEmpty) parts.add(key.replaceAll('-', ' '));
        final options = node['options'];
        if (options is List) {
          for (final option in options) {
            if (option is Map) {
              walk(option);
            } else {
              final value = option.toString().trim();
              if (value.isNotEmpty) parts.add(value);
            }
          }
        }
        final fields = node['fields'];
        if (fields is List) {
          for (final field in fields) {
            walk(field);
          }
        }
        final children = node['children'];
        if (children is List) {
          for (final child in children) {
            walk(child);
          }
        }
      }
    }

    walk(category);
    return parts.join(' ');
  }

  Widget _buildCategoryLevels() {
    if (controller.categoryLevels.isEmpty) {
      return _infoBox(
        'pasaj.market.create.no_subcategory'.tr,
      );
    }

    return Column(
      children: [
        for (var level = 0; level < controller.categoryLevels.length; level++)
          if (controller.shouldShowLevel(level)) ...[
            _buildCategorySelector(level),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  String _levelLabel(int level) {
    switch (level) {
      case 0:
        return 'pasaj.market.create.subcategory'.tr;
      case 1:
        return 'pasaj.market.create.subgroup'.tr;
      case 2:
        return 'pasaj.market.create.product_type'.tr;
      default:
        return 'pasaj.market.create.level'.trParams({'value': '${level + 1}'});
    }
  }

  Widget _buildCategorySelector(int level) {
    final selected = controller.selectedNodeForLevel(level);
    return GestureDetector(
      onTap: () => _openCategoryLevelSheet(level),
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
                selected?.label ?? _levelLabel(level),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected == null ? Colors.grey : Colors.black,
                  fontSize: 15,
                  fontFamily:
                      selected == null ? 'MontserratMedium' : 'MontserratBold',
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
    );
  }

  Future<void> _openCategoryLevelSheet(int level) async {
    final nodes = controller.optionsForLevel(level);
    if (nodes.isEmpty) return;

    final displayToKey = <String, String>{};
    final seenCounts = <String, int>{};
    for (final node in nodes) {
      final duplicateCount =
          nodes.where((candidate) => candidate.label == node.label).length;
      var display =
          duplicateCount > 1 ? node.pathLabels.skip(1).join(' > ') : node.label;
      if (display.trim().isEmpty) {
        display = node.label;
      }
      final existing = seenCounts[display] ?? 0;
      seenCounts[display] = existing + 1;
      if (existing > 0) {
        display = '$display (${existing + 1})';
      }
      displayToKey[display] = node.key;
    }

    final selectedNode = controller.selectedNodeForLevel(level);
    String? selectedDisplay;
    for (final entry in displayToKey.entries) {
      if (entry.value == selectedNode?.key) {
        selectedDisplay = entry.key;
        break;
      }
    }

    await ListBottomSheet.show(
      context: context,
      items: displayToKey.keys.toList(growable: false),
      title: _levelLabel(level),
      selectedItem: selectedDisplay,
      onSelect: (selectedDisplayValue) {
        final key = displayToKey[selectedDisplayValue.toString()];
        if (key != null) {
          controller.selectNodeAtLevel(level, key);
          Future.delayed(
            const Duration(milliseconds: 180),
            () => _openNextCategoryLevelSheet(fromLevel: level),
          );
        }
      },
    );
  }

  Future<void> _openNextCategoryLevelSheet({required int fromLevel}) async {
    for (var nextLevel = fromLevel + 1;
        nextLevel < controller.categoryLevels.length;
        nextLevel++) {
      if (controller.shouldShowLevel(nextLevel)) {
        await _openCategoryLevelSheet(nextLevel);
        return;
      }
    }
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
        onChanged: (_) => setState(() {}),
        decoration: _inputDecoration(
          field['required'] == true ? '$label *' : label,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _visibleDynamicFields(
      List<Map<String, dynamic>> fields) {
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

  Widget _buildImagePicker() {
    _syncImagePreviewIndex();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 50,
          width: double.infinity,
          child: OutlinedButton(
            onPressed:
                controller.isSubmitting.value ? null : controller.pickImages,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0x22000000)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'pasaj.market.create.select_image'.trParams({
                'current': '${controller.totalImageCount}',
                'max': '${MarketCreateController.maxImages}',
              }),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontFamily: 'MontserratBold',
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (controller.totalImageCount == 0)
          _buildImageFallbackCard()
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 186,
                child: PageView.builder(
                  controller: _imagePreviewController,
                  itemCount: controller.totalImageCount,
                  onPageChanged: (index) {
                    if (!mounted) return;
                    setState(() {
                      _imagePreviewIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final isExisting =
                        index < controller.existingImageUrls.length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: double.infinity,
                              child: isExisting
                                  ? Image.network(
                                      controller.existingImageUrls[index],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildImageFallback(),
                                    )
                                  : Image.file(
                                      controller.selectedImages[index -
                                          controller.existingImageUrls.length],
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: () => controller.removeImageAt(index),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.72),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                index == 0
                                    ? 'pasaj.market.create.cover'.tr
                                    : '${index + 1}/${controller.totalImageCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontFamily: 'MontserratBold',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (controller.totalImageCount > 1) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    controller.totalImageCount,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _imagePreviewIndex == index ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _imagePreviewIndex == index
                            ? Colors.black
                            : const Color(0x22000000),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.totalImageCount,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isExisting =
                        index < controller.existingImageUrls.length;
                    final selected = _imagePreviewIndex == index;
                    return GestureDetector(
                      onTap: () {
                        _imagePreviewController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        );
                      },
                      child: Container(
                        width: 86,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? Colors.black
                                : const Color(0x22000000),
                            width: selected ? 1.4 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: isExisting
                              ? Image.network(
                                  controller.existingImageUrls[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildImageFallback(),
                                )
                              : Image.file(
                                  controller.selectedImages[index -
                                      controller.existingImageUrls.length],
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildImageFallbackCard() {
    return Container(
      height: 186,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x11000000)),
      ),
      alignment: Alignment.center,
      child: const Icon(
        CupertinoIcons.photo_on_rectangle,
        color: Colors.black38,
        size: 36,
      ),
    );
  }

  void _syncImagePreviewIndex() {
    final total = controller.totalImageCount;
    if (total <= 0) {
      _imagePreviewIndex = 0;
      return;
    }
    if (_imagePreviewIndex < total) return;
    final targetIndex = total - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _imagePreviewController.jumpToPage(targetIndex);
      setState(() {
        _imagePreviewIndex = targetIndex;
      });
    });
  }

  Widget _buildImageFallback() {
    return Container(
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported, color: Colors.black38),
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
