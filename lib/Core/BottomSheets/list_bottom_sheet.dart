import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Themes/app_icons.dart';

class ListBottomSheet extends StatefulWidget {
  final List<dynamic> list;
  final Function(dynamic) onBackData;
  final Function(List<dynamic>)? onBackUpdatedList;
  final String title;
  final String searchHintText;
  final dynamic startSelection;
  final String Function(dynamic item)? searchTextBuilder;
  final String Function(dynamic item)? itemLabelBuilder;

  const ListBottomSheet({
    required this.list,
    required this.onBackData,
    required this.title,
    this.searchHintText = "common.search",
    required this.startSelection,
    this.onBackUpdatedList,
    this.searchTextBuilder,
    this.itemLabelBuilder,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required List<dynamic> items,
    required String title,
    required Function(dynamic) onSelect,
    dynamic selectedItem,
    bool isSearchable = false,
    String searchHintText = "common.search",
    String Function(dynamic item)? searchTextBuilder,
    String Function(dynamic item)? itemLabelBuilder,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: FractionallySizedBox(
            heightFactor: bottomInset > 0 ? 0.88 : 0.72,
            child: ListBottomSheet(
              list: items,
              title: title,
              searchHintText: searchHintText,
              startSelection: selectedItem,
              onBackData: onSelect,
              searchTextBuilder: searchTextBuilder,
              itemLabelBuilder: itemLabelBuilder,
            ),
          ),
        );
      },
    );
  }

  @override
  _ListBottomSheetState createState() => _ListBottomSheetState();
}

class _ListBottomSheetState extends State<ListBottomSheet> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  late ValueNotifier<bool> focusNotifier;
  late final String _controllerTag;
  late final ListBottomSheetController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controllerTag = '${widget.title}_${identityHashCode(this)}';
    final existingController =
        ListBottomSheetController.maybeFind(tag: _controllerTag);
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = ListBottomSheetController.ensure(
        tag: _controllerTag,
      );
      _ownsController = true;
    }
    controller.initSingleSelection(widget.list, widget.startSelection);
    // ValueNotifier'ı başlat
    focusNotifier = ValueNotifier<bool>(searchFocusNode.hasFocus);
    // FocusNode'a listener ekle
    searchFocusNode.addListener(() {
      focusNotifier.value = searchFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    // Temizlik
    if (_ownsController &&
        identical(
          ListBottomSheetController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<ListBottomSheetController>(tag: _controllerTag);
    }
    searchController.dispose();
    searchFocusNode.dispose();
    focusNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ListBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.list != widget.list ||
        oldWidget.startSelection != widget.startSelection) {
      controller.initSingleSelection(widget.list, widget.startSelection);
      if (searchController.text.isNotEmpty) {
        controller.filterList(
          searchController.text,
          widget.list,
          searchTextBuilder: widget.searchTextBuilder,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          AppSheetHeader(title: widget.title),
          ValueListenableBuilder<bool>(
            valueListenable: focusNotifier,
            builder: (context, hasFocus, child) {
              return Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: TextField(
                  cursorColor: Colors.black,
                  controller: searchController,
                  focusNode: searchFocusNode,
                  decoration: InputDecoration(
                    hintText: widget.searchHintText.tr,
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontFamily: "MontserratMedium",
                    ),
                    border: InputBorder.none,
                    prefixIcon: Obx(
                      () => controller.searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                searchController.clear();
                                controller.filterList(
                                  "",
                                  widget.list,
                                  searchTextBuilder: widget.searchTextBuilder,
                                );
                              },
                            )
                          : const Icon(
                              AppIcons.search,
                              color: Colors.pinkAccent,
                            ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  ),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "Montserrat",
                  ),
                  textAlignVertical: TextAlignVertical.center,
                  onChanged: (value) => controller.filterList(
                    value,
                    widget.list,
                    searchTextBuilder: widget.searchTextBuilder,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(
              () => controller.list.isEmpty
                  ? Center(
                      child: Text(
                        'explore.no_results'.tr,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    )
                  : ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: controller.list.length,
                      itemBuilder: (context, index) {
                        final item = controller.list[index];
                        return GestureDetector(
                          onTap: () {
                            controller.selectItem(item, widget.onBackData);
                            if (widget.onBackUpdatedList != null) {
                              widget.onBackUpdatedList!(
                                controller.list.toList(),
                              );
                            }
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.itemLabelBuilder?.call(item) ??
                                            item.toString(),
                                        style: TextStyle(
                                          color:
                                              controller.startSelection.value ==
                                                      item
                                                  ? Colors.pinkAccent
                                                  : Colors.black,
                                          fontSize: 16,
                                          fontFamily:
                                              controller.startSelection.value ==
                                                      item
                                                  ? "MontserratBold"
                                                  : "MontserratMedium",
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 25,
                                      height: 25,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: Container(
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: controller
                                                        .startSelection.value ==
                                                    item
                                                ? Colors.black
                                                : Colors.transparent,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(color: Colors.grey.withAlpha(20)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class ListBottomSheetController extends GetxController {
  static ListBottomSheetController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ListBottomSheetController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static ListBottomSheetController? maybeFind({String? tag}) {
    if (!Get.isRegistered<ListBottomSheetController>(tag: tag)) return null;
    return Get.find<ListBottomSheetController>(tag: tag);
  }

  final list = <dynamic>[].obs;
  final selectedItems = <String>[].obs;
  final startSelection = "".obs;
  final searchQuery = "".obs;

  void initSingleSelection(List<dynamic> items, dynamic initialSelection) {
    list.value = items;
    startSelection.value = initialSelection?.toString() ?? "";
    list.value = items;
  }

  void initMultiSelection(List<String> initialSelections) {
    selectedItems.value = initialSelections;
  }

  void selectItem(dynamic item, Function(dynamic) onBackData) {
    startSelection.value = item.toString();
    onBackData(item);
    Get.back();
  }

  void toggleSelection(String item) {
    if (selectedItems.contains(item)) {
      selectedItems.remove(item);
    } else {
      selectedItems.add(item);
    }
  }

  void confirmMultiSelection(Function(List<String>) onBackData) {
    onBackData(selectedItems);
    Get.back();
  }

  void filterList(
    String query,
    List<dynamic> originalList, {
    String Function(dynamic item)? searchTextBuilder,
  }) {
    searchQuery.value = query;
    if (query.isEmpty) {
      list.value = originalList;
    } else {
      final normalizedQuery = normalizeSearchText(query);
      list.value = originalList
          .where(
            (item) => normalizeSearchText(
              searchTextBuilder?.call(item) ?? item.toString(),
            ).contains(normalizedQuery),
          )
          .toList();
    }
  }
}
