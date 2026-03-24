import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Profile/Policies/policy_content.dart';

part 'policy_detail_view_content_part.dart';

class PolicyDetailView extends StatelessWidget {
  const PolicyDetailView({super.key, required this.policy});

  final PolicyDocument policy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: BackButtons(text: policy.title),
            ),
            Expanded(child: _buildPolicyDetailContent()),
          ],
        ),
      ),
    );
  }
}
