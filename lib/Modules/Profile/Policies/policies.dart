import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Profile/Policies/policy_content.dart';

class Policies extends StatefulWidget {
  const Policies({super.key, this.initialPolicyId});

  final String? initialPolicyId;

  @override
  State<Policies> createState() => _PoliciesState();
}

class _PoliciesState extends State<Policies>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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
    _tabController = TabController(
      length: _policies.length,
      vsync: this,
      initialIndex: _initialIndex,
    );
  }

  @override
  void dispose() {
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

class _PolicyTab extends StatelessWidget {
  const _PolicyTab({required this.policy});

  final PolicyDocument policy;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x12000000)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(policy.icon, color: Colors.black, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      policy.title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 21,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                policy.summary,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  height: 1.55,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'policies.last_updated'
                    .trParams(<String, String>{'date': policy.updatedAt}),
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 12,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(
          policy.sections.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PolicyAccordionTile(
              section: policy.sections[index],
              initiallyExpanded: index == 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _PolicyAccordionTile extends StatelessWidget {
  const _PolicyAccordionTile({
    required this.section,
    this.initiallyExpanded = false,
  });

  final PolicySection section;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: Colors.white,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0x14000000)),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0x14000000)),
            ),
            iconColor: Colors.black,
            collapsedIconColor: Colors.black45,
            title: Text(
              section.title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'MontserratBold',
              ),
            ),
            children: [
              if (section.body.isNotEmpty)
                ...section.body.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        height: 1.6,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                ),
              if (section.bullets.isNotEmpty)
                ...section.bullets.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              height: 1.6,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
