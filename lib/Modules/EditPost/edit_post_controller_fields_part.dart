part of 'edit_post_controller.dart';

class _EditPostControllerState {
  final TextEditingController text = TextEditingController();
  final Rxn<dynamic> rxVideoController = Rxn<dynamic>();
  final RxBool isPlaying = false.obs;
  final RxList<String> imageUrls = <String>[].obs;
  final RxString videoUrl = ''.obs;
  final RxString adres = ''.obs;
  final RxBool yorum = false.obs;
  final RxString thumbnail = ''.obs;
  final RxBool waitingVideo = false.obs;
  final RxBool bekle = false.obs;
  final ImagePicker picker = ImagePicker();
  final RxList<File> selectedImages = <File>[].obs;
  bool newVideoSelected = false;
  bool videoRemoved = false;
}

extension EditPostControllerFieldsPart on EditPostController {
  TextEditingController get text => _state.text;
  Rxn<dynamic> get rxVideoController => _state.rxVideoController;
  RxBool get isPlaying => _state.isPlaying;
  RxList<String> get imageUrls => _state.imageUrls;
  RxString get videoUrl => _state.videoUrl;
  RxString get adres => _state.adres;
  RxBool get yorum => _state.yorum;
  RxString get thumbnail => _state.thumbnail;
  RxBool get waitingVideo => _state.waitingVideo;
  RxBool get bekle => _state.bekle;
  ImagePicker get picker => _state.picker;
  RxList<File> get selectedImages => _state.selectedImages;

  bool get _newVideoSelected => _state.newVideoSelected;
  set _newVideoSelected(bool value) => _state.newVideoSelected = value;

  bool get _videoRemoved => _state.videoRemoved;
  set _videoRemoved(bool value) => _state.videoRemoved = value;
}
