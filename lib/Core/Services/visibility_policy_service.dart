import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'visibility_policy_service_facade_part.dart';
part 'visibility_policy_service_fields_part.dart';
part 'visibility_policy_service_support_part.dart';

class VisibilityPolicyService extends GetxService {
  static VisibilityPolicyService? maybeFind() {
    final isRegistered = Get.isRegistered<VisibilityPolicyService>();
    if (!isRegistered) return null;
    return Get.find<VisibilityPolicyService>();
  }

  static VisibilityPolicyService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(VisibilityPolicyService(), permanent: true);
  }

  final _state = _VisibilityPolicyServiceState();
}
