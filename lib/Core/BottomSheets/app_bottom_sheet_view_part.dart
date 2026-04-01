part of 'app_bottom_sheet.dart';

class _AppBottomSheetState extends State<AppBottomSheet> {
  late final String _controllerTag;
  late final AppBottomSheetController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'app_bottom_sheet_${identityHashCode(this)}';
    _ownsController =
        maybeFindAppBottomSheetController(tag: _controllerTag) == null;
    controller = ensureAppBottomSheetController(tag: _controllerTag);
    controller.initSelection(widget.list, widget.startSelection);
  }

  @override
  void didUpdateWidget(covariant AppBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.list != widget.list ||
        oldWidget.startSelection != widget.startSelection) {
      controller.initSelection(widget.list, widget.startSelection);
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindAppBottomSheetController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<AppBottomSheetController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSheetHeader(title: widget.title),
          Wrap(
            children: [
              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.list.length,
                    itemBuilder: (context, index) {
                      final item = controller.list[index];
                      final isLastItem = index == controller.list.length - 1;

                      return GestureDetector(
                        onTap: () {
                          controller.selectItem(item, widget.onBackData);
                          if (widget.onBackUpdatedList != null) {
                            widget.onBackUpdatedList!(controller.list.toList());
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
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    controller.startSelection.value == item
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color:
                                        controller.startSelection.value == item
                                            ? Colors.green
                                            : Colors.grey,
                                    size: 21,
                                  ),
                                ],
                              ),
                              if (!isLastItem)
                                Divider(
                                  color: Colors.grey.withAlpha(50),
                                  thickness: 1,
                                  height: 20,
                                ),
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
        ],
      ),
    );
  }
}
