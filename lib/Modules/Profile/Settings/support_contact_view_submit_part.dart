part of 'support_contact_view.dart';

extension SupportContactViewSubmitPart on _SupportContactViewState {
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _sending ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _sending
            ? const CupertinoActivityIndicator(color: Colors.white)
            : Text(
                'support.send'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'MontserratSemiBold',
                ),
              ),
      ),
    );
  }
}
