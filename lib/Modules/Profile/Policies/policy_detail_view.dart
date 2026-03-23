import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Profile/Policies/policy_content.dart';

part 'policy_detail_view_shell_part.dart';
part 'policy_detail_view_content_part.dart';

class PolicyDetailView extends StatelessWidget {
  const PolicyDetailView({super.key, required this.policy});

  final PolicyDocument policy;

  @override
  Widget build(BuildContext context) {
    return _buildPolicyDetailShell(context);
  }
}
