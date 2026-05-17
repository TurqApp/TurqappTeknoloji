part of 'multiple_choice_bottom_sheet.dart';

extension MultipleChoiceBottomSheetContentPart on MultipleChoiceBottomSheet {
  Widget _buildSheetContent(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          AppSheetHeader(title: title),
          Expanded(child: _buildItemsList()),
          const SizedBox(height: 16),
          _buildFooterActions(context),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (items.isEmpty) {
      return Center(child: Text('admin.tasks.not_found'.tr));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => _toggleItemSelection(item),
          child: Container(
            color: Colors.transparent,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        itemLabelBuilder?.call(item) ?? item,
                        style: TextStyles.textFieldTitle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Obx(
                      () => Icon(
                        controller.selectedItems.contains(item)
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: controller.selectedItems.contains(item)
                            ? Colors.green
                            : Colors.grey,
                        size: 21,
                      ),
                    ),
                  ],
                ),
                if (index < items.length - 1)
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
    );
  }

  Widget _buildFooterActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: SizedBox(
            height: TurqButtonTokens.height,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: TurqButtonTokens.elevatedStyle(
                backgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.black,
              ),
              child: Text(
                'common.cancel'.tr,
                style: TurqButtonTokens.secondaryTextStyle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: TurqButtonTokens.height,
            child: ElevatedButton(
              onPressed: () => _confirmSelection(context),
              style: TurqButtonTokens.elevatedStyle(),
              child: Text(
                'common.select'.tr,
                style: TurqButtonTokens.primaryTextStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
