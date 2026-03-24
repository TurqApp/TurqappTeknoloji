part of 'support_contact_view.dart';

extension SupportContactViewTopicsPart on _SupportContactViewState {
  Widget _buildTopicChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _supportTopicKeys.map((topicKey) {
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
}

const List<String> _supportTopicKeys = <String>[
  'support.topic.account',
  'support.topic.payment',
  'support.topic.technical',
  'support.topic.content',
  'support.topic.suggestion',
];
