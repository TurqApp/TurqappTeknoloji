part of 'sinav_hazirla.dart';

extension SinavHazirlaTypesPart on _SinavHazirlaState {
  Widget _buildTypesSection() {
    final renkler = [
      Colors.black,
      Colors.green[500]!,
      Colors.purple[500]!,
      Colors.red[500]!,
      Colors.orange[500]!,
      Colors.teal[500]!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            'tests.types'.tr,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: "MontserratBold",
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sinavTurleriList.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () =>
                    controller.updateSinavTuru(sinavTurleriList[index]),
                child: Padding(
                  padding: EdgeInsets.only(
                    right: 12,
                    left: index == 0 ? 15 : 0,
                  ),
                  child: Obx(
                    () => Container(
                      height: 60,
                      width: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: controller.sinavTuru.value ==
                                sinavTurleriList[index]
                            ? renkler[index % renkler.length]
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(50),
                        ),
                      ),
                      child: Text(
                        sinavTurleriList[index],
                        style: TextStyle(
                          color: controller.sinavTuru.value ==
                                  sinavTurleriList[index]
                              ? Colors.white
                              : Colors.black,
                          fontSize: 15,
                          fontFamily: controller.sinavTuru.value ==
                                  sinavTurleriList[index]
                              ? "MontserratBold"
                              : "MontserratMedium",
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Obx(
          () => controller.sinavTuru.value == _sinavHazirlaKpssType
              ? Column(
                  children: [
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: kpssOgretimTipleri.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: GestureDetector(
                                onTap: () => controller.updateKpssLisans(
                                  kpssOgretimTipleri[index],
                                ),
                                child: Obx(
                                  () => Container(
                                    height: 45,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: controller
                                                  .kpssSecilenLisans.value ==
                                              kpssOgretimTipleri[index]
                                          ? Colors.indigo
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(50),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: Text(
                                        kpssOgretimTipleri[index],
                                        style: TextStyle(
                                          color: controller.kpssSecilenLisans
                                                      .value ==
                                                  kpssOgretimTipleri[index]
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium",
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
