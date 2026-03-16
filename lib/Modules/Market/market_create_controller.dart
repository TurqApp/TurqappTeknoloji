import 'dart:convert';
import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Models/market_item_model.dart';
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
  String get pathTextWithoutTop =>
      pathLabels.length <= 1 ? pathText : pathLabels.skip(1).join(' > ');
}

class MarketCategoryNode {
  MarketCategoryNode({
    required this.key,
    required this.label,
    required this.pathLabels,
    required this.fields,
    required this.meta,
    required this.children,
  });

  final String key;
  final String label;
  final List<String> pathLabels;
  final List<Map<String, dynamic>> fields;
  final Map<String, dynamic> meta;
  final List<MarketCategoryNode> children;

  bool get isLeaf => children.isEmpty;

  MarketLeafCategory toLeaf() => MarketLeafCategory(
        key: key,
        label: label,
        pathLabels: pathLabels,
        fields: fields,
        meta: meta,
      );
}

class MarketCreateController extends GetxController {
  MarketCreateController({this.initialItem});

  final MarketSchemaService _schemaService = MarketSchemaService.ensure();
  final MarketRepository _repository = MarketRepository.ensure();
  final MarketItemModel? initialItem;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isResolvingLocation = false.obs;
  final RxList<Map<String, dynamic>> topCategories =
      <Map<String, dynamic>>[].obs;
  final RxList<List<MarketCategoryNode>> categoryLevels =
      <List<MarketCategoryNode>>[].obs;
  final RxList<MarketCategoryNode> selectedCategoryNodes =
      <MarketCategoryNode>[].obs;
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
  final RxList<String> existingImageUrls = <String>[].obs;

  final Map<String, TextEditingController> _fieldControllers =
      <String, TextEditingController>{};
  static const int maxImages = 4;
  MarketCategoryNode? _selectedTopNode;

  bool get isEditing => initialItem != null;
  int get totalImageCount => existingImageUrls.length + selectedImages.length;
  String get pageTitle => isEditing ? 'İlan Düzenle' : 'İlan Ekle';
  String get draftActionLabel => isEditing ? 'Taslak Güncelle' : 'Taslak';
  String get publishActionLabel => isEditing ? 'Güncelle' : 'Yayınla';
  String get selectedCategoryPathText =>
      selectedLeaf.value?.pathTextWithoutTop ?? '';

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
      final loadedCategories =
          _schemaService.categories().toList(growable: true)
            ..sort(
              (a, b) => compareTurkishStrings(
                (a['label'] ?? '').toString(),
                (b['label'] ?? '').toString(),
              ),
            );
      topCategories.assignAll(loadedCategories);
      await _loadCityDistricts();
      if (isEditing) {
        _hydrateInitialItem();
      } else if (topCategories.isNotEmpty) {
        selectTopCategory((topCategories.first['key'] ?? '').toString());
        await autoFillLocationIfNeeded();
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
      _selectedTopNode = null;
      categoryLevels.clear();
      selectedCategoryNodes.clear();
      leafCategories.clear();
      selectedLeaf.value = null;
      _prepareDynamicFields(const []);
      return;
    }
    _selectedTopNode = _buildCategoryNode(
      target,
      [(target['label'] ?? '').toString()],
    );
    final flattened = _flattenLeafCategories(_selectedTopNode!);
    leafCategories.assignAll(flattened);
    _rebuildCategorySelection();
  }

  void selectLeafCategory(String key) {
    final leaf = leafCategories.firstWhereOrNull((item) => item.key == key);
    if (leaf == null) return;
    selectedLeaf.value = leaf;
    _prepareDynamicFields(leaf.fields);
  }

  void selectNodeAtLevel(int level, String key) {
    if (level < 0 || level >= categoryLevels.length) return;
    final node = categoryLevels[level].firstWhereOrNull(
      (item) => item.key == key,
    );
    if (node == null) return;
    final preservedPath = <String>[
      for (var i = 0; i < level; i++) selectedCategoryNodes[i].key,
      node.key,
    ];
    _rebuildCategorySelection(preferredPathKeys: preservedPath);
  }

  List<MarketCategoryNode> optionsForLevel(int level) {
    if (level < 0 || level >= categoryLevels.length) return const [];
    return categoryLevels[level];
  }

  MarketCategoryNode? selectedNodeForLevel(int level) {
    if (level < 0 || level >= selectedCategoryNodes.length) return null;
    return selectedCategoryNodes[level];
  }

  bool shouldShowLevel(int level) => optionsForLevel(level).length > 1;

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

  Future<void> autoFillLocationIfNeeded() async {
    if (selectedCity.value.isNotEmpty && selectedDistrict.value.isNotEmpty) {
      return;
    }
    isResolvingLocation.value = true;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return;

      final place = placemarks.first;
      final cityCandidates = <String>[
        (place.administrativeArea ?? '').trim(),
        (place.locality ?? '').trim(),
      ];
      final districtCandidates = <String>[
        (place.subAdministrativeArea ?? '').trim(),
        (place.subLocality ?? '').trim(),
        (place.locality ?? '').trim(),
      ];

      final matchedCity = _matchCity(cityCandidates);
      if (matchedCity == null) return;
      selectedCity.value = matchedCity;
      final matchedDistrict = _matchDistrict(matchedCity, districtCandidates);
      if (matchedDistrict != null) {
        selectedDistrict.value = matchedDistrict;
      }
    } catch (_) {
      // Konum otomatik doldurma başarısızsa formu engelleme.
    } finally {
      isResolvingLocation.value = false;
    }
  }

  void setContactPreference(String value) {
    if (value == 'phone') {
      contactPreference.value = 'phone';
      return;
    }
    contactPreference.value = 'message_only';
  }

  List<String> get districtOptions {
    final city = selectedCity.value;
    if (city.isEmpty) return const <String>[];
    final districts = cityDistricts
        .where((item) => item.il == city)
        .map((item) => item.ilce)
        .toSet()
        .toList();
    sortTurkishStrings(districts);
    return districts;
  }

  bool fieldUsesTextInput(Map<String, dynamic> field) {
    final type = (field['type'] ?? 'select').toString();
    return type != 'select';
  }

  List<String> fieldOptions(Map<String, dynamic> field) {
    final key = (field['key'] ?? '').toString();
    var options = field['options'] as List<dynamic>? ?? const [];
    if (key == 'model' && options.isEmpty) {
      options = _dependentModelOptions();
    }
    final values = options
        .map((option) {
          if (option is Map) {
            return (option['label'] ?? option['key'] ?? '').toString();
          }
          return option.toString();
        })
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    sortTurkishStrings(values);
    return values;
  }

  TextEditingController controllerForField(String key) {
    return _fieldControllers.putIfAbsent(key, () => TextEditingController());
  }

  void setFieldValue(String key, String value) {
    if (key == 'marka') {
      final currentModel = fieldValues['model'] ?? '';
      final allowedModels = _dependentModelOptions()
          .map((option) => option is Map
              ? (option['label'] ?? option['key'] ?? '').toString()
              : option.toString())
          .where((option) => option.trim().isNotEmpty)
          .toSet();
      if (currentModel.isNotEmpty && !allowedModels.contains(currentModel)) {
        fieldValues.remove('model');
        _fieldControllers['model']?.clear();
      }
    }
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
    final remaining = maxImages - totalImageCount;
    if (remaining <= 0) {
      AppSnackbar('Sınır', 'En fazla $maxImages görsel ekleyebilirsin.');
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
    if (index < 0 || index >= totalImageCount) return;
    if (index < existingImageUrls.length) {
      existingImageUrls.removeAt(index);
      return;
    }
    selectedImages.removeAt(index - existingImageUrls.length);
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
    if (totalImageCount == 0) {
      AppSnackbar('Eksik Bilgi', 'Yayınlamak için en az bir görsel ekle.');
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
    final fullName = [
      current?.firstName ?? '',
      current?.lastName ?? '',
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    final nickname = (current?.nickname ?? '').trim();
    final displayName = fullName.isEmpty ? nickname : fullName;
    final avatarUrl = (current?.avatarUrl ?? '').trim();
    final showPhone = contactPreference.value == 'phone';
    final phoneNumber = showPhone ? _resolveSellerPhone(current) : '';
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
      'showPhone': showPhone,
      'status': _nextStatus(publish),
      'seller': {
        'userId': userId,
        'displayName': displayName.isEmpty ? 'Turq Kullanıcı' : displayName,
        'nickname': nickname,
        'avatarUrl': avatarUrl,
        'rozet': current?.rozet ?? '',
        'phoneNumber': phoneNumber,
        'isApproved': current?.hesapOnayi == true,
        // Geriye uyumlu alanlar
        'name': displayName.isEmpty ? 'Turq Kullanıcı' : displayName,
        'username': nickname,
        'photoUrl': avatarUrl,
        'verified': current?.hesapOnayi == true,
      },
      'sellerDisplayName': displayName.isEmpty ? 'Turq Kullanıcı' : displayName,
      'sellerNickname': nickname,
      'sellerAvatarUrl': avatarUrl,
      'sellerRozet': current?.rozet ?? '',
      'sellerName': displayName.isEmpty ? 'Turq Kullanıcı' : displayName,
      'sellerUsername': nickname,
      'sellerPhotoUrl': avatarUrl,
      'sellerPhoneNumber': phoneNumber,
      'coverImageUrl': imageUrls.isEmpty ? '' : imageUrls.first,
      'imageUrls': imageUrls,
      'imageCount': imageUrls.length,
      'isNegotiable': true,
      'updatedAt': now,
      'createdAt': initialItem?.createdAt ?? now,
      if (!isEditing) 'offerCount': 0,
      if (!isEditing) 'favoriteCount': 0,
      if (!isEditing) 'reportCount': 0,
      if (!isEditing) 'viewCount': 0,
      if (!isEditing) 'publishedAt': publish ? now : 0,
      if (isEditing && publish && initialItem?.status == 'draft')
        'publishedAt': now,
    };
  }

  String _resolveSellerPhone(dynamic current) {
    final values = <String>[
      (current?.phoneNumber ?? '').toString().trim(),
      (FirebaseAuth.instance.currentUser?.phoneNumber ?? '').toString().trim(),
    ];
    for (final value in values) {
      if (value.isNotEmpty) return value;
    }
    return '';
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
        return 'Geçerli bir fiyat gir.';
      }
    }
    if (selectedCity.value.isEmpty || selectedDistrict.value.isEmpty) {
      return 'Şehir ve ilçe seçimi gerekli.';
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
      final cityList = data.map((item) => item.il).toSet().toList();
      sortTurkishStrings(cityList);
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
      AppSnackbar('Hata', 'Kullanıcı oturumu bulunamadı.');
      return;
    }

    final itemId =
        initialItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
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
      FocusManager.instance.primaryFocus?.unfocus();
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
      final context = Get.context;
      if (context != null && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(payload);
      } else {
        Get.back(result: payload);
      }
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
    if (selectedImages.isEmpty)
      return existingImageUrls.toList(growable: false);
    final urls = existingImageUrls.toList(growable: true);
    for (var i = 0; i < selectedImages.length; i++) {
      final file = selectedImages[i];
      final imageIndex = existingImageUrls.length + i;
      final path = imageIndex == 0
          ? 'marketStore/$uid/$itemId/cover'
          : 'marketStore/$uid/$itemId/image_$imageIndex';
      final url = await WebpUploadService.uploadFileAsWebp(
        storage: FirebaseStorage.instance,
        file: file,
        storagePathWithoutExt: path,
      );
      urls.add(url);
    }
    return urls;
  }

  void _hydrateInitialItem() {
    final item = initialItem;
    if (item == null) return;
    titleController.text = item.title;
    descriptionController.text = item.description;
    if (item.price > 0) {
      priceController.text = item.price.toStringAsFixed(0);
    }
    selectedCity.value = item.city;
    selectedDistrict.value = item.district;
    contactPreference.value = item.contactPreference;
    final initialUrls = item.imageUrls
        .where((url) => url.trim().isNotEmpty)
        .toList(growable: true);
    if (initialUrls.isEmpty && item.coverImageUrl.trim().isNotEmpty) {
      initialUrls.add(item.coverImageUrl);
    }
    existingImageUrls.assignAll(initialUrls);

    final match = _findLeafByKey(item.categoryKey);
    if (match != null) {
      selectedTopKey.value = match.$1;
      _selectedTopNode = _buildCategoryNode(
        match.$4,
        [(match.$4['label'] ?? '').toString()],
      );
      leafCategories.assignAll(match.$2);
      _rebuildCategorySelection(
        preferredPathKeys:
            _pathKeysForLeaf(_selectedTopNode!, item.categoryKey),
      );
    } else if (topCategories.isNotEmpty) {
      selectTopCategory((topCategories.first['key'] ?? '').toString());
    }

    final leaf = selectedLeaf.value;
    if (leaf != null) {
      for (final field in leaf.fields) {
        final fieldKey = (field['key'] ?? '').toString();
        final label = (field['label'] ?? fieldKey).toString();
        final value =
            (item.attributes[label] ?? item.attributes[fieldKey] ?? '')
                .toString();
        if (value.trim().isEmpty) continue;
        setFieldValue(fieldKey, value);
      }
    }
  }

  (String, List<MarketLeafCategory>, MarketLeafCategory, Map<String, dynamic>)?
      _findLeafByKey(
    String categoryKey,
  ) {
    for (final category in topCategories) {
      final topKey = (category['key'] ?? '').toString();
      final node = _buildCategoryNode(
        category,
        [(category['label'] ?? '').toString()],
      );
      final flattened = _flattenLeafCategories(node);
      final leaf =
          flattened.firstWhereOrNull((item) => item.key == categoryKey);
      if (leaf != null) {
        return (topKey, flattened, leaf, category);
      }
    }
    return null;
  }

  String _nextStatus(bool publish) {
    if (!publish) return 'draft';
    if (!isEditing) return 'active';
    if (initialItem?.status == 'draft') return 'active';
    return initialItem?.status ?? 'active';
  }

  MarketCategoryNode _buildCategoryNode(
    Map<String, dynamic> node,
    List<String> path,
  ) {
    final rawChildren = (node['children'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    final children = <MarketCategoryNode>[];
    final seen = <String>{};
    for (final child in rawChildren) {
      final label = (child['label'] ?? '').toString().trim();
      if (label.isEmpty) continue;
      final dedupeKey =
          '${_normalizeNodeKey(label)}|${(child['key'] ?? '').toString().trim()}';
      if (!seen.add(dedupeKey)) continue;
      children.add(_buildCategoryNode(child, _appendPath(path, label)));
    }
    children.sort((a, b) => compareTurkishStrings(a.label, b.label));

    return MarketCategoryNode(
      key: (node['key'] ?? '').toString(),
      label: (node['label'] ?? '').toString(),
      pathLabels: path,
      fields: (node['fields'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false),
      meta: Map<String, dynamic>.from(node['meta'] as Map? ?? const {}),
      children: children,
    );
  }

  List<MarketLeafCategory> _flattenLeafCategories(MarketCategoryNode node) {
    if (node.children.isEmpty) {
      return <MarketLeafCategory>[node.toLeaf()];
    }

    final result = <MarketLeafCategory>[];
    for (final child in node.children) {
      result.addAll(_flattenLeafCategories(child));
    }
    return result;
  }

  void _rebuildCategorySelection({List<String>? preferredPathKeys}) {
    categoryLevels.clear();
    selectedCategoryNodes.clear();
    final topNode = _selectedTopNode;
    if (topNode == null) {
      selectedLeaf.value = null;
      _prepareDynamicFields(const []);
      return;
    }

    if (topNode.isLeaf) {
      selectedLeaf.value = topNode.toLeaf();
      _prepareDynamicFields(topNode.fields);
      return;
    }

    var options = topNode.children;
    var level = 0;
    final selected = <MarketCategoryNode>[];

    while (options.isNotEmpty) {
      categoryLevels.add(options);
      MarketCategoryNode? nextSelection;
      if (preferredPathKeys != null && level < preferredPathKeys.length) {
        nextSelection = options.firstWhereOrNull(
          (node) => node.key == preferredPathKeys[level],
        );
      }
      nextSelection ??= options.length == 1 ? options.first : null;
      if (nextSelection == null) break;
      selected.add(nextSelection);
      options = nextSelection.children;
      level++;
    }

    selectedCategoryNodes.assignAll(selected);
    final leafNode =
        selected.isNotEmpty && selected.last.isLeaf ? selected.last : null;
    if (leafNode == null) {
      selectedLeaf.value = null;
      _prepareDynamicFields(const []);
      return;
    }
    selectedLeaf.value = leafNode.toLeaf();
    _prepareDynamicFields(leafNode.fields);
  }

  List<String>? _pathKeysForLeaf(MarketCategoryNode node, String targetKey) {
    return _findPathKeys(node, targetKey, <String>[]);
  }

  List<String>? _findPathKeys(
    MarketCategoryNode node,
    String targetKey,
    List<String> path,
  ) {
    for (final child in node.children) {
      final nextPath = [...path, child.key];
      if (child.key == targetKey) {
        return nextPath;
      }
      final nested = _findPathKeys(child, targetKey, nextPath);
      if (nested != null) return nested;
    }
    return null;
  }

  List<String> _appendPath(List<String> path, String label) {
    if (path.isNotEmpty &&
        _normalizeNodeKey(path.last) == _normalizeNodeKey(label)) {
      return path;
    }
    return [...path, label];
  }

  String _normalizeNodeKey(String value) => value.trim().toLowerCase();

  String? _matchCity(List<String> candidates) {
    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      for (final city in cities) {
        if (_normalizeText(city) == _normalizeText(candidate)) {
          return city;
        }
      }
    }
    return null;
  }

  String? _matchDistrict(String city, List<String> candidates) {
    final districts = cityDistricts
        .where((item) => item.il == city)
        .map((item) => item.ilce)
        .toSet()
        .toList(growable: false);
    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      for (final district in districts) {
        if (_normalizeText(district) == _normalizeText(candidate)) {
          return district;
        }
      }
    }
    return null;
  }

  String _normalizeText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
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

  List<dynamic> _dependentModelOptions() {
    final marka = fieldValues['marka']?.trim() ?? '';
    if (marka.isEmpty) return const <dynamic>[];
    final leaf = selectedLeaf.value;
    if (leaf == null) return const <dynamic>[];
    final markaField = leaf.fields.firstWhereOrNull(
      (field) => (field['key'] ?? '').toString() == 'marka',
    );
    if (markaField == null) return const <dynamic>[];
    final markaOptions =
        markaField['options'] as List<dynamic>? ?? const <dynamic>[];
    for (final option in markaOptions) {
      if (option is! Map) continue;
      final label = (option['label'] ?? option['key'] ?? '').toString().trim();
      if (label == marka) {
        return option['options'] as List<dynamic>? ?? const <dynamic>[];
      }
    }
    return const <dynamic>[];
  }
}
