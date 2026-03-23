part of 'pasaj_settings_view.dart';

class _PasajToggleTile extends StatelessWidget {
  const _PasajToggleTile({
    super.key,
    required this.controller,
    required this.title,
  });

  final SettingsController controller;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isOn = controller.pasajVisibility[title] ?? true;
      return GestureDetector(
        key: ValueKey('pasaj-row-$title-$isOn'),
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.setPasajTabVisibility(title, !isOn),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8E8E8)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    SvgPicture.asset(
                      "assets/icons/sinav.svg",
                      height: 22,
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _pasajDisplayTitle(title),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                key: ValueKey('pasaj-switch-$title-$isOn'),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 54,
                height: 32,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isOn ? Colors.black : const Color(0xFFEDEDED),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment:
                      isOn ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
