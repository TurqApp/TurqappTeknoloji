part of 'family_info_view.dart';

extension _FamilyInfoViewFieldsPart on _FamilyInfoViewState {
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? prefixText,
    String? suffixText,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            if (prefixText != null)
              Transform.translate(
                offset: const Offset(0, -1),
                child: Text(
                  prefixText,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ),
            Expanded(
              child: TextField(
                cursorColor: Colors.black,
                controller: controller,
                keyboardType: keyboardType,
                inputFormatters: formatters,
                decoration: InputDecoration(
                  hintText: hintText,
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
            if (suffixText != null)
              Text(
                suffixText,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String title,
    required String value,
    required String hintText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(20),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value.isEmpty || value == hintText ? hintText : value,
                style: TextStyle(
                  color: value.isEmpty || value == hintText
                      ? Colors.grey
                      : Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_down,
                color: Colors.black45,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
