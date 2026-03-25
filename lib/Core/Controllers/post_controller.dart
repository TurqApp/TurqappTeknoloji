import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import '../../Services/post_interaction_service.dart';
import '../../Models/posts_model.dart';

part 'post_controller_actions_part.dart';
part 'post_controller_runtime_part.dart';

/// Post etkileşimlerini yönetmek için controller
class PostController extends GetxController {
  static PostController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      PostController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static PostController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<PostController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PostController>(tag: tag);
  }

  late final PostInteractionService _interactionService;

  @override
  void onInit() {
    super.onInit();
    _interactionService = PostInteractionService.ensure();
  }
}
