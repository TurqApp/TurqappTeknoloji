part of 'policy_detail_view.dart';

extension _PolicyDetailViewContentPart on PolicyDetailView {
  Widget _buildPolicyDetailContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(15, 8, 15, 28),
      children: [
        _buildPolicyHeaderCard(),
        const SizedBox(height: 14),
        ...policy.sections.map(
          (section) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SectionCard(section: section),
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            policy.title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontFamily: 'MontserratBold',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            policy.summary,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              height: 1.5,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'policy_detail.last_updated'.trParams({'date': policy.updatedAt}),
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
              fontFamily: 'MontserratMedium',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final PolicySection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'MontserratBold',
            ),
          ),
          if (section.body.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...section.body.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  item,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.55,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ),
          ],
          if (section.bullets.isNotEmpty) ...[
            if (section.body.isEmpty) const SizedBox(height: 10),
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
                          height: 1.55,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
