import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/AgendaContent/agenda_content.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';

class SinglePost extends StatefulWidget {
  final PostsModel model;
  final bool showComments;
  final String instanceTag;
  SinglePost({super.key, required this.model, required this.showComments})
      : instanceTag =
            'single_${model.docID}_${DateTime.now().microsecondsSinceEpoch}';

  @override
  State<SinglePost> createState() => _SinglePostState();
}

class _SinglePostState extends State<SinglePost> {
  late final AgendaController put = AgendaController.ensure();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      put.pauseAll.value = false;
      put.isMuted.value = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenSinglePost),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [BackButtons(text: 'single_post.title'.tr)],
                ),
              ),
              AgendaContent(
                model: widget.model,
                isPreview: false,
                shouldPlay: true,
                instanceTag: widget.instanceTag,
                hideVideoPoster: true,
                showComments: widget.showComments,
              )
            ],
          ),
        ),
      ),
    );
  }
}
