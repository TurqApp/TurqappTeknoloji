part of 'sinav_hazirla.dart';

extension SinavHazirlaSectionsPart on _SinavHazirlaState {
  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            'tests.details'.tr,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: "MontserratBold",
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Obx(
                () => TextField(
                  controller: controller.sinavIsmi.value,
                  maxLines: 1,
                  keyboardType: TextInputType.text,
                  inputFormatters: [LengthLimitingTextInputFormatter(17)],
                  decoration: InputDecoration(
                    hintText: 'tests.name_hint'.tr,
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontFamily: "MontserratMedium",
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                    height: 1.8,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Obx(
                () => TextField(
                  controller: controller.aciklama.value,
                  maxLines: null,
                  keyboardType: TextInputType.text,
                  inputFormatters: [LengthLimitingTextInputFormatter(300)],
                  decoration: InputDecoration(
                    hintText: 'common.description'.tr,
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontFamily: "MontserratMedium",
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                    height: 1.8,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => controller.public.value = !controller.public.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              height: 45,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'tests.post_exam_status'.trParams({
                          'status': controller.public.value
                              ? 'tests.status.open'.tr
                              : 'tests.status.closed'.tr,
                        }),
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: "MontserratBold",
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 25,
                        alignment: controller.public.value
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(50),
                          ),
                        ),
                        child: Container(
                          width: 25,
                          decoration: BoxDecoration(
                            color: controller.public.value
                                ? Colors.indigo
                                : Colors.grey,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(50),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
