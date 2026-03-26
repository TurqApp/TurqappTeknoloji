// AgendaView.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/Services/global_video_adapter_pool.dart';

import '../../Agenda/AgendaContent/agenda_content.dart';
import 'archives_controller.dart';

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
    final existingController = maybeFindArchiveController();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = ensureArchiveController();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(maybeFindArchiveController(), controller)) {
      Get.delete<ArchiveController>(force: true);
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
            Expanded(
              child: Obx(() {
                final centeredIndex = controller.centeredIndex.value;
                controller.lastCenteredIndex = centeredIndex;
                if (controller.isLoading.value && controller.list.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  );
                }
                if (controller.list.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildArchiveList();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchiveList() {
    return RefreshIndicator(
      backgroundColor: Colors.black,
      color: Colors.white,
      onRefresh: () async {
        await resetPlaybackForSurfaceRefresh();
        await controller.fetchData();
      },
      child: ListView.builder(
        controller: controller.scrollController,
        itemCount: controller.list.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BackButtons(text: "settings.archive".tr),
            );
          }

          final actualIndex = index - 1;
          final model = controller.list[actualIndex];
          final itemKey = controller.getAgendaKey(docId: model.docID);
          final isCentered = controller.centeredIndex.value == actualIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Column(
              children: [
                AgendaContent(
                  key: itemKey,
                  model: model,
                  isPreview: false,
                  shouldPlay: isCentered,
                  instanceTag: controller.agendaInstanceTag(model.docID),
                  showArchivePost: true,
                ),
                const SizedBox(height: 2),
                Divider(color: Colors.grey.withAlpha(50)),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        BackButtons(text: "settings.archive".tr),
        EmptyRow(text: "common.no_results".tr),
      ],
    );
  }
}
