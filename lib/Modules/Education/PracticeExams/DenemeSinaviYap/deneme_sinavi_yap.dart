import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeSinaviYap/deneme_sinavi_yap_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/soru_model.dart';

part 'deneme_sinavi_yap_content_part.dart';
part 'deneme_sinavi_yap_questions_part.dart';

const _practiceExamLgsType = 'LGS';

class DenemeSinaviYap extends StatefulWidget {
  final SinavModel model;
  final Function sinaviBitir;
  final Function showGecersizAlert;
  final bool uyariAtla;

  const DenemeSinaviYap({
    super.key,
    required this.model,
    required this.sinaviBitir,
    required this.showGecersizAlert,
    required this.uyariAtla,
  });

  @override
  State<DenemeSinaviYap> createState() => _DenemeSinaviYapState();
}

class _DenemeSinaviYapState extends State<DenemeSinaviYap> {
  late final String _tag;
  late final DenemeSinaviYapController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _tag =
        'practice_exam_solve_${widget.model.docID}_${identityHashCode(this)}';
    final existing = DenemeSinaviYapController.maybeFind(tag: _tag);
    _ownsController = existing == null;
    controller = existing ??
        DenemeSinaviYapController.ensure(
          tag: _tag,
          model: widget.model,
          sinaviBitir: widget.sinaviBitir,
          showGecersizAlert: widget.showGecersizAlert,
          uyariAtla: widget.uyariAtla,
        );
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(DenemeSinaviYapController.maybeFind(tag: _tag), controller)) {
      Get.delete<DenemeSinaviYapController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage(context);
  }

  Widget _buildRulesSection(DenemeSinaviYapController controller) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'practice.exam_started_title'.tr,
              style: const TextStyle(
                color: Colors.purple,
                fontSize: 25,
                fontFamily: "MontserratBold",
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'practice.exam_started_body'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratMedium",
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'practice.rules_title'.tr,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratBold",
              ),
            ),
            const SizedBox(height: 15),
            _buildRuleRow("1-)", 'practice.rule_1'.tr),
            const SizedBox(height: 15),
            _buildRuleRow("2-)", 'practice.rule_2'.tr),
            const SizedBox(height: 15),
            _buildRuleRow("3-)", 'practice.rule_3'.tr),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () => controller.selection.value = 0,
              child: Container(
                height: 45,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Text(
                  'practice.start_exam'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow(String index, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: Text(
            index,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: "MontserratBold",
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: "MontserratMedium",
            ),
          ),
        ),
      ],
    );
  }
}
