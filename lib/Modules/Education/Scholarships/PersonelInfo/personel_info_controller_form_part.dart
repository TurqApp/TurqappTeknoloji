part of 'personel_info_controller.dart';

extension PersonelInfoControllerFormPart on PersonelInfoController {
  void initializeFieldConfigs() {
    fieldConfigs = [
      FieldConfig(
        label: _countryFieldLabel,
        title: _countryFieldTitleKey,
        value: county,
        items: countryList,
        onSelect: (val) {
          county.value = val;
          if (val != _turkey) {
            city.value = '';
            town.value = '';
          }
        },
        isSearchable: true,
      ),
      FieldConfig(
        label: _maritalStatusFieldLabel,
        title: _maritalStatusFieldTitleKey,
        value: medeniHal,
        items: medeniHalList,
        onSelect: (val) => medeniHal.value = val,
      ),
      FieldConfig(
        label: _genderFieldLabel,
        title: _genderFieldTitleKey,
        value: cinsiyet,
        items: cinsiyetList,
        onSelect: (val) => cinsiyet.value = val,
      ),
      FieldConfig(
        label: _disabilityFieldLabel,
        title: _disabilityFieldTitleKey,
        value: engelliRaporu,
        items: engelliRaporuList,
        onSelect: (val) => engelliRaporu.value = val,
      ),
      FieldConfig(
        label: _employmentFieldLabel,
        title: _employmentFieldTitleKey,
        value: calismaDurumu,
        items: calismaDurumuList,
        onSelect: (val) => calismaDurumu.value = val,
      ),
    ];
  }

  void initializeAnimationControllers() {
    for (final config in fieldConfigs) {
      _animationControllers[config.label] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      );
      _animationTurns[config.label] = 0.0.obs;
      _animationControllers[config.label]!.addListener(() {
        _animationTurns[config.label]!.value =
            _animationControllers[config.label]!.value * 0.5;
      });
    }

    _animationControllers[_cityFieldLabel] = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationTurns[_cityFieldLabel] = 0.0.obs;
    _animationControllers[_cityFieldLabel]!.addListener(() {
      _animationTurns[_cityFieldLabel]!.value =
          _animationControllers[_cityFieldLabel]!.value * 0.5;
    });

    _animationControllers[_districtFieldLabel] = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationTurns[_districtFieldLabel] = 0.0.obs;
    _animationControllers[_districtFieldLabel]!.addListener(() {
      _animationTurns[_districtFieldLabel]!.value =
          _animationControllers[_districtFieldLabel]!.value * 0.5;
    });
  }

  void disposeAnimationControllers() {
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    _animationTurns.clear();
  }

  AnimationController getAnimationController(String label) {
    return _animationControllers[label]!;
  }

  RxDouble getAnimationTurns(String label) {
    return _animationTurns[label]!;
  }

  Future<void> toggleDropdown(BuildContext context, FieldConfig config) async {
    final animationController = _animationControllers[config.label];
    if (animationController == null) return;

    animationController.forward();

    if ([
      _maritalStatusFieldLabel,
      _genderFieldLabel,
      _disabilityFieldLabel,
      _employmentFieldLabel,
    ].contains(config.label)) {
      final localizedItems = config.items.map(localizedStaticValue).toList();
      await AppBottomSheet.show(
        context: context,
        items: localizedItems,
        title: localizedFieldTitle(config.title),
        onSelect: (dynamic val) {
          final selectedIndex = localizedItems.indexOf(val as String);
          config.onSelect(
            selectedIndex >= 0 ? config.items[selectedIndex] : val,
          );
        },
        selectedItem: config.value.value.isEmpty
            ? null
            : localizedStaticValue(config.value.value),
        isSearchable: config.isSearchable,
      );
    } else {
      final useLocalizedLabels = config.label == _countryFieldLabel;
      await ListBottomSheet.show(
        context: context,
        items: config.items,
        title: localizedFieldTitle(config.title),
        onSelect: (dynamic val) => config.onSelect(val as String),
        selectedItem: config.value.value.isEmpty ? null : config.value.value,
        isSearchable: config.isSearchable,
        itemLabelBuilder:
            useLocalizedLabels ? (item) => localizedStaticValue('$item') : null,
        searchTextBuilder:
            useLocalizedLabels ? (item) => localizedStaticValue('$item') : null,
      );
    }

    animationController.reverse();
  }
}
