part of 'list_bottom_sheet.dart';

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
    focusNotifier = ValueNotifier<bool>(searchFocusNode.hasFocus);
    searchFocusNode.addListener(() {
      focusNotifier.value = searchFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
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
                        final isSelected =
                            controller.startSelection.value == item;
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
                                          color: isSelected
                                              ? Colors.pinkAccent
                                              : Colors.black,
                                          fontSize: 16,
                                          fontFamily: isSelected
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
                                            color: isSelected
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
