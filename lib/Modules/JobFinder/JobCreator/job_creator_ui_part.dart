part of 'job_creator.dart';

extension _JobCreatorUiPart on _JobCreatorState {
  Widget _buildLogoPicker() {
    Widget preview;
    final bytes = controller.croppedImage.value;
    if (bytes != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 112,
          height: 112,
          child: Image.memory(bytes, fit: BoxFit.cover),
        ),
      );
    } else if ((widget.existingJob?.logo.isNotEmpty ?? false)) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 112,
          height: 112,
          child: CachedNetworkImage(
            imageUrl: widget.existingJob!.logo,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      preview = Container(
        width: 112,
        height: 112,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x22000000)),
        ),
        child: const Icon(
          CupertinoIcons.building_2_fill,
          color: Colors.black38,
          size: 40,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        preview,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _imageActionButton(
                label: 'pasaj.job_finder.create.pick_gallery'.tr,
                primary: true,
                onTap: () => controller.pickImage(source: ImageSource.gallery),
              ),
              const SizedBox(height: 8),
              _imageActionButton(
                label: 'pasaj.job_finder.create.take_photo'.tr,
                onTap: () => controller.pickImage(source: ImageSource.camera),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
          border: primary ? null : Border.all(color: const Color(0x22000000)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: primary ? Colors.white : Colors.black,
            fontSize: 13,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
    );
  }

  Widget _selectionField({
    required String label,
    required VoidCallback onTap,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 18,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 22,
        fontFamily: 'MontserratBold',
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontFamily: 'MontserratSemiBold',
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 15,
        fontFamily: 'MontserratMedium',
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x22000000)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x22000000)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x33000000)),
      ),
    );
  }
}
