part of 'cv.dart';

extension _CvEducationPart on _CvState {
  Widget step2() {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: controller.okullar.length + 1,
          itemBuilder: (context, index) {
            if (index == controller.okullar.length) {
              return _buildAddRow(
                text: 'cv.add_school'.tr,
                onTap: () => controller.okulEkle(),
                margin: const EdgeInsets.only(top: 12),
              );
            }

            final model = controller.okullar[index];
            return Stack(
              children: [
                GestureDetector(
                  onTap: () => controller.okulDuzenle(index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(20),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                model.school,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    model.branch,
                                    style: TextStyle(
                                      color: Colors.pinkAccent,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
                                    ),
                                  ),
                                  if (model.branch.isNotEmpty &&
                                      model.lastYear.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      child: Text("-"),
                                    ),
                                  Text(
                                    controller.localizedYearLabel(
                                      model.lastYear,
                                    ),
                                    style: TextStyle(
                                      color: Colors.pinkAccent,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          CupertinoIcons.pencil,
                          color: Colors.grey,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: GestureDetector(
                    onTap: () => controller.okulSil(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 3,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
