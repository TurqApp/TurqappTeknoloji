// AgendaView.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/empty_row.dart';

import '../../Agenda/AgendaContent/agenda_content.dart';
import 'archives_controller.dart';

part 'archives_shell_part.dart';
part 'archives_content_part.dart';

class Archives extends StatefulWidget {
  const Archives({super.key});

  @override
  State<Archives> createState() => _ArchivesState();
}

class _ArchivesState extends State<Archives> {
  late final ArchiveController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    final existingController = ArchiveController.maybeFind();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = ArchiveController.ensure();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(ArchiveController.maybeFind(), controller)) {
      Get.delete<ArchiveController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
