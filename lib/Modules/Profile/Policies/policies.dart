import 'package:flutter/material.dart';
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

  int get _initialIndex {
    final targetId = widget.initialPolicyId?.trim() ?? '';
    if (targetId.isEmpty) return 0;
    final index = turqAppPolicies.indexWhere((item) => item.id == targetId);
    return index < 0 ? 0 : index;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: turqAppPolicies.length,
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
      backgroundColor: const Color(0xFFF4F1EA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: BackButtons(text: 'Politikalar'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 8, 15, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Politika Merkezi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Uyelik, gizlilik, topluluk, telif ve guvenlik metinleri tek yerde ve uygulama ici okumaya uygun sekilde sunulur.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black54,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'MontserratBold',
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'MontserratMedium',
                  ),
                  tabs: turqAppPolicies
                      .map((policy) => Tab(text: policy.title))
                      .toList(),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: turqAppPolicies
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
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                policy.title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 21,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 9),
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
                'Son guncelleme: ${policy.updatedAt}',
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
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: Colors.white,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Color(0x14000000)),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
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
