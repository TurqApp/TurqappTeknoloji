part of 'multiple_choice_bottom_sheet2.dart';

class _MultiSelectBottomSheet2Content extends StatefulWidget {
  final MultiSelectBottomSheet2 sheet;

  const _MultiSelectBottomSheet2Content({required this.sheet});

  @override
  State<_MultiSelectBottomSheet2Content> createState() =>
      _MultiSelectBottomSheet2ContentState();
}

class _MultiSelectBottomSheet2ContentState
    extends State<_MultiSelectBottomSheet2Content> {
  final RxList<String> _tempSelectedItems = <String>[].obs;
  final RxString _searchQuery = ''.obs;
  final RxList<String> _filteredItems = <String>[].obs;
  late final TextEditingController _searchController;
  late final Worker _searchWorker;

  MultiSelectBottomSheet2 get sheet => widget.sheet;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tempSelectedItems.assignAll(sheet.selectedItems);
    _searchWorker = ever(_searchQuery, (_) => _updateFilteredItems());
    _updateFilteredItems();
  }

  @override
  void didUpdateWidget(covariant _MultiSelectBottomSheet2Content oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sheet.items != sheet.items ||
        oldWidget.sheet.selectedItems != sheet.selectedItems ||
        oldWidget.sheet.relatedItems != sheet.relatedItems ||
        oldWidget.sheet.parentSelection != sheet.parentSelection) {
      _tempSelectedItems.assignAll(sheet.selectedItems);
      _updateFilteredItems();
    }
  }

  @override
  void dispose() {
    _searchWorker.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilteredItems() {
    _filteredItems.assignAll(sheet.filterItems(_searchQuery.value));
  }

  void _clearSearch() {
    _searchController.clear();
    _searchQuery.value = '';
  }

  void _confirmSelection(BuildContext context) {
    sheet.onConfirm(sheet.confirmedSelection(_tempSelectedItems));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          AppSheetHeader(
            title: sheet.title,
            padding: const EdgeInsets.only(bottom: 12),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'common.search'.tr,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: Obx(
                  () => _searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: _clearSearch,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              onChanged: (value) => _searchQuery.value = value,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(
              () => _filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        'explore.no_results'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return GestureDetector(
                          onTap: () => sheet.toggleSelection(
                            _tempSelectedItems,
                            item,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            color: Colors.transparent,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        sheet.itemLabelBuilder?.call(item) ??
                                            item,
                                        style:
                                            TextStyles.textFieldTitle.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Obx(
                                      () => Icon(
                                        sheet.containsSelectedValue(
                                          _tempSelectedItems,
                                          item,
                                        )
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: sheet.containsSelectedValue(
                                          _tempSelectedItems,
                                          item,
                                        )
                                            ? Colors.green
                                            : Colors.grey,
                                        size: 21,
                                      ),
                                    ),
                                  ],
                                ),
                                if (index < _filteredItems.length - 1)
                                  Divider(
                                    color: Colors.grey.withAlpha(50),
                                    thickness: 1,
                                    height: 6,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'common.cancel'.tr,
                    style: TextStyles.textFieldTitle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _confirmSelection(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'common.select'.tr,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
