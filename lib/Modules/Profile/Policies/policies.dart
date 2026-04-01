import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Profile/Policies/policy_content.dart';
import 'package:turqappv2/Modules/Profile/Policies/policies_controller.dart';

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
    _ownsController = maybeFindPoliciesController(tag: _controllerTag) == null;
    _controller = ensurePoliciesController(tag: _controllerTag);
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
            maybeFindPoliciesController(tag: _controllerTag), _controller)) {
      Get.delete<PoliciesController>(tag: _controllerTag);
    }
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: BackButtons(text: 'settings.policies'.tr),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'policies.center_title'.tr,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'policies.center_desc'.tr,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      height: 1.45,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  dividerColor: Colors.transparent,
                  tabAlignment: TabAlignment.start,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x11000000)),
                  ),
                  indicatorPadding: const EdgeInsets.symmetric(vertical: 4),
                  splashBorderRadius: BorderRadius.circular(999),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black45,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'MontserratBold',
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'MontserratMedium',
                  ),
                  tabs: _policies
                      .map(
                        (policy) => Tab(
                          iconMargin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(policy.title),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _policies
                    .map((policy) => _PolicyTab(policy: policy))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
