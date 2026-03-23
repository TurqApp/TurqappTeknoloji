import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGrid/deneme_grid.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeTurleriListesi/deneme_turleri_listesi_controller.dart';

part 'deneme_turleri_listesi_shell_part.dart';
part 'deneme_turleri_listesi_content_part.dart';

class DenemeTurleriListesi extends StatefulWidget {
  final String sinavTuru;

  const DenemeTurleriListesi({super.key, required this.sinavTuru});

  @override
  State<DenemeTurleriListesi> createState() => _DenemeTurleriListesiState();
}

class _DenemeTurleriListesiState extends State<DenemeTurleriListesi> {
  late final String _tag;
  late final DenemeTurleriListesiController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _tag = 'practice_exam_type_${widget.sinavTuru}_${identityHashCode(this)}';
    final existing = DenemeTurleriListesiController.maybeFind(tag: _tag);
    _ownsController = existing == null;
    controller = existing ??
        DenemeTurleriListesiController.ensure(
          tag: _tag,
          sinavTuru: widget.sinavTuru,
        );
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          DenemeTurleriListesiController.maybeFind(tag: _tag),
          controller,
        )) {
      Get.delete<DenemeTurleriListesiController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildDenemeTurleriListesiBody());
  }
}
