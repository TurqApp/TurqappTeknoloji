import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/AgendaContent/agenda_content.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';

class SinglePost extends StatelessWidget {
  final PostsModel model;
  final bool showComments;
  final String instanceTag;
  SinglePost({super.key, required this.model, required this.showComments})
      : instanceTag =
            'single_${model.docID}_${DateTime.now().microsecondsSinceEpoch}';
  final put = Get.find<AgendaController>();
  @override
  Widget build(BuildContext context) {
    put.pauseAll.value = false;
    put.isMuted.value = false;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [BackButtons(text: "Gönderiler")],
                ),
              ),
              AgendaContent(
                model: model,
                isPreview: false,
                shouldPlay: true,
                instanceTag: instanceTag,
                hideVideoPoster: true,
                showComments: showComments,
              )
            ],
          ),
        ),
      ),
    );
  }
}
