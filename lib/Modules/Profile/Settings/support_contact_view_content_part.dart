part of 'support_contact_view.dart';

extension SupportContactViewContentPart on _SupportContactViewState {
  Widget _buildContent(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'support.title'.tr),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Container(
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _SupportContactViewState._topicKeys.map((topicKey) {
        final selected = topicKey == _selectedTopicKey;
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _updateViewState(() => _selectedTopicKey = topicKey),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: selected ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? Colors.black : Colors.black12,
              ),
            ),
            child: Text(
              topicKey.tr,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black,
                fontSize: 13,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ),
        );
      }).toList(),
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
