part of 'market_create_controller.dart';

extension MarketCreateControllerFormPart on MarketCreateController {
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

  Future<void> _loadCityDistricts() async {
    try {
      final data = await _cityDirectoryService.getCitiesAndDistricts();
      cityDistricts.assignAll(data);
      cities.assignAll(await _cityDirectoryService.getSortedCities());
    } catch (_) {
      cities.clear();
      cityDistricts.clear();
    }
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
          '${normalizeMarketNodeKey(label)}|${(child['key'] ?? '').toString().trim()}';
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
        normalizeMarketNodeKey(path.last) == normalizeMarketNodeKey(label)) {
      return path;
    }
    return [...path, label];
  }

  String? _matchCity(List<String> candidates) {
    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      for (final city in cities) {
        if (normalizeSearchText(city) == normalizeSearchText(candidate)) {
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
        if (normalizeSearchText(district) == normalizeSearchText(candidate)) {
          return district;
        }
      }
    }
    return null;
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
