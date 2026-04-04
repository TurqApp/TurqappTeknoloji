part of 'become_verified_account.dart';

extension _BecomeVerifiedAccountFieldsPart on _BecomeVerifiedAccountState {
  Widget _buildSizedAssetIcon(
    String assetPath, {
    double boxSize = 45,
    double iconSize = 30,
    double radius = 8,
  }) {
    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            width: iconSize,
            height: iconSize,
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSocialField(
    TextEditingController ctrl,
    String hint,
    String? iconPath,
    VoidCallback onTap, {
    IconData? icon,
  }) {
    return [
      Row(
        children: [
          iconPath != null
              ? _buildSizedAssetIcon(iconPath)
              : Container(
                  width: 45,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon ?? Icons.link, color: Colors.white),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: ctrl,
                  onTap: onTap,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 15),
    ];
  }

  Widget _buildCustomInput(
    TextEditingController ctrl,
    String hint, [
    VoidCallback? onTap,
    String? iconAsset,
  ]) {
    return Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: iconAsset != null
              ? Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Image.asset(iconAsset),
                )
              : const Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: ctrl,
                onTap: onTap,
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Montserrat',
                  ),
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _badgeTitleKey(String title) => _resolveBadgeKey(
        title: title,
        titleSuffix: '',
      );

  String _badgeDescKey(String title) => _resolveBadgeKey(
        title: title,
        titleSuffix: '_desc',
      );

  String _resolveBadgeKey({
    required String title,
    required String titleSuffix,
  }) {
    final normalized = title.trim();
    final normalizedRozet = normalizeRozetValue(normalized);
    final baseKey = switch (normalizedRozet) {
      'mavi' => 'become_verified.badge_blue',
      'kirmizi' => 'become_verified.badge_red',
      'sari' => 'become_verified.badge_yellow',
      'turkuaz' => 'become_verified.badge_turquoise',
      'gri' => 'become_verified.badge_gray',
      'siyah' => 'become_verified.badge_black',
      _ => '',
    };
    if (baseKey.isNotEmpty) {
      return '$baseKey$titleSuffix';
    }

    for (final baseKey in const <String>[
      'become_verified.badge_blue',
      'become_verified.badge_red',
      'become_verified.badge_yellow',
      'become_verified.badge_turquoise',
      'become_verified.badge_gray',
      'become_verified.badge_black',
    ]) {
      final key = '$baseKey$titleSuffix';
      if (normalized == baseKey || normalized == key) {
        return key;
      }
    }
    return title;
  }

  String _localizedBadgeTitle(String title) => _badgeTitleKey(title).tr;

  String _localizedBadgeDesc(String title) => _badgeDescKey(title).tr;

  bool _requiresAnnualRenewal(String title) {
    final normalized = normalizeRozetValue(title);
    return normalized != 'gri' && normalized != 'siyah';
  }
}
