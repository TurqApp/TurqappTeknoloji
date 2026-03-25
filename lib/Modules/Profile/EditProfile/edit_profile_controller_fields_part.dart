part of 'edit_profile_controller.dart';

class _EditProfileControllerState {
  final cropController = CropController();
  final picker = ImagePicker();
  final selectedImage = Rx<File?>(null);
  final croppedImage = Rx<Uint8List?>(null);
  final isCropping = false.obs;
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final email = ''.obs;
  final phoneNumber = ''.obs;
  StreamSubscription<Map<String, dynamic>?>? userSub;
}

extension EditProfileControllerFieldsPart on EditProfileController {
  CropController get cropController => _state.cropController;
  ImagePicker get picker => _state.picker;
  Rx<File?> get selectedImage => _state.selectedImage;
  Rx<Uint8List?> get croppedImage => _state.croppedImage;
  RxBool get isCropping => _state.isCropping;
  TextEditingController get firstNameController => _state.firstNameController;
  TextEditingController get lastNameController => _state.lastNameController;
  RxString get email => _state.email;
  RxString get phoneNumber => _state.phoneNumber;
  StreamSubscription<Map<String, dynamic>?>? get _userSub => _state.userSub;
  set _userSub(StreamSubscription<Map<String, dynamic>?>? value) =>
      _state.userSub = value;
}
