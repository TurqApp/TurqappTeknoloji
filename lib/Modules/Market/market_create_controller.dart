import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/user_moderation_guard.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_category_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import 'market_schema_service.dart';

part 'market_create_controller_form_part.dart';
part 'market_create_controller_submission_part.dart';
part 'market_create_controller_models_part.dart';

class MarketCreateController extends GetxController {
  static MarketCreateController ensure({
    MarketItemModel? initialItem,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MarketCreateController(initialItem: initialItem),
      tag: tag,
      permanent: permanent,
    );
  }

  static MarketCreateController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<MarketCreateController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MarketCreateController>(tag: tag);
  }

  MarketCreateController({this.initialItem});

  final MarketSchemaService _schemaService = MarketSchemaService.ensure();
  final MarketRepository _repository = MarketRepository.ensure();
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
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
  String get pageTitle => isEditing
      ? 'pasaj.market.create.edit_title'.tr
      : 'pasaj.market.create.add_title'.tr;
  String get draftActionLabel => isEditing
      ? 'pasaj.market.create.update_draft'.tr
      : 'pasaj.market.status.draft'.tr;
  String get publishActionLabel =>
      isEditing ? 'common.update'.tr : 'common.publish'.tr;
  String get selectedCategoryPathText =>
      selectedLeaf.value?.pathTextWithoutTop ?? '';

  @override
  void onInit() {
    super.onInit();
    _handleMarketCreateInit();
  }

  @override
  void onClose() {
    _handleMarketCreateClose();
    super.onClose();
  }
}
