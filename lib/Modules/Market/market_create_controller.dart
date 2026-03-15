import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import 'market_schema_service.dart';

class MarketLeafCategory {
  MarketLeafCategory({
    required this.key,
    required this.label,
    required this.pathLabels,
    required this.fields,
    required this.meta,
  });

  final String key;
  final String label;
  final List<String> pathLabels;
  final List<Map<String, dynamic>> fields;
  final Map<String, dynamic> meta;

  String get pathText => pathLabels.join(' > ');
}

class MarketCreateController extends GetxController {
  final MarketSchemaService _schemaService = MarketSchemaService.ensure();
  final MarketRepository _repository = MarketRepository.ensure();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<Map<String, dynamic>> topCategories =
      <Map<String, dynamic>>[].obs;
  final RxList<MarketLeafCategory> leafCategories = <MarketLeafCategory>[].obs;
  final Rxn<MarketLeafCategory> selectedLeaf = Rxn<MarketLeafCategory>();
  final RxString selectedTopKey = ''.obs;
  final RxString selectedCity = ''.obs;
  final RxString selectedDistrict = ''.obs;
  final RxString contactPreference = 'message_only'.obs;
  final RxMap<String, String> fieldValues = <String, String>{}.obs;
  final RxList<CitiesModel> cityDistricts = <CitiesModel>[].obs;
  final RxList<String> cities = <String>[].obs;
  final RxList<File> selectedImages = <File>[].obs;

  final Map<String, TextEditingController> _fieldControllers =
      <String, TextEditingController>{};
  static const int maxImages = 8;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      await _schemaService.loadSchema();
      topCategories.assignAll(_schemaService.categories());
      await _loadCityDistricts();
      if (topCategories.isNotEmpty) {
        selectTopCategory((topCategories.first['key'] ?? '').toString());
      }
    } finally {
      isLoading.value = false;
    }
  }

  void selectTopCategory(String key) {
    selectedTopKey.value = key;
    final target = topCategories.firstWhereOrNull(
      (item) => (item['key'] ?? '').toString() == key,
    );
    if (target == null) {
      leafCategories.clear();
      selectedLeaf.value = null;
      return;
    }
    final flattened = _flattenLeafCategories(
      target,
      [(target['label'] ?? '').toString()],
    );
    leafCategories.assignAll(flattened);
    if (flattened.isNotEmpty) {
      selectLeafCategory(flattened.first.key);
    } else {
      selectedLeaf.value = null;
      fieldValues.clear();
    }
  }

  void selectLeafCategory(String key) {
    final leaf = leafCategories.firstWhereOrNull((item) => item.key == key);
    if (leaf == null) return;
    selectedLeaf.value = leaf;
    _prepareDynamicFields(leaf.fields);
  }

  void setCity(String? value) {
    selectedCity.value = value?.trim() ?? '';
    final districts = districtOptions;
    if (!districts.contains(selectedDistrict.value)) {
      selectedDistrict.value = '';
    }
  }

  void setDistrict(String? value) {
    selectedDistrict.value = value?.trim() ?? '';
  }

  void setContactPreference(String value) {
    contactPreference.value = value;
  }

  List<String> get districtOptions {
    final city = selectedCity.value;
    if (city.isEmpty) return const <String>[];
    return cityDistricts
        .where((item) => item.il == city)
        .map((item) => item.ilce)
        .toSet()
        .toList()
      ..sort();
  }

  bool fieldUsesTextInput(Map<String, dynamic> field) {
    final type = (field['type'] ?? 'select').toString();
    return type != 'select';
  }

  List<String> fieldOptions(Map<String, dynamic> field) {
    final options = field['options'] as List<dynamic>? ?? const [];
    return options
        .map((option) {
          if (option is Map) {
            return (option['label'] ?? option['key'] ?? '').toString();
          }
          return option.toString();
        })
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  TextEditingController controllerForField(String key) {
    return _fieldControllers.putIfAbsent(key, () => TextEditingController());
  }

  void setFieldValue(String key, String value) {
    fieldValues[key] = value;
    final controller = _fieldControllers[key];
    if (controller != null && controller.text != value) {
      controller.text = value;
    }
  }

  String fieldValue(String key) {
    if (_fieldControllers.containsKey(key)) {
      return _fieldControllers[key]!.text.trim();
    }
    return fieldValues[key] ?? '';
  }

  Future<void> pickImages() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final remaining = maxImages - selectedImages.length;
    if (remaining <= 0) {
      AppSnackbar('Sinir', 'En fazla $maxImages gorsel ekleyebilirsin.');
      return;
    }
    final files = await AppImagePickerService.pickImages(
      ctx,
      maxAssets: remaining,
    );
    if (files.isEmpty) return;
    selectedImages.addAll(files.take(remaining));
  }

  void removeImageAt(int index) {
    if (index < 0 || index >= selectedImages.length) return;
    selectedImages.removeAt(index);
  }

  Future<void> saveDraftPreview() async {
    final issue = _validateBase(requiredPrice: false);
    if (issue != null) {
      AppSnackbar('Eksik Bilgi', issue);
      return;
    }
    await _submit(publish: false);
  }

  Future<void> publishPreview() async {
    final issue = _validateBase(requiredPrice: true);
    if (issue != null) {
      AppSnackbar('Eksik Bilgi', issue);
      return;
    }
    if (selectedImages.isEmpty) {
      AppSnackbar('Eksik Bilgi', 'Yayinlamak icin en az bir gorsel ekle.');
      return;
    }
    await _submit(publish: true);
  }

  Map<String, dynamic> buildDraftPayload({
    required bool publish,
    required String itemId,
    required String userId,
    required List<String> imageUrls,
  }) {
    final leaf = selectedLeaf.value;
    final now = int.tryParse(itemId) ?? DateTime.now().millisecondsSinceEpoch;
    final current = CurrentUserService.instance.currentUser;
    final sellerName = [
      current?.firstName ?? '',
      current?.lastName ?? '',
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    final attributes = <String, dynamic>{};
    if (leaf != null) {
      for (final field in leaf.fields) {
        final fieldKey = (field['key'] ?? '').toString();
        final label = (field['label'] ?? fieldKey).toString();
        final value = fieldValue(fieldKey);
        if (value.isNotEmpty) {
          attributes[label] = value;
        }
      }
    }
    return {
      'id': itemId,
      'userId': userId,
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'price': double.tryParse(
            priceController.text.trim().replaceAll(',', '.'),
          ) ??
          0,
      'currency': 'TRY',
      'categoryKey': leaf?.key ?? '',
      'categoryPath': leaf?.pathLabels ?? const <String>[],
      'attributes': attributes,
      'city': selectedCity.value,
      'district': selectedDistrict.value,
      'locationText': [selectedDistrict.value, selectedCity.value]
          .where((value) => value.trim().isNotEmpty)
          .join(', '),
      'contactPreference': contactPreference.value,
      'status': publish ? 'active' : 'draft',
      'seller': {
        'userId': userId,
        'name': sellerName.isEmpty
            ? (current?.nickname ?? 'Turq Kullanici')
            : sellerName,
        'username': current?.nickname ?? '',
        'photoUrl': current?.avatarUrl ?? '',
        'phoneNumber': current?.phoneNumber ?? '',
        'verified': current?.hesapOnayi == true,
      },
      'sellerName': sellerName.isEmpty
          ? (current?.nickname ?? 'Turq Kullanici')
          : sellerName,
      'sellerUsername': current?.nickname ?? '',
      'sellerPhotoUrl': current?.avatarUrl ?? '',
      'sellerPhoneNumber': current?.phoneNumber ?? '',
      'coverImageUrl': imageUrls.isEmpty ? '' : imageUrls.first,
      'imageUrls': imageUrls,
      'imageCount': imageUrls.length,
      'offerCount': 0,
      'favoriteCount': 0,
      'reportCount': 0,
      'viewCount': 0,
      'isNegotiable': true,
      'publishedAt': publish ? now : 0,
      'createdAt': now,
      'updatedAt': now,
    };
  }

  String? _validateBase({required bool requiredPrice}) {
    if (selectedLeaf.value == null) {
      return 'Bir kategori secmelisin.';
    }
    if (titleController.text.trim().isEmpty) {
      return 'Baslik gerekli.';
    }
    if (requiredPrice) {
      final price = double.tryParse(
        priceController.text.trim().replaceAll(',', '.'),
      );
      if (price == null || price <= 0) {
        return 'Gecerli bir fiyat gir.';
      }
    }
    if (selectedCity.value.isEmpty || selectedDistrict.value.isEmpty) {
      return 'Sehir ve ilce secimi gerekli.';
    }
    final leaf = selectedLeaf.value;
    if (leaf != null) {
      for (final field in leaf.fields) {
        if (field['required'] != true) continue;
        final key = (field['key'] ?? '').toString();
        if (fieldValue(key).isEmpty) {
          return '${(field['label'] ?? key).toString()} alani gerekli.';
        }
      }
    }
    return null;
  }

  Future<void> _loadCityDistricts() async {
    try {
      final response =
          await rootBundle.loadString('assets/data/CityDistrict.json');
      final data = (json.decode(response) as List<dynamic>)
          .map((item) => CitiesModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
      cityDistricts.assignAll(data);
      final cityList = data.map((item) => item.il).toSet().toList()..sort();
      cities.assignAll(cityList);
    } catch (_) {
      cities.clear();
      cityDistricts.clear();
    }
  }

  Future<void> _submit({required bool publish}) async {
    final uid = CurrentUserService.instance.userId.isNotEmpty
        ? CurrentUserService.instance.userId
        : (FirebaseAuth.instance.currentUser?.uid ?? '');
    if (uid.isEmpty) {
      AppSnackbar('Hata', 'Kullanici oturumu bulunamadi.');
      return;
    }

    final itemId = DateTime.now().millisecondsSinceEpoch.toString();
    isSubmitting.value = true;
    try {
      final imageUrls = await _uploadImages(uid: uid, itemId: itemId);
      final payload = buildDraftPayload(
        publish: publish,
        itemId: itemId,
        userId: uid,
        imageUrls: imageUrls,
      );
      await _repository.saveItem(
        docId: itemId,
        payload: payload,
        userId: uid,
      );
      AppSnackbar(
        'Tamam',
        publish ? 'Ilan yayinlandi.' : 'Taslak kaydedildi.',
      );
      Get.back(result: payload);
    } catch (e) {
      AppSnackbar('Hata', 'Ilan kaydedilemedi: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<List<String>> _uploadImages({
    required String uid,
    required String itemId,
  }) async {
    if (selectedImages.isEmpty) return const <String>[];
    final urls = <String>[];
    for (var i = 0; i < selectedImages.length; i++) {
      final file = selectedImages[i];
      final path = i == 0
          ? 'marketStore/$uid/$itemId/cover'
          : 'marketStore/$uid/$itemId/image_$i';
      final url = await WebpUploadService.uploadFileAsWebp(
        storage: FirebaseStorage.instance,
        file: file,
        storagePathWithoutExt: path,
      );
      urls.add(url);
    }
    return urls;
  }

  List<MarketLeafCategory> _flattenLeafCategories(
    Map<String, dynamic> node,
    List<String> path,
  ) {
    final children = (node['children'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    if (children.isEmpty) {
      final fields = (node['fields'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
      return <MarketLeafCategory>[
        MarketLeafCategory(
          key: (node['key'] ?? '').toString(),
          label: (node['label'] ?? '').toString(),
          pathLabels: path,
          fields: fields,
          meta: Map<String, dynamic>.from(node['meta'] as Map? ?? const {}),
        ),
      ];
    }

    final result = <MarketLeafCategory>[];
    for (final child in children) {
      result.addAll(
        _flattenLeafCategories(
          child,
          [...path, (child['label'] ?? '').toString()],
        ),
      );
    }
    return result;
  }

  void _prepareDynamicFields(List<Map<String, dynamic>> fields) {
    fieldValues.clear();
    final allowedKeys = fields
        .map((field) => (field['key'] ?? '').toString())
        .where((key) => key.trim().isNotEmpty)
        .toSet();
    final staleKeys = _fieldControllers.keys
        .where((key) => !allowedKeys.contains(key))
        .toList(growable: false);
    for (final key in staleKeys) {
      _fieldControllers.remove(key)?.dispose();
    }
    for (final field in fields) {
      final key = (field['key'] ?? '').toString();
      if (key.isEmpty) continue;
      if (fieldUsesTextInput(field)) {
        controllerForField(key).clear();
      }
    }
  }
}
