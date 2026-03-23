part of 'biography_maker.dart';

extension BiographyMakerContentPart on _BiographyMakerState {
  Widget _buildContent() {
    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(
            minHeight: 150,
            maxHeight: 150,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller.bioController,
            maxLength: 100,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'biography.hint'.tr,
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontFamily: "MontserratMedium",
                fontSize: 15,
              ),
              counterText: "",
            ),
            style: const TextStyle(
              fontSize: 15,
              fontFamily: "MontserratMedium",
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Obx(() {
              return Text(
                "${controller.currentLength.value}/100",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontFamily: "MontserratMedium",
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          return AbsorbPointer(
            absorbing: controller.isSaving.value,
            child: TurqAppButton(
              onTap: () {
                controller.setData();
              },
            ),
          );
        }),
        const SizedBox(height: 12),
      ],
    );
  }
}
