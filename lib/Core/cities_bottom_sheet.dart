import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

class CitiesBottomSheet {
  static Future<void> show({
    required BuildContext context,
    required List<String> items,
    required String title,
    required Function(String) onSelect,
    String? selectedItem,
    bool isSearchable = false,
  }) async {
    if (items.isEmpty) {
      AppSnackbar("Hata", "$title yüklenemedi. Lütfen tekrar deneyin.");
      return;
    }

    final TextEditingController searchController = TextEditingController();
    final RxList<String> filteredItems = items.toList().obs;

    void filterItems(String query) {
      filteredItems.value = items
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = screenHeight * 0.8 - keyboardHeight;

    await Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      Padding(
        padding: EdgeInsets.only(bottom: keyboardHeight, top: 15),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxHeight.clamp(200, screenHeight * 0.6),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSheetHeader(
                  title: title,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                ),
                if (isSearchable)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                      ),
                      child: TextField(
                        cursorColor: Colors.grey,
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: "Ara",
                          prefixIcon: const Icon(
                            CupertinoIcons.search,
                            color: Colors.grey,
                            size: 24,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: filterItems,
                      ),
                    ),
                  ),
                Obx(
                  () => Container(
                    constraints: BoxConstraints(
                      maxHeight: maxHeight.clamp(200, screenHeight * 0.8),
                    ),
                    child: filteredItems.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text("Sonuç bulunamadı"),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final isSelected =
                                  filteredItems[index] == selectedItem;
                              return Column(
                                children: [
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 0,
                                      horizontal: 15,
                                    ),
                                    title: Text(filteredItems[index]),
                                    trailing: isSelected
                                        ? const Icon(
                                            CupertinoIcons.check_mark_circled,
                                            color: Colors.green,
                                          )
                                        : Icon(
                                            CupertinoIcons.circle,
                                            color: Colors.grey.shade200,
                                          ),
                                    onTap: () {
                                      onSelect(filteredItems[index]);
                                      Get.back();
                                    },
                                  ),
                                  if (index < filteredItems.length - 1)
                                    Divider(
                                      height: 0,
                                      indent: 12,
                                      endIndent: 12,
                                      color: Colors.grey.shade200,
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
