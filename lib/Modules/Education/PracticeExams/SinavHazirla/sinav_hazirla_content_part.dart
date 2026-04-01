part of 'sinav_hazirla.dart';

extension SinavHazirlaContentPart on _SinavHazirlaState {
  Widget _buildSinavHazirlaForm(BuildContext context) {
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: Colors.black,
      onRefresh: controller.resetForm,
      child: ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCoverSection(context),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Colors.grey.shade300),
              ),
              _buildDetailsSection(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Colors.grey.shade300),
              ),
              _buildTypesSection(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Colors.grey.shade300),
              ),
              _buildQuestionCountsSection(context),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Colors.grey.shade300),
              ),
              _buildDateDurationSection(context),
              _buildContinueButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return Obx(
      () => (controller.sinavIsmi.value.text.isNotEmpty &&
              controller.aciklama.value.text.isNotEmpty &&
              (controller.cover.value != null ||
                  (sinavModel != null && sinavModel!.cover.isNotEmpty)))
          ? Padding(
              padding: const EdgeInsets.all(15),
              child: GestureDetector(
                onTap: controller.isSaving.value
                    ? null
                    : () => controller.setData(context),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        controller.isSaving.value ? Colors.grey : Colors.indigo,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'common.continue'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                        Icon(
                          controller.isSaving.value
                              ? Icons.hourglass_empty
                              : Icons.arrow_right_alt,
                          color: Colors.white,
                          size: 30,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
