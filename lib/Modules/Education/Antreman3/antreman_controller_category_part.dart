part of 'antreman_controller.dart';

extension AntremanControllerCategoryPart on AntremanController {
  Future<void> loadMainCategory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_mainCategoryPrefKey) ?? '';
      if (saved.isNotEmpty && subjects.containsKey(saved)) {
        mainCategory.value = saved;
      } else {
        mainCategory.value = '';
      }
    } catch (_) {
      mainCategory.value = '';
    } finally {
      mainCategoryLoaded.value = true;
    }
  }

  Future<void> setMainCategory(String category) async {
    if (!subjects.containsKey(category)) return;
    mainCategory.value = category;
    expandedIndex.value = -1;
    expandedSubIndex.value = -1;
    _mainCategoryPromptShown = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mainCategoryPrefKey, category);
    unawaited(_prefetchSelectedMainCategoryOnWifi(category));
  }

  Future<void> openMainCategoryPicker(
    BuildContext context, {
    bool force = false,
  }) async {
    if (!mainCategoryLoaded.value) {
      await loadMainCategory();
    }
    if (!force && mainCategory.value.isNotEmpty) return;
    if (_mainCategoryPromptShown && !force) return;
    _mainCategoryPromptShown = true;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: !force,
      enableDrag: !force,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.72;
        return PopScope(
          canPop: !force,
          child: SafeArea(
            child: SizedBox(
              height: maxHeight,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  MediaQuery.of(sheetContext).padding.bottom + 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'training.select_main_category_title'.tr,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!force)
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'training.select_main_category_body'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView.separated(
                        itemCount: mainCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final category = mainCategories[index];
                          final selected = category == mainCategory.value;
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              await setMainCategory(category);
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              height: 52,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: getRandomColor(index),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? Colors.black.withValues(alpha: 0.35)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      category,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    selected
                                        ? CupertinoIcons
                                            .check_mark_circled_solid
                                        : CupertinoIcons.chevron_right,
                                    size: 19,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    _mainCategoryPromptShown = false;
  }

  Color getRandomColor(int index) {
    final colors = <Color>[
      Colors.blue.shade900,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber.shade900,
      Colors.pink,
      Colors.indigo,
      Colors.brown,
      Colors.cyan,
      Colors.lime.shade700,
      Colors.amber,
      Colors.black54,
      Colors.orange.shade400,
      Colors.red.shade900,
    ];
    return colors[index % colors.length];
  }
}
