part of 'market_create_controller.dart';

class _MarketCreateControllerState {
  _MarketCreateControllerState({required this.initialItem});

  final schemaService = ensureMarketSchemaService();
  final repository = ensureMarketRepository();
  final cityDirectoryService = ensureCityDirectoryService();
  final MarketItemModel? initialItem;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final isResolvingLocation = false.obs;
  final topCategories = <Map<String, dynamic>>[].obs;
  final categoryLevels = <List<MarketCategoryNode>>[].obs;
  final selectedCategoryNodes = <MarketCategoryNode>[].obs;
  final leafCategories = <MarketLeafCategory>[].obs;
  final selectedLeaf = Rxn<MarketLeafCategory>();
  final selectedTopKey = ''.obs;
  final selectedCity = ''.obs;
  final selectedDistrict = ''.obs;
  final contactPreference = 'message_only'.obs;
  final fieldValues = <String, String>{}.obs;
  final cityDistricts = <CitiesModel>[].obs;
  final cities = <String>[].obs;
  final selectedImages = <File>[].obs;
  final existingImageUrls = <String>[].obs;
  final fieldControllers = <String, TextEditingController>{};
  MarketCategoryNode? selectedTopNode;
}

extension MarketCreateControllerFieldsPart on MarketCreateController {
  MarketSchemaService get _schemaService => _state.schemaService;
  MarketRepository get _repository => _state.repository;
  CityDirectoryService get _cityDirectoryService => _state.cityDirectoryService;
  MarketItemModel? get initialItem => _state.initialItem;
  TextEditingController get titleController => _state.titleController;
  TextEditingController get descriptionController =>
      _state.descriptionController;
  TextEditingController get priceController => _state.priceController;
  RxBool get isLoading => _state.isLoading;
  RxBool get isSubmitting => _state.isSubmitting;
  RxBool get isResolvingLocation => _state.isResolvingLocation;
  RxList<Map<String, dynamic>> get topCategories => _state.topCategories;
  RxList<List<MarketCategoryNode>> get categoryLevels => _state.categoryLevels;
  RxList<MarketCategoryNode> get selectedCategoryNodes =>
      _state.selectedCategoryNodes;
  RxList<MarketLeafCategory> get leafCategories => _state.leafCategories;
  Rxn<MarketLeafCategory> get selectedLeaf => _state.selectedLeaf;
  RxString get selectedTopKey => _state.selectedTopKey;
  RxString get selectedCity => _state.selectedCity;
  RxString get selectedDistrict => _state.selectedDistrict;
  RxString get contactPreference => _state.contactPreference;
  RxMap<String, String> get fieldValues => _state.fieldValues;
  RxList<CitiesModel> get cityDistricts => _state.cityDistricts;
  RxList<String> get cities => _state.cities;
  RxList<File> get selectedImages => _state.selectedImages;
  RxList<String> get existingImageUrls => _state.existingImageUrls;
  Map<String, TextEditingController> get _fieldControllers =>
      _state.fieldControllers;
  MarketCategoryNode? get _selectedTopNode => _state.selectedTopNode;
  set _selectedTopNode(MarketCategoryNode? value) =>
      _state.selectedTopNode = value;
}
