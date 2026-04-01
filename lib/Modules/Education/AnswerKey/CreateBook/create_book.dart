import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/CreateBook/create_book_controller.dart';

part 'create_book_answer_key_part.dart';
part 'create_book_editor_part.dart';

String _answerKeyExamLabel(String raw) {
  switch (raw) {
    case 'Dil':
      return 'common.language'.tr;
    case 'Yazılım':
      return 'tutoring.branch.software'.tr;
    case 'Spor':
      return 'tutoring.branch.sports'.tr;
    case 'Tasarım':
      return 'common.design'.tr;
    default:
      return raw;
  }
}

class CevapAnahtariHazirlikModel {
  String baslik;
  List<String> dogruCevaplar;
  int sira;

  CevapAnahtariHazirlikModel({
    required this.baslik,
    required this.dogruCevaplar,
    required this.sira,
  });
}

class CreateBook extends StatefulWidget {
  final Function? onBack;
  final BookletModel? existingBook;

  const CreateBook({required this.onBack, this.existingBook, super.key});

  @override
  State<CreateBook> createState() => _CreateBookState();
}

class _CreateBookState extends State<CreateBook> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final CreateBookController controller;

  Function? get onBack => widget.onBack;
  BookletModel? get existingBook => widget.existingBook;

  double _coverWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth * 0.44).clamp(150.0, 170.0);
  }

  double _coverHeight(BuildContext context) {
    final width = _coverWidth(context);
    return (width * 1.29).clamp(194.0, 220.0);
  }

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'create_book_${existingBook?.docID ?? 'new'}_${identityHashCode(this)}';
    _ownsController =
        maybeFindCreateBookController(tag: _controllerTag) == null;
    controller = ensureCreateBookController(
      onBack,
      existingBook: existingBook,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = maybeFindCreateBookController(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<CreateBookController>(tag: _controllerTag, force: true);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                BackButtons(text: 'answer_key.create_book'.tr),
                Obx(
                  () => controller.selection.value == 0
                      ? _build1(context, controller)
                      : _build2(context, controller),
                ),
                Obx(
                  () => controller.isFormValid()
                      ? GestureDetector(
                          onTap: () => controller.selection.value == 0
                              ? controller.nextStep()
                              : controller.setData(context),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 15,
                              right: 15,
                              bottom: 20,
                            ),
                            child: Container(
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                controller.selection.value == 0
                                    ? 'common.continue'.tr
                                    : controller.isEditMode
                                        ? 'common.update'.tr
                                        : 'common.publish'.tr,
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
              ],
            ),
            Obx(
              () => controller.showIndicator.value
                  ? Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 20),
                          Text(
                            'common.loading'.tr,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
