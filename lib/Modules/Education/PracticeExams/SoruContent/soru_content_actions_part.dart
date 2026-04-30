part of 'soru_content.dart';

extension SoruContentActionsPart on _SoruContentState {
  Future<void> _pickImageFromGallery() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final pickedFile = await AppImagePickerService.pickSingleImage(ctx);
    if (pickedFile != null) {
      _updateSoruContentState(() {
        selectedImage = pickedFile;
        yukle(selectedImage!, widget.mainID);
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _updateSoruContentState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> yukle(File imageFile, String mainID) async {
    try {
      final nsfw = await OptimizedNSFWService.checkImage(imageFile);
      if (nsfw.errorMessage != null) {
        AppSnackbar('common.error'.tr, 'tests.image_analyze_failed'.tr);
        return;
      }
      if (nsfw.isNSFW) {
        AppSnackbar('common.error'.tr, 'tests.image_invalid'.tr);
        return;
      }
      final downloadUrl = await WebpUploadService.uploadFileAsWebp(
        file: imageFile,
        storagePathWithoutExt:
            'practiceExams/$mainID/questions/${widget.model.docID}',
      );

      await _practiceExamRepository.saveQuestion(
        examId: widget.mainID,
        questionId: widget.model.docID,
        data: {
          "id": widget.model.id,
          "soru": downloadUrl,
          "ders": widget.ders,
          "konu": konu,
          "dogruCevap": dogruCevap,
          "yanitlayanlar": [],
        },
      );
    } catch (e) {
      print("Hata oluştu: $e");
    }
  }

  void fastSetData() {
    _practiceExamRepository.saveQuestion(
      examId: widget.mainID,
      questionId: widget.model.docID,
      data: {
        "id": widget.model.id,
        "ders": widget.ders,
        "konu": konu,
        "dogruCevap": dogruCevap,
        "yanitlayanlar": [],
      },
    );
  }
}
