part of 'profile_contact.dart';

extension ProfileContactContentPart on _ProfileContactState {
  Widget _buildCallVisibilityTile() {
    return Obx(() {
      return _buildVisibilityTile(
        icon: CupertinoIcons.phone,
        label: 'profile_contact.call'.tr,
        isOn: controller.isCallVisible.value,
        onTap: controller.toggleCallVisibility,
      );
    });
  }

  Widget _buildEmailVisibilityTile() {
    return Obx(() {
      return _buildVisibilityTile(
        icon: CupertinoIcons.at,
        label: 'profile_contact.email'.tr,
        isOn: controller.isEmailVisible.value,
        onTap: controller.toggleEmailVisibility,
      );
    });
  }

  Widget _buildVisibilityTile({
    required IconData icon,
    required String label,
    required bool isOn,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(icon, color: Colors.black),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onTap,
              child: TurqAppToggle(isOn: isOn),
            ),
          ],
        ),
      ),
    );
  }
}
