part of 'create_test.dart';

extension CreateTestPickerPart on _CreateTestState {
  Widget _buildBranchPicker(BuildContext context) {
    return Obx(
      () => controller.showBransh.value
          ? _buildSelectionSheet(
              context: context,
              title: "tests.select_branch".tr,
              itemCount: bransDersleri.length,
              labelForIndex: (index) =>
                  controller.localizedLesson(bransDersleri[index]),
              isSelected: (index) =>
                  controller.selectedDers.contains(bransDersleri[index]),
              onTap: (index) {
                controller.selectedDers.clear();
                controller.selectedDers.add(bransDersleri[index]);
                controller.showBransh.value = false;
              },
              onDismiss: () => controller.showBransh.value = false,
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildLanguagePicker(BuildContext context) {
    return Obx(
      () => controller.showDiller.value
          ? _buildSelectionSheet(
              context: context,
              title: "tests.select_language".tr,
              itemCount: yabanciDiller.length,
              labelForIndex: (index) =>
                  controller.localizedLesson(yabanciDiller[index]),
              isSelected: (index) =>
                  yabanciDiller[index] == controller.selectedDil.value,
              onTap: (index) {
                controller.selectedDil.value = yabanciDiller[index];
                controller.showDiller.value = false;
              },
              onDismiss: () => controller.showDiller.value = false,
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSelectionSheet({
    required BuildContext context,
    required String title,
    required int itemCount,
    required String Function(int index) labelForIndex,
    required bool Function(int index) isSelected,
    required void Function(int index) onTap,
    required VoidCallback onDismiss,
  }) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onDismiss,
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(24),
                  topLeft: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: ListView.builder(
                        itemCount: itemCount,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => onTap(index),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      labelForIndex(index),
                                      style: TextStyle(
                                        color: isSelected(index)
                                            ? Colors.indigo
                                            : Colors.black,
                                        fontSize: 18,
                                        fontFamily: "MontserratMedium",
                                      ),
                                    ),
                                  ),
                                  _buildSelectionIndicator(
                                    selected: isSelected(index),
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
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionIndicator({required bool selected}) {
    return Container(
      width: 25,
      height: 25,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(
          Radius.circular(40),
        ),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? Colors.indigo : Colors.white,
            borderRadius: const BorderRadius.all(
              Radius.circular(40),
            ),
          ),
        ),
      ),
    );
  }
}
