part of 'education_info_controller.dart';

extension EducationInfoControllerFacadePart on EducationInfoController {
  String get middleSchoolValue => EducationInfoController._middleSchool;
  String get highSchoolValue => EducationInfoController._highSchool;
  String get associateValue => EducationInfoController._associate;
  String get bachelorValue => EducationInfoController._bachelor;
  String get mastersValue => EducationInfoController._masters;
  String get doctorateValue => EducationInfoController._doctorate;

  Future<void> loadInitialData() => _loadInitialDataImpl();

  Future<void> loadSavedData() => _loadSavedDataImpl();

  void updateContent() => content.value = '';

  Future<void> loadSavedDataForLevel(String level) =>
      _loadSavedDataForLevelImpl(level);

  bool hasDataForLevel(String level) => _hasDataForLevelImpl(level);

  void clearFields() => _clearFieldsImpl();

  void clearOtherEducationFields(String currentLevel) =>
      _clearOtherEducationFieldsImpl(currentLevel);

  Future<void> saveMiddleSchool() => _saveMiddleSchoolImpl();

  Future<void> saveHighSchool() => _saveHighSchoolImpl();

  Future<void> saveHigherEducation() => _saveHigherEducationImpl();

  Future<void> showBottomSheet(
    BuildContext context,
    List<String> items,
    String title,
    Function(String) onSelect, {
    String? selectedItem,
    bool isSearchable = false,
  }) =>
      _showBottomSheetImpl(
        context,
        items,
        title,
        onSelect,
        selectedItem: selectedItem,
        isSearchable: isSearchable,
      );
}
