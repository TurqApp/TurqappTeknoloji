part of 'editor_nickname.dart';

extension _EditorNicknameContentPart on _EditorNicknameState {
  Widget _buildEditorNicknameContent() {
    final current = userService.currentUserRx.value;
    final rozet = current?.rozet ?? '';
    final nickname = current?.nickname ?? '';

    return Column(
      children: [
        if (rozet.isEmpty) _buildEditableNicknameField(),
        if (rozet.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Obx(() => _buildNicknameStatusRow()),
          )
        else
          _buildLockedNicknameField(nickname),
        if (rozet.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Text(
                  'editor_nickname.verified_locked'.tr,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'editor_nickname.mimic_warning'.tr,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: "Montserrat",
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'editor_nickname.tr_char_info'.tr,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontFamily: "Montserrat",
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Obx(() {
          final canSave = controller.canSave;
          return TurqAppButton(
            onTap: () {
              if (canSave) {
                controller.setData();
              }
            },
            bgColor:
                canSave ? Colors.black : Colors.black.withValues(alpha: 0.3),
          );
        }),
      ],
    );
  }

  Widget _buildEditableNicknameField() {
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.nicknameController,
                autofocus: true,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(20),
                  CustomNicknameFormatter(),
                ],
                decoration: InputDecoration(
                  hintText: 'editor_nickname.hint'.tr,
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontFamily: "MontserratMedium",
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNicknameStatusRow() {
    final checking = controller.isChecking.value;
    final available = controller.isAvailable.value;
    final text = controller.statusText.value;

    Color color;
    if (checking) {
      color = Colors.grey;
    } else if (available == true) {
      color = Colors.green;
    } else if (available == false) {
      color = Colors.red;
    } else {
      color = Colors.grey;
    }

    return Row(
      children: [
        if (checking)
          const SizedBox(
            width: 14,
            height: 14,
            child: CupertinoActivityIndicator(radius: 7),
          ),
        if (checking) const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontFamily: "MontserratMedium",
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockedNicknameField(String nickname) {
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Text(
          nickname,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 15,
            fontFamily: "MontserratMedium",
          ),
        ),
      ),
    );
  }
}
