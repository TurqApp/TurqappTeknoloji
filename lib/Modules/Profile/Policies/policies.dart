import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Profile/Policies/policy_content.dart';
import 'package:turqappv2/Modules/Profile/Policies/policies_controller.dart';

part 'policies_shell_part.dart';
part 'policies_content_part.dart';

class Policies extends StatefulWidget {
  const Policies({super.key, this.initialPolicyId});

  final String? initialPolicyId;

  @override
  State<Policies> createState() => _PoliciesState();
}

class _PoliciesState extends State<Policies>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final String _controllerTag = 'policies_${identityHashCode(this)}';
  late final PoliciesController _controller;
  late final bool _ownsController;

  List<PolicyDocument> get _policies =>
      localizedTurqAppPolicies(Get.locale?.languageCode);

  int get _initialIndex {
    final targetId = widget.initialPolicyId?.trim() ?? '';
    if (targetId.isEmpty) return 0;
    final index = _policies.indexWhere((item) => item.id == targetId);
    return index < 0 ? 0 : index;
  }

  @override
  void initState() {
    super.initState();
    _ownsController = PoliciesController.maybeFind(tag: _controllerTag) == null;
    _controller = PoliciesController.ensure(tag: _controllerTag);
    _tabController = TabController(
      length: _policies.length,
      vsync: this,
      initialIndex: _initialIndex,
    );
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
            PoliciesController.maybeFind(tag: _controllerTag), _controller)) {
      Get.delete<PoliciesController>(tag: _controllerTag);
    }
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildPoliciesShell(context);
  }
}
