import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Themes/app_icons.dart';

class ListBottomSheet extends StatefulWidget {
  final List<dynamic> list;
  final Function(dynamic) onBackData;
  final Function(List<dynamic>)? onBackUpdatedList;
  final String title;
  final dynamic startSelection;

  const ListBottomSheet({
    required this.list,
    required this.onBackData,
    required this.title,
    required this.startSelection,
    this.onBackUpdatedList,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required List<dynamic> items,
    required String title,
    required Function(dynamic) onSelect,
    dynamic selectedItem,
    bool isSearchable = false,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return ListBottomSheet(
          list: items,
          title: title,
          startSelection: selectedItem,
          onBackData: onSelect,
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

  @override
  void initState() {
    super.initState();
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
    searchController.dispose();
    searchFocusNode.dispose();
    focusNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ListBottomSheetController());
    controller.initSingleSelection(widget.list, widget.startSelection);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Search TextField
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
                      hintText: "Ara",
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
                                  controller.filterList("", widget.list);
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
                    onChanged: (value) =>
                        controller.filterList(value, widget.list),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: MediaQuery.of(context).size.width,
              child: Obx(
                () => controller.list.isEmpty
                    ? const Center(
                        child: Text(
                          "Sonuç bulunamadı",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      )
                    : ListView.builder(
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
                                          item.toString(),
                                          style: TextStyle(
                                            color: controller
                                                        .startSelection.value ==
                                                    item
                                                ? Colors.pinkAccent
                                                : Colors.black,
                                            fontSize: 16,
                                            fontFamily: controller
                                                        .startSelection.value ==
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
                                              color: controller.startSelection
                                                          .value ==
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
      ),
    );
  }
}

class ListBottomSheetController extends GetxController {
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

  void filterList(String query, List<dynamic> originalList) {
    searchQuery.value = query;
    if (query.isEmpty) {
      list.value = originalList;
    } else {
      list.value = originalList
          .where(
            (item) =>
                item.toString().toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
  }
}
