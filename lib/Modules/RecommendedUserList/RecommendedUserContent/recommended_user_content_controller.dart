import 'dart:async';
import 'package:get/get.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'recommended_user_content_controller_facade_part.dart';
part 'recommended_user_content_controller_fields_part.dart';
part 'recommended_user_content_controller_runtime_part.dart';

class RecommendedUserContentController extends GetxController {
  static RecommendedUserContentController ensure({
    required String userID,
    String? tag,
    bool permanent = false,
  }) =>
      _ensureRecommendedUserContentController(
        userID: userID,
        tag: tag,
        permanent: permanent,
      );

  static RecommendedUserContentController? maybeFind({String? tag}) =>
      _maybeFindRecommendedUserContentController(tag: tag);

  final _state = _RecommendedUserContentControllerState();

  RecommendedUserContentController({required String userID}) {
    this.userID = userID;
  }

  @override
  void onInit() {
    super.onInit();
    getTakipStatus();
  }

  Future<void> getTakipStatus() => _loadRecommendedUserFollowStatus(this);

  Future<void> follow() => _toggleRecommendedUserFollow(this);
}
