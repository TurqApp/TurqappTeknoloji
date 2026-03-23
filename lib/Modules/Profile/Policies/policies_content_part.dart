part of 'policies.dart';

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
