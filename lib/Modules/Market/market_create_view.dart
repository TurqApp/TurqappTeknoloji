import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'market-create-${widget.initialItem?.id ?? DateTime.now().microsecondsSinceEpoch}';
    controller = Get.put(
      MarketCreateController(initialItem: widget.initialItem),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<MarketCreateController>(tag: _controllerTag)) {
      Get.delete<MarketCreateController>(tag: _controllerTag, force: true);
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
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
        ),
        title: Text(
          controller.pageTitle,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'MontserratBold',
          ),
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
            _sectionTitle('Kategori'),
            const SizedBox(height: 8),
            _buildTopCategories(),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: leaf?.key,
              decoration: _inputDecoration('Alt kategori sec'),
              items: controller.leafCategories
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.key,
                      child: Text(
                        item.pathText,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) controller.selectLeafCategory(value);
              },
            ),
            if (leaf != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  leaf.pathText,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            _sectionTitle('Temel Bilgiler'),
            const SizedBox(height: 8),
            TextField(
              controller: controller.titleController,
              decoration: _inputDecoration('Baslik'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.descriptionController,
              minLines: 4,
              maxLines: 6,
              decoration: _inputDecoration('Açıklama'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration('Fiyat (TL)'),
            ),
            const SizedBox(height: 18),
            _sectionTitle('İlan Özellikleri'),
            const SizedBox(height: 8),
            if (leaf == null)
              _infoBox('Bir kategori secince bu alanlar otomatik dolacak.')
            else if (leaf.fields.isEmpty)
              _infoBox('Bu kategori icin ek alan tanimli degil.')
            else
              ...leaf.fields.map((field) => _buildDynamicField(field)),
            const SizedBox(height: 18),
            _sectionTitle('Konum'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: controller.selectedCity.value.isEmpty
                  ? null
                  : controller.selectedCity.value,
              decoration: _inputDecoration('Şehir'),
              items: controller.cities
                  .map(
                    (city) => DropdownMenuItem<String>(
                      value: city,
                      child: Text(
                        city,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: controller.setCity,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: controller.selectedDistrict.value.isEmpty
                  ? null
                  : controller.selectedDistrict.value,
              decoration: _inputDecoration('İlçe'),
              items: controller.districtOptions
                  .map(
                    (district) => DropdownMenuItem<String>(
                      value: district,
                      child: Text(
                        district,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: controller.setDistrict,
            ),
            const SizedBox(height: 18),
            _sectionTitle('İletişim Tercihi'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _contactChip(
                    label: 'Mesaj ile',
                    value: 'message_only',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _contactChip(
                    label: 'Telefon göster',
                    value: 'phone',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _sectionTitle('Görseller'),
            const SizedBox(height: 8),
            _buildImagePicker(),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: controller.isSubmitting.value
                          ? null
                          : controller.saveDraftPreview,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0x22000000)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        controller.isSubmitting.value
                            ? 'Bekleyin...'
                            : controller.draftActionLabel,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 50,
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
                            ? 'Yükleniyor...'
                            : controller.publishActionLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTopCategories() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.topCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = controller.topCategories[index];
          final key = (category['key'] ?? '').toString();
          final selected = controller.selectedTopKey.value == key;
          return GestureDetector(
            onTap: () => controller.selectTopCategory(key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: selected ? Colors.black : Colors.white,
                border: Border.all(
                  color: selected ? Colors.black : const Color(0x22000000),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                (category['label'] ?? '').toString(),
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black,
                  fontSize: 12,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDynamicField(Map<String, dynamic> field) {
    final key = (field['key'] ?? '').toString();
    final label = (field['label'] ?? key).toString();
    final isSelect = !controller.fieldUsesTextInput(field);
    final options = controller.fieldOptions(field);
    if (isSelect) {
      final initialValue = controller.fieldValue(key).isEmpty
          ? null
          : controller.fieldValue(key);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: DropdownButtonFormField<String>(
          initialValue: initialValue,
          decoration: _inputDecoration(
            field['required'] == true ? '$label *' : label,
          ),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (value) => controller.setFieldValue(key, value ?? ''),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller.controllerForField(key),
        decoration: _inputDecoration(
          field['required'] == true ? '$label *' : label,
        ),
      ),
    );
  }

  Widget _contactChip({
    required String label,
    required String value,
  }) {
    final selected = controller.contactPreference.value == value;
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
              'Görsel Seç (${controller.totalImageCount}/${MarketCreateController.maxImages})',
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
          _infoBox('İlk seçilen görsel kapak resmi olarak kullanılır.')
        else
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.totalImageCount,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isExisting = index < controller.existingImageUrls.length;
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isExisting
                          ? Image.network(
                              controller.existingImageUrls[index],
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 96,
                                height: 96,
                                color: const Color(0xFFF3F4F6),
                                alignment: Alignment.center,
                                child: const Icon(Icons.image_not_supported),
                              ),
                            )
                          : Image.file(
                              controller.selectedImages[
                                  index - controller.existingImageUrls.length],
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => controller.removeImageAt(index),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Kapak',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: 'MontserratBold',
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
      ],
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
