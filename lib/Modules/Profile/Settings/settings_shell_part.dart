part of 'settings.dart';

extension _SettingsViewShellPart on _SettingsViewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenSettings),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'settings.title'.tr),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ..._buildPrimarySections(),
                      _buildAssignedTasksSection(),
                      _buildAdminSection(),
                      ..._buildSessionSection(),
                      15.ph,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRow(
    String text,
    IconData icon,
    VoidCallback onTap, {
    bool isNew = false,
    bool usePasajIcon = false,
    bool showLanguageLabel = false,
    Key? valueKey,
  }) {
    return TextButton(
      key: valueKey,
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            usePasajIcon
                ? SvgPicture.asset(
                    "assets/icons/sinav.svg",
                    height: 25,
                    colorFilter:
                        const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                  )
                : Icon(icon, size: 25, color: Colors.black),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
            if (showLanguageLabel)
              Text(
                _languageService.currentLanguageLabel,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              )
            else ...[
              if (isNew) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text(
                    "Yeni",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ),
              ],
              const Icon(
                CupertinoIcons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 2),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 13,
              fontFamily: "MontserratBold",
            ),
          ),
        ],
      ),
    );
  }
}
