part of 'support_contact_view.dart';

extension SupportContactViewCardPart on _SupportContactViewState {
  Widget _buildSupportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'support.card_title'.tr,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: 'MontserratSemiBold',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'support.direct_admin'.tr,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 13,
              fontFamily: 'MontserratMedium',
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'support.topic'.tr,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontFamily: 'MontserratSemiBold',
            ),
          ),
          const SizedBox(height: 8),
          _buildTopicChips(),
          const SizedBox(height: 14),
          _buildMessageField(),
          const SizedBox(height: 14),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildMessageField() {
    return TextField(
      controller: _messageController,
      maxLines: 7,
      minLines: 5,
      decoration: InputDecoration(
        hintText: 'support.message_hint'.tr,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black54),
        ),
      ),
    );
  }
}
