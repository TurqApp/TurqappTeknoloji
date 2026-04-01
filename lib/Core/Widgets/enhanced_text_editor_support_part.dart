part of 'enhanced_text_editor.dart';

class FormattingToolbar extends StatelessWidget {
  final PostEditingService editingService;

  const FormattingToolbar({
    super.key,
    required this.editingService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Obx(() {
        final actions = editingService.getFormattingActions();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: actions
              .map(
                (action) => IconButton(
                  icon: Icon(action['icon'] as IconData),
                  onPressed: action['action'] as VoidCallback,
                  color:
                      action['active'] as bool ? Colors.blue : Colors.grey[600],
                  splashRadius: 20,
                ),
              )
              .toList(),
        );
      }),
    );
  }
}

class SuggestionPanel extends StatelessWidget {
  final PostEditingService editingService;
  final Function(SmartSuggestion) onSuggestionApplied;

  const SuggestionPanel({
    super.key,
    required this.editingService,
    required this.onSuggestionApplied,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final suggestions = editingService.suggestions;
      if (suggestions.isEmpty) {
        return const Center(
          child: Text(
            'No suggestions available',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      return ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            leading: _getSuggestionIcon(suggestion.type),
            title: Text(suggestion.suggestion),
            subtitle: Text(_getSuggestionDescription(suggestion)),
            onTap: () => onSuggestionApplied(suggestion),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          );
        },
      );
    });
  }

  Widget _getSuggestionIcon(String type) {
    switch (type) {
      case 'hashtag':
        return const Icon(Icons.tag, color: Colors.blue);
      case 'mention':
        return const Icon(Icons.alternate_email, color: Colors.green);
      case 'grammar':
        return const Icon(Icons.spellcheck, color: Colors.orange);
      case 'emoji':
        return const Icon(Icons.emoji_emotions, color: Colors.yellow);
      default:
        return const Icon(Icons.lightbulb_outline, color: Colors.grey);
    }
  }

  String _getSuggestionDescription(SmartSuggestion suggestion) {
    switch (suggestion.type) {
      case 'hashtag':
        return 'Improve discoverability';
      case 'mention':
        return 'Tag a friend';
      case 'grammar':
        return 'Fix spelling/grammar';
      case 'emoji':
        return 'Add expression';
      default:
        return 'Enhance your content';
    }
  }
}
