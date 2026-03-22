part of 'create_tutoring_view.dart';

extension CreateTutoringViewUiPart on _CreateTutoringViewState {
  Widget _imageActionButton({
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primary ? Colors.black : const Color(0x22000000),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: primary ? Colors.white : Colors.black,
            fontSize: 14,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
    );
  }

  Widget _selectionField({
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x22000000)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: onTap == null ? Colors.black38 : Colors.black87,
                  fontSize: 15,
                  fontFamily: 'MontserratMedium',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(CupertinoIcons.chevron_down, size: 20),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x22000000)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black12),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontFamily: 'MontserratBold',
      ),
    );
  }
}
