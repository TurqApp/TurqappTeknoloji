part of 'cv.dart';

extension _CvOtherPart on _CvState {
  Widget step3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12),
        Row(
          children: [
            Text(
              'cv.skills'.tr,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratBold",
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
          ],
        ),
        SizedBox(height: 12),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...controller.skills.asMap().entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: "MontserratMedium",
                          color: Colors.blueAccent,
                        ),
                      ),
                      SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => controller.skills.removeAt(entry.key),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (controller.skills.length < 10)
                GestureDetector(
                  onTap: () => controller.beceriEkle(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.add,
                          size: 15,
                          color: Colors.black,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'social_links.add'.tr,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontFamily: "MontserratMedium",
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Row(
          children: [
            Text(
              'cv.add_language'.tr,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratBold",
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
          ],
        ),
        SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount:
              controller.diler.length >= 5 ? 5 : controller.diler.length + 1,
          itemBuilder: (context, index) {
            if (index == controller.diler.length &&
                controller.diler.length < 5) {
              return _buildAddRow(
                text: 'cv.add_new_language'.tr,
                onTap: () => controller.dilEkle(),
                margin: EdgeInsets.only(top: index == 0 ? 0 : 12),
              );
            }

            final model = controller.diler[index];
            return GestureDetector(
              onTap: () => controller.dilDuzenle(index),
              child: Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.localizedLanguage(model.languege),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < model.level
                                    ? Icons.star
                                    : Icons.star_border,
                                color: i < model.level
                                    ? Colors.amber
                                    : Colors.grey,
                                size: 20,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(CupertinoIcons.pencil, color: Colors.grey, size: 18),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => controller.diler.removeAt(index),
                      child: Icon(
                        CupertinoIcons.trash,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Row(
          children: [
            Text(
              'cv.add_experience'.tr,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratBold",
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
          ],
        ),
        SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: controller.isDeneyimleri.length >= 5
              ? 5
              : controller.isDeneyimleri.length + 1,
          itemBuilder: (context, index) {
            if (index == controller.isDeneyimleri.length &&
                controller.isDeneyimleri.length < 5) {
              return _buildAddRow(
                text: 'cv.add_new_experience'.tr,
                onTap: () => controller.isDeneyimiEkle(),
                margin: EdgeInsets.only(top: index == 0 ? 0 : 12),
              );
            }

            final model = controller.isDeneyimleri[index];
            return GestureDetector(
              onTap: () => controller.isDeneyimiDuzenle(index),
              child: Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model.position,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            model.company,
                            style: TextStyle(
                              color: Colors.pinkAccent,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                          if (model.description.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Text(
                              model.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                                fontFamily: "Montserrat",
                              ),
                            ),
                          ],
                          SizedBox(height: 4),
                          Text(
                            "${controller.localizedYearLabel(model.year1)} - ${controller.localizedYearLabel(model.year2)}",
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(CupertinoIcons.pencil, color: Colors.grey, size: 18),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => controller.isDeneyimleri.removeAt(index),
                      child: Icon(
                        CupertinoIcons.trash,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Row(
          children: [
            Text(
              'cv.add_reference'.tr,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratBold",
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
          ],
        ),
        SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: controller.referanslar.length >= 5
              ? 5
              : controller.referanslar.length + 1,
          itemBuilder: (context, index) {
            if (index == controller.referanslar.length &&
                controller.referanslar.length < 5) {
              return _buildAddRow(
                text: 'cv.add_new_reference'.tr,
                onTap: () => controller.referansEkle(),
                margin: EdgeInsets.only(top: index == 0 ? 0 : 12),
              );
            }

            final model = controller.referanslar[index];
            return GestureDetector(
              onTap: () => controller.referansDuzenle(index),
              child: Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model.nameSurname,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            model.phone,
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(CupertinoIcons.pencil, color: Colors.grey, size: 18),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => controller.referanslar.removeAt(index),
                      child: Icon(
                        CupertinoIcons.trash,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
