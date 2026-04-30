import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/konu_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/soru_model.dart';

part 'soru_content_actions_part.dart';

const _practiceQuestionLgsType = 'LGS';

class SoruContent extends StatefulWidget {
  final SoruModel model;
  final String sinavTuru;
  final String mainID;
  final int index;
  final String ders;
  const SoruContent({
    super.key,
    required this.model,
    required this.sinavTuru,
    required this.mainID,
    required this.index,
    required this.ders,
  });

  @override
  State<SoruContent> createState() => _SoruContentState();
}

class _SoruContentState extends State<SoruContent> {
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();
  final PracticeExamRepository _practiceExamRepository =
      ensurePracticeExamRepository();
  String dogruCevap = "";
  String konu = "";
  List<KonuModel> konuList = [];
  List<KonuModel> filteredKonuList = [];

  @override
  void initState() {
    super.initState();
    dogruCevap = widget.model.dogruCevap;
  }

  void _updateSoruContentState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20, top: widget.index == 0 ? 20 : 0),
      child: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            selectedImage != null || widget.model.soru != ""
                ? GestureDetector(
                    onTap: _pickImageFromGallery,
                    child: Stack(
                      alignment: Alignment.topLeft,
                      children: [
                        Column(
                          children: [
                            SizedBox(height: 7),
                            widget.model.soru != ""
                                ? CachedNetworkImage(
                                    imageUrl: widget.model.soru,
                                  )
                                : Column(
                                    children: [
                                      SizedBox(height: 15),
                                      Image.file(selectedImage!),
                                    ],
                                  ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/education/createsoru.webp",
                          height: (MediaQuery.of(context).size.height * 0.2)
                              .clamp(120.0, 150.0),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: _pickImageFromGallery,
                              child: Container(
                                height: 35,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(50),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Text(
                                    "profile_photo.gallery".tr,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            GestureDetector(
                              onTap: _pickImageFromCamera,
                              child: Container(
                                height: 35,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.indigo,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(50),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Text(
                                    "profile_photo.camera".tr,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            if (selectedImage != null || widget.model.soru != "")
              Container(
                color: Colors.pinkAccent.withValues(alpha: 0.2),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        widget.sinavTuru == _practiceQuestionLgsType
                            ? MainAxisAlignment.spaceAround
                            : MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var item
                          in widget.sinavTuru == _practiceQuestionLgsType
                              ? ['A', 'B', 'C', 'D']
                              : ['A', 'B', 'C', 'D', 'E'])
                        GestureDetector(
                          onTap: () {
                            if (mounted) {
                              setState(() {
                                dogruCevap = item;
                                fastSetData();
                              });
                            }
                          },
                          child: Column(
                            children: [
                              Container(
                                height: 40,
                                width: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: dogruCevap == item
                                      ? Colors.green
                                      : Colors.white,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(50),
                                  ),
                                  border: Border.all(
                                    color: dogruCevap == item
                                        ? Colors.green
                                        : Colors.black,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    color: dogruCevap == item
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
