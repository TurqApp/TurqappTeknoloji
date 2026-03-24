import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavSorusuHazirla/sinav_sorusu_hazirla_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SoruContent/soru_content.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/soru_model.dart';

part 'sinav_sorusu_hazirla_question_part.dart';

class SinavSorusuHazirla extends StatefulWidget {
  final String docID;
  final String sinavTuru;
  final List<String> tumDersler;
  final List<String> derslerinSoruSayilari;
  final Function() complated;

  const SinavSorusuHazirla({
    super.key,
    required this.docID,
    required this.sinavTuru,
    required this.tumDersler,
    required this.derslerinSoruSayilari,
    required this.complated,
  });

  @override
  State<SinavSorusuHazirla> createState() => _SinavSorusuHazirlaState();
}

class _SinavSorusuHazirlaState extends State<SinavSorusuHazirla> {
  late final String _tag;
  late final SinavSorusuHazirlaController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _tag =
        'practice_question_prepare_${widget.docID}_${identityHashCode(this)}';
    final existing = SinavSorusuHazirlaController.maybeFind(tag: _tag);
    _ownsController = existing == null;
    controller = existing ??
        SinavSorusuHazirlaController.ensure(
          tag: _tag,
          docID: widget.docID,
          sinavTuru: widget.sinavTuru,
          tumDersler: widget.tumDersler,
          derslerinSoruSayilari: widget.derslerinSoruSayilari,
          complated: widget.complated,
        );
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          SinavSorusuHazirlaController.maybeFind(tag: _tag),
          controller,
        )) {
      Get.delete<SinavSorusuHazirlaController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildSinavSorusuHazirlaBody());
  }

  Widget _buildSinavSorusuHazirlaBody() {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            children: [
              BackButtons(text: 'tests.prepare_questions'.tr),
              Expanded(child: _buildSinavSorusuHazirlaContent()),
            ],
          ),
        ],
      ),
    );
  }
}
