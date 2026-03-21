import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGrid/deneme_grid.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeTurleriListesi/deneme_turleri_listesi_controller.dart';

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
    _tag =
        'practice_exam_type_${widget.sinavTuru}_${identityHashCode(this)}';
    if (Get.isRegistered<DenemeTurleriListesiController>(tag: _tag)) {
      controller = Get.find<DenemeTurleriListesiController>(tag: _tag);
      _ownsController = false;
    } else {
      controller = Get.put(
        DenemeTurleriListesiController(sinavTuru: widget.sinavTuru),
        tag: _tag,
      );
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        Get.isRegistered<DenemeTurleriListesiController>(tag: _tag) &&
        identical(
          Get.find<DenemeTurleriListesiController>(tag: _tag),
          controller,
        )) {
      Get.delete<DenemeTurleriListesiController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget buildExamGrid() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 5.0,
            mainAxisSpacing: 5.0,
            childAspectRatio: 2 / 4,
          ),
          itemCount: controller.list.length,
          itemBuilder: (context, index) {
            return DenemeGrid(
              model: controller.list[index],
              getData: controller.getData,
            );
          },
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: widget.sinavTuru),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? const Center(
                        child: CupertinoActivityIndicator(radius: 20),
                      )
                    : controller.isInitialized.value && controller.list.isEmpty
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.black,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'tests.not_found_in_type'
                                        .trParams({'type': widget.sinavTuru}),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            color: Colors.white,
                            backgroundColor: Colors.black,
                            onRefresh: controller.getData,
                            child: ListView(children: [buildExamGrid()]),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
