part of 'create_book.dart';

class CreateBookAnswerKey extends StatefulWidget {
  final CevapAnahtariHazirlikModel model;
  final Function onBack;

  const CreateBookAnswerKey({
    required this.model,
    required this.onBack,
    super.key,
  });

  @override
  State<CreateBookAnswerKey> createState() => _CreateBookAnswerKeyState();
}

class _CreateBookAnswerKeyState extends State<CreateBookAnswerKey> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final CreateBookAnswerKeyController controller;

  CevapAnahtariHazirlikModel get model => widget.model;
  Function get onBack => widget.onBack;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'create_book_answer_key_${model.sira}_${identityHashCode(this)}';
    _ownsController =
        CreateBookAnswerKeyController.maybeFind(tag: _controllerTag) == null;
    controller = CreateBookAnswerKeyController.ensure(
      model,
      onBack,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = CreateBookAnswerKeyController.maybeFind(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<CreateBookAnswerKeyController>(
          tag: _controllerTag,
          force: true,
        );
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              height: 70,
              decoration: const BoxDecoration(color: Colors.white),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: const Row(
                children: [
                  AppBackButton(icon: Icons.arrow_back),
                  SizedBox(width: 8),
                  Expanded(
                    child: AppPageTitle(
                      "answer_key.add_answer_key",
                      translate: true,
                      fontSize: 25,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  children: [
                    Column(
                      children: [
                        Container(
                          height: 50,
                          color: Colors.grey.withValues(alpha: 0.1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                              controller: controller.baslikController,
                              decoration: InputDecoration(
                                hintText: "answer_key.book_title_hint".tr,
                                hintStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontFamily: "MontserratMedium",
                                ),
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 50,
                      color: Colors.grey.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextField(
                          controller: controller.inputController,
                          decoration: InputDecoration(
                            hintText: "answer_key.answer_list_hint".tr,
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                              fontFamily: "MontserratMedium",
                            ),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: controller.kaydetCevaplar,
                      child: Obx(
                        () => controller.inputController.text.isNotEmpty
                            ? Container(
                                height: 50,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.indigo,
                                ),
                                child: Text(
                                  "common.preview".tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    Obx(
                      () => ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.cevaplar.length,
                        itemBuilder: (context, index) {
                          return Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: index.isEven
                                  ? Colors.pink.withValues(alpha: 0.1)
                                  : Colors.pink.withValues(alpha: 0.2),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${index + 1}.",
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontFamily: "MontserratBold",
                                    ),
                                  ),
                                  for (final item in ["A", "B", "C", "D", "E"])
                                    Container(
                                      width: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color:
                                            item == controller.cevaplar[index]
                                                ? Colors.green
                                                : Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          color:
                                              item == controller.cevaplar[index]
                                                  ? Colors.white
                                                  : Colors.black,
                                          fontSize: 20,
                                          fontFamily: "MontserratBold",
                                        ),
                                      ),
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
            Obx(
              () => controller.baslikController.text.isNotEmpty &&
                      controller.onIzlendi.value
                  ? GestureDetector(
                      onTap: controller.saveAndBack,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.all(
                              Radius.circular(50),
                            ),
                          ),
                          child: Text(
                            "common.ok".tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
