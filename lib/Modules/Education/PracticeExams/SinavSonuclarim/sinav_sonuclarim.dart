import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGecmisSonucContent/deneme_gecmis_sonuc_content.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavSonuclarim/sinav_sonuclarim_controller.dart';

part 'sinav_sonuclarim_content_part.dart';

class SinavSonuclarim extends StatefulWidget {
  const SinavSonuclarim({super.key});

  @override
  State<SinavSonuclarim> createState() => _SinavSonuclarimState();
}

class _SinavSonuclarimState extends State<SinavSonuclarim> {
  late final SinavSonuclarimController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    final existing = SinavSonuclarimController.maybeFind();
    _ownsController = existing == null;
    controller = existing ?? SinavSonuclarimController.ensure();
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(SinavSonuclarimController.maybeFind(), controller)) {
      Get.delete<SinavSonuclarimController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildSinavSonuclarimBody());
  }

  Widget _buildSinavSonuclarimBody() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          BackButtons(text: 'practice.results_title'.tr),
          Expanded(child: _buildSinavSonuclarimContent()),
        ],
      ),
    );
  }
}
