part of 'social_media_links_controller.dart';

class _SocialMediaControllerState {
  final SocialMediaLinksRepository linksRepository =
      SocialMediaLinksRepository.ensure();
  final RxList<SocialMediaModel> list = <SocialMediaModel>[].obs;
  final RxString selected = ''.obs;
  final TextEditingController textController = TextEditingController();
  final TextEditingController urlController = TextEditingController();
  final Rxn<File> imageFile = Rxn<File>();
  final RxBool enableSave = false.obs;
  final RxBool isUploading = false.obs;
  final RxBool isLoading = false.obs;
  final List<String> sosyal = List<String>.from(kSocialMediaEmbeddedKeys);
}

extension SocialMediaControllerFieldsPart on SocialMediaController {
  SocialMediaLinksRepository get _linksRepository => _state.linksRepository;
  RxList<SocialMediaModel> get list => _state.list;
  RxString get selected => _state.selected;
  TextEditingController get textController => _state.textController;
  TextEditingController get urlController => _state.urlController;
  Rxn<File> get imageFile => _state.imageFile;
  RxBool get enableSave => _state.enableSave;
  RxBool get isUploading => _state.isUploading;
  RxBool get isLoading => _state.isLoading;
  List<String> get sosyal => _state.sosyal;
}
