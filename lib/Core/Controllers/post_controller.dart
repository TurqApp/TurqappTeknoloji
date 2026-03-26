import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import '../../Services/post_interaction_service.dart';
import '../../Models/posts_model.dart';

part 'post_controller_actions_part.dart';
part 'post_controller_facade_part.dart';
part 'post_controller_runtime_part.dart';

/// Post etkileşimlerini yönetmek için controller
class PostController extends GetxController {
  late final PostInteractionService _interactionService;

  @override
  void onInit() {
    super.onInit();
    _interactionService = PostInteractionService.ensure();
  }
}
