import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Models/PostsModel.dart';
import 'package:turqappv2/Modules/Agenda/AgendaContent/AgendaContent.dart';
import 'package:turqappv2/Modules/Agenda/AgendaController.dart';

class SinglePost extends StatelessWidget {
  final PostsModel model;
  final bool showComments;
  SinglePost({super.key, required this.model, required this.showComments});
  final put = Get.find<AgendaController>();
  @override
  Widget build(BuildContext context) {
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
                showComments: showComments,
              )
            ],
          ),
        ),
      ),
    );
  }
}
