part of 'view_changer.dart';

extension ViewChangerSelectionPart on _ViewChangerState {
  Widget _buildClassicSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectionHeader(
          label: 'view_changer.classic'.tr,
          isSelected: controller.selection.value == 0,
        ),
        7.ph,
        Padding(
          padding: const EdgeInsets.only(left: 33),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: controller.selection.value == 0
                    ? Colors.blueAccent
                    : Colors.grey.withAlpha(50),
              ),
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              child: Image.asset("assets/images/klasikview.webp"),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectionHeader(
          label: 'view_changer.modern'.tr,
          isSelected: controller.selection.value == 1,
        ),
        7.ph,
        Padding(
          padding: const EdgeInsets.only(left: 33),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: controller.selection.value == 1
                    ? Colors.blueAccent
                    : Colors.grey.withAlpha(50),
              ),
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              child: Image.asset("assets/images/modernview.webp"),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionHeader({
    required String label,
    required bool isSelected,
  }) {
    return Row(
      children: [
        Container(
          width: 25,
          height: 25,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
        7.pw,
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: "MontserratBold",
          ),
        ),
      ],
    );
  }
}
