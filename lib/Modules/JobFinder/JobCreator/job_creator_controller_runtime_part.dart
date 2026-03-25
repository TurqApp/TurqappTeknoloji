part of 'job_creator_controller.dart';

extension JobCreatorControllerRuntimePart on JobCreatorController {
  Future<void> pickImage({required ImageSource source}) async {
    _pickImageInternal(source: source);
  }

  Future<void> showCropDialog() async {
    _showCropDialogInternal();
  }

  Future<void> selectCalismaTuru() async {
    _selectCalismaTuruInternal();
  }

  Future<void> selectYanHaklar(BuildContext context) async {
    _selectYanHaklarInternal(context);
  }

  Future<void> selectCalismaGunleri() async {
    _selectCalismaGunleriInternal();
  }

  Future<void> showMeslekSelector() async {
    _showMeslekSelectorInternal();
  }

  Future<void> showSehirSelect() async {
    _showSehirSelectInternal();
  }

  Future<void> showIlceSelect() async {
    _showIlceSelectInternal();
  }

  Future<void> uploadCroppedImageToFirebase(String docID) async {
    _uploadCroppedImageToFirebaseInternal(docID);
  }

  Future<void> setData() async {
    _setDataInternal();
  }
}
