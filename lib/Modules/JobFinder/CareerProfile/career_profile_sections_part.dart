part of 'career_profile.dart';

extension _CareerProfileSectionsPart on _CareerProfileState {
  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'MontserratBold',
            ),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile({
    required String title,
    required String subtitle,
    required String trailing,
    String detail = '',
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
              if (detail.isNotEmpty || trailing.isNotEmpty)
                Container(
                  width: 1,
                  height: 72,
                  color: const Color(0x22000000),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                fontFamily: 'MontserratMedium',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        trailing,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ],
                  ),
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      detail,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        height: 1.4,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _surface({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: child,
    );
  }
}
