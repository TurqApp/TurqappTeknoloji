part of 'antreman_controller.dart';

AntremanController ensureAntremanController({bool permanent = false}) {
  final existing = maybeFindAntremanController();
  if (existing != null) return existing;
  return Get.put(AntremanController(), permanent: permanent);
}

AntremanController? maybeFindAntremanController() {
  final isRegistered = Get.isRegistered<AntremanController>();
  if (!isRegistered) return null;
  return Get.find<AntremanController>();
}

const String _mainCategoryPrefKeyPrefix = 'antreman_main_category';
const String _categoryCachePrefix = 'antreman_category_cache_';
const String _categoryCacheTimePrefix = 'antreman_category_cache_time_';
const Duration _categoryCacheTtl = Duration(hours: 12);
const int _mainCategoryWarmupLimit = 10;

extension AntremanControllerSupportPart on AntremanController {
  String get _activeUid {
    final uid = CurrentUserService.instance.effectiveUserId;
    return uid.isEmpty ? 'guest' : uid;
  }

  String get _mainCategoryPrefKey => '$_mainCategoryPrefKeyPrefix:$_activeUid';

  List<String> get mainCategories => const <String>[
        'LGS',
        'YKS',
        'KPSS',
        'YDS',
        'ALES',
        'DGS',
        'DUS',
        'TUS',
      ];

  List<String> get visibleMainCategories => mainCategory.value.isEmpty
      ? mainCategories
      : <String>[mainCategory.value];

  bool get hasActiveSearch => searchQuery.value.trim().length >= 2;
}
