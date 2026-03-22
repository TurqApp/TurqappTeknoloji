part of 'highlight_picker_sheet.dart';

extension _HighlightPickerSheetCreatePart on _HighlightPickerSheetState {
  Widget _buildEmptyCreateState(StoryHighlightsController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'story.highlights_first_create'.tr,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: 'MontserratSemiBold',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'story.highlights_first_create_body'.tr,
            style: const TextStyle(
              color: Color(0xFF6D6D6D),
              fontSize: 12,
              height: 1.35,
              fontFamily: 'MontserratMedium',
            ),
          ),
          const SizedBox(height: 14),
          _buildNewHighlightForm(controller),
        ],
      ),
    );
  }

  Widget _buildCreateAnotherTile() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _updateViewState(() => _isCreatingNew = true),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFFF3F3F3),
                child: Icon(
                  CupertinoIcons.add,
                  size: 20,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'story.highlights_new'.tr,
                  style: const TextStyle(
                    fontFamily: 'MontserratSemiBold',
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewHighlightForm(StoryHighlightsController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
              color: Colors.white,
            ),
            child: TextField(
              controller: _titleController,
              autofocus: false,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'story.highlights_title_hint'.tr,
                hintStyle: TextStyle(
                  color: Colors.grey.withAlpha(150),
                  fontSize: 14,
                  fontFamily: 'MontserratMedium',
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 14,
                color: Colors.black,
              ),
              onSubmitted: (_) => _submitCreate(controller),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: _isSubmitting ? null : () => _submitCreate(controller),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'common.create'.tr,
                      style: const TextStyle(
                        fontFamily: 'MontserratSemiBold',
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCreate(StoryHighlightsController controller) async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _isSubmitting) return;
    _updateViewState(() => _isSubmitting = true);
    try {
      final created = await controller.createHighlight(
        title: title,
        storyIds: [widget.storyId],
      );
      if (created != null) {
        Get.back();
      } else {
        AppSnackbar('common.error'.tr, 'story.highlights_create_failed'.tr);
      }
    } finally {
      _updateViewState(() => _isSubmitting = false);
    }
  }
}
