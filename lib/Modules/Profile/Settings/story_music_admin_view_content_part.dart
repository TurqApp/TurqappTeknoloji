part of 'story_music_admin_view.dart';

extension StoryMusicAdminViewContentPart on _StoryMusicAdminViewState {
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _editingDocId.isEmpty
                      ? 'admin.story_music.new_track'.tr
                      : 'admin.story_music.edit_track'.tr,
                  style: const TextStyle(
                    fontFamily: 'MontserratBold',
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ),
              if (_editingDocId.isNotEmpty)
                TextButton(
                  onPressed: _isBusy ? null : _resetForm,
                  child: Text(
                    'admin.tasks.clear'.tr,
                    style: const TextStyle(
                      fontFamily: 'MontserratMedium',
                      color: Colors.black54,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _field(
              controller: _titleController, label: 'admin.push.title_field'.tr),
          const SizedBox(height: 10),
          _field(
            controller: _artistController,
            label: 'admin.story_music.artist'.tr,
          ),
          const SizedBox(height: 10),
          _field(
            controller: _audioUrlController,
            label: 'admin.story_music.audio_url'.tr,
            hint: 'https://...',
          ),
          const SizedBox(height: 10),
          _field(
            controller: _coverUrlController,
            label: 'admin.story_music.cover_url'.tr,
            hint: 'https://...',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _field(
                  controller: _categoryController,
                  label: 'admin.story_music.category'.tr,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
                child: _field(
                  controller: _orderController,
                  label: 'admin.story_music.order'.tr,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isBusy ? null : _pickCover,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    'admin.story_music.upload_cover'.tr,
                    style: const TextStyle(fontFamily: 'MontserratMedium'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Text(
                        'admin.story_music.active'.tr,
                        style: const TextStyle(
                          fontFamily: 'MontserratMedium',
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _isActive,
                        onChanged: _isBusy
                            ? null
                            : (value) {
                                _updateViewState(() => _isActive = value);
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_coverUrlController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 120,
                child: CachedNetworkImage(
                  imageUrl: _coverUrlController.text.trim(),
                  cacheManager: TurqImageCacheManager.instance,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) =>
                      Container(color: const Color(0xFFE9EDF0)),
                  errorWidget: (_, __, ___) =>
                      Container(color: const Color(0xFFE9EDF0)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isBusy ? null : _saveTrack,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _editingDocId.isEmpty
                    ? 'admin.story_music.save_track'.tr
                    : 'admin.story_music.save_update'.tr,
                style: const TextStyle(fontFamily: 'MontserratBold'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryList() {
    if (_isLoadingTracks) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_tracks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          'admin.story_music.no_tracks'.tr,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 15,
            fontFamily: 'MontserratMedium',
          ),
        ),
      );
    }

    return Column(
      children: _tracks.map((model) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE7EAEE)),
          ),
          child: Row(
            children: [
              _trackCover(model),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.title.isNotEmpty
                          ? model.title
                          : 'admin.story_music.untitled'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'MontserratSemiBold',
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    if (model.artist.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        model.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'MontserratMedium',
                          fontSize: 12,
                          color: Color(0xFF6F7A85),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'admin.story_music.order_usage'.trParams(
                        <String, String>{
                          'order': '${model.order}',
                          'count': '${model.useCount}',
                        },
                      ),
                      style: const TextStyle(
                        fontFamily: 'MontserratMedium',
                        fontSize: 11,
                        color: Color(0xFF7E8790),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _isBusy ? null : () => _togglePreview(model),
                icon: Icon(
                  _currentPreviewUrl == model.audioUrl
                      ? Icons.pause_circle
                      : Icons.play_circle_fill,
                  size: 30,
                  color: Colors.black,
                ),
              ),
              IconButton(
                onPressed: _isBusy ? null : () => _loadTrack(model),
                icon: const Icon(Icons.edit_outlined, color: Colors.black54),
              ),
              IconButton(
                onPressed: _isBusy ? null : () => _deleteTrack(model),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _trackCover(MusicModel model) {
    final url = model.coverUrl.trim();
    if (url.isEmpty) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFEDF1F4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.music_note, color: Colors.black54),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 52,
        height: 52,
        child: CachedNetworkImage(
          imageUrl: url,
          cacheManager: TurqImageCacheManager.instance,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: const Color(0xFFEDF1F4)),
          errorWidget: (_, __, ___) =>
              Container(color: const Color(0xFFEDF1F4)),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontFamily: 'MontserratMedium'),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(
        fontFamily: 'MontserratMedium',
        color: Colors.black,
      ),
      onChanged: (_) {
        if (label == 'Kapak URL') {
          _updateViewState(() {});
        }
      },
    );
  }
}
