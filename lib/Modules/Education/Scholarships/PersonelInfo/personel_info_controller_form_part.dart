part of 'personel_info_controller.dart';

extension PersonelInfoControllerFormPart on PersonelInfoController {
  void initializeFieldConfigs() {
    fieldConfigs = [
      FieldConfig(
        label: PersonelInfoController._countryFieldLabel,
        title: PersonelInfoController._countryFieldTitleKey,
        value: county,
        items: countryList,
        onSelect: (val) {
          county.value = val;
          if (val != PersonelInfoController._turkey) {
            city.value = '';
            town.value = '';
          }
        },
        isSearchable: true,
      ),
      FieldConfig(
        label: PersonelInfoController._maritalStatusFieldLabel,
        title: PersonelInfoController._maritalStatusFieldTitleKey,
        value: medeniHal,
        items: medeniHalList,
        onSelect: (val) => medeniHal.value = val,
      ),
      FieldConfig(
        label: PersonelInfoController._genderFieldLabel,
        title: PersonelInfoController._genderFieldTitleKey,
        value: cinsiyet,
        items: cinsiyetList,
        onSelect: (val) => cinsiyet.value = val,
      ),
      FieldConfig(
        label: PersonelInfoController._disabilityFieldLabel,
        title: PersonelInfoController._disabilityFieldTitleKey,
        value: engelliRaporu,
        items: engelliRaporuList,
        onSelect: (val) => engelliRaporu.value = val,
      ),
      FieldConfig(
        label: PersonelInfoController._employmentFieldLabel,
        title: PersonelInfoController._employmentFieldTitleKey,
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

    _animationControllers[PersonelInfoController._cityFieldLabel] =
        AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationTurns[PersonelInfoController._cityFieldLabel] = 0.0.obs;
    _animationControllers[PersonelInfoController._cityFieldLabel]!
        .addListener(() {
      _animationTurns[PersonelInfoController._cityFieldLabel]!.value =
          _animationControllers[PersonelInfoController._cityFieldLabel]!.value *
              0.5;
    });

    _animationControllers[PersonelInfoController._districtFieldLabel] =
        AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationTurns[PersonelInfoController._districtFieldLabel] = 0.0.obs;
    _animationControllers[PersonelInfoController._districtFieldLabel]!
        .addListener(() {
      _animationTurns[PersonelInfoController._districtFieldLabel]!.value =
          _animationControllers[PersonelInfoController._districtFieldLabel]!
                  .value *
              0.5;
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
      PersonelInfoController._maritalStatusFieldLabel,
      PersonelInfoController._genderFieldLabel,
      PersonelInfoController._disabilityFieldLabel,
      PersonelInfoController._employmentFieldLabel,
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
      final useLocalizedLabels =
          config.label == PersonelInfoController._countryFieldLabel;
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
