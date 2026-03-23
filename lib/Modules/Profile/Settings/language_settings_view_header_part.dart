part of 'language_settings_view.dart';

class _LanguageHeader extends StatelessWidget {
  const _LanguageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'language.subtitle'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontFamily: "MontserratBold",
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'language.note'.tr,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 14,
            fontFamily: "MontserratMedium",
          ),
        ),
      ],
    );
  }
}
