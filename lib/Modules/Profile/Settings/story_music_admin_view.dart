import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/story_music_library_service.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/music_model.dart';

class StoryMusicAdminView extends StatefulWidget {
  const StoryMusicAdminView({super.key});

  @override
  State<StoryMusicAdminView> createState() => _StoryMusicAdminViewState();
}

class _StoryMusicAdminViewState extends State<StoryMusicAdminView> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final TextEditingController _audioUrlController = TextEditingController();
  final TextEditingController _coverUrlController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _orderController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  late final Future<bool> _canAccessFuture;
  final StoryMusicLibraryService _libraryService =
      StoryMusicLibraryService.instance;
  final List<MusicModel> _tracks = <MusicModel>[];
  String _editingDocId = '';
  bool _isActive = true;
  bool _isBusy = false;
  bool _isLoadingTracks = true;
  String _currentPreviewUrl = '';

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('storyMusic');

  @override
  void initState() {
    super.initState();
    _canAccessFuture = AdminAccessService.canManageSliders();
    _loadTracks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _audioUrlController.dispose();
    _coverUrlController.dispose();
    _categoryController.dispose();
    _orderController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _editingDocId = '';
      _isActive = true;
      _titleController.clear();
      _artistController.clear();
      _audioUrlController.clear();
      _coverUrlController.clear();
      _categoryController.clear();
      _orderController.clear();
    });
  }

  void _loadTrack(MusicModel track) {
    setState(() {
      _editingDocId = track.docID;
      _isActive = track.isActive;
      _titleController.text = track.title;
      _artistController.text = track.artist;
      _audioUrlController.text = track.audioUrl;
      _coverUrlController.text = track.coverUrl;
      _categoryController.text = track.category;
      _orderController.text = track.order > 0 ? track.order.toString() : '';
    });
  }

  Future<int> _resolveNextOrder() async {
    return _libraryService.fetchNextOrder();
  }

  Future<void> _loadTracks({bool forceRemote = false}) async {
    if (!mounted) return;
    setState(() => _isLoadingTracks = true);
    try {
      final tracks = await _libraryService.fetchAdminTracks(
        preferCache: !forceRemote,
        forceRemote: forceRemote,
      );
      if (!mounted) return;
      setState(() {
        _tracks
          ..clear()
          ..addAll(tracks);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingTracks = false);
      }
    }
  }

  Future<void> _pickCover() async {
    final file = await AppImagePickerService.pickSingleImage(context);
    if (file == null) return;

    setState(() => _isBusy = true);
    try {
      final itemId =
          _editingDocId.isNotEmpty ? _editingDocId : DateTime.now().millisecondsSinceEpoch.toString();
      final coverUrl = await WebpUploadService.uploadFileAsWebp(
        storage: FirebaseStorage.instance,
        file: file,
        storagePathWithoutExt: 'storyMusic/$itemId/cover',
      );
      _coverUrlController.text = coverUrl;
      AppSnackbar('Tamam', 'Kapak görseli yüklendi');
    } catch (e) {
      AppSnackbar('Hata', 'Kapak görseli yüklenemedi: $e');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _saveTrack() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final title = _titleController.text.trim();
    final audioUrl = _audioUrlController.text.trim();
    final artist = _artistController.text.trim();
    final coverUrl = _coverUrlController.text.trim();
    final category = _categoryController.text.trim();

    if (title.isEmpty || audioUrl.isEmpty) {
      AppSnackbar('Hata', 'Başlık ve müzik URL zorunlu');
      return;
    }

    setState(() => _isBusy = true);
    try {
      final docId =
          _editingDocId.isNotEmpty ? _editingDocId : DateTime.now().millisecondsSinceEpoch.toString();
      final order = int.tryParse(_orderController.text.trim()) ??
          (_editingDocId.isNotEmpty ? 0 : await _resolveNextOrder());
      final now = DateTime.now().millisecondsSinceEpoch;

      final current = _editingDocId.isNotEmpty
          ? await _libraryService.fetchTrackById(docId, preferCache: true)
          : null;
      final existingUseCount = current?.useCount ?? 0;
      final existingShareCount = current?.shareCount ?? 0;
      final existingStoryCount = current?.storyCount ?? 0;
      final existingLastUsedAt = current?.lastUsedAt ?? 0;
      final existingCreatedAt = current?.createdAt ?? now;

      await _collection.doc(docId).set({
        'title': title,
        'artist': artist,
        'audioUrl': audioUrl,
        'coverUrl': coverUrl,
        'durationMs': current?.durationMs ?? 0,
        'useCount': existingUseCount,
        'shareCount': existingShareCount,
        'storyCount': existingStoryCount,
        'order': order,
        'isActive': _isActive,
        'category': category,
        'lastUsedAt': existingLastUsedAt,
        'createdAt': existingCreatedAt,
        'updatedAt': now,
      }, SetOptions(merge: true));

      AppSnackbar('Tamam', _editingDocId.isEmpty ? 'Parça eklendi' : 'Parça güncellendi');
      _resetForm();
      await _loadTracks(forceRemote: true);
    } catch (e) {
      AppSnackbar('Hata', 'Parça kaydedilemedi: $e');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _deleteTrack(MusicModel track) async {
    setState(() => _isBusy = true);
    try {
      await _collection.doc(track.docID).delete();
      if (_editingDocId == track.docID) {
        _resetForm();
      }
      await _loadTracks(forceRemote: true);
      AppSnackbar('Tamam', 'Parça silindi');
    } catch (e) {
      AppSnackbar('Hata', 'Parça silinemedi: $e');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _togglePreview(MusicModel track) async {
    final url = track.audioUrl.trim();
    if (url.isEmpty) return;
    if (_currentPreviewUrl == url) {
      await _audioPlayer.stop();
      setState(() => _currentPreviewUrl = '');
      return;
    }
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
      setState(() => _currentPreviewUrl = url);
    } catch (e) {
      AppSnackbar('Hata', 'Önizleme oynatılamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'Hikaye Müzikleri'),
            Expanded(
              child: FutureBuilder<bool>(
                future: _canAccessFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data != true) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Bu alan sadece admin erişimine açıktır.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'MontserratMedium',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
                    child: Column(
                      children: [
                        _buildFormCard(),
                        const SizedBox(height: 16),
                        _buildLibraryList(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  _editingDocId.isEmpty ? 'Yeni Parça' : 'Parçayı Düzenle',
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
                  child: const Text(
                    'Temizle',
                    style: TextStyle(
                      fontFamily: 'MontserratMedium',
                      color: Colors.black54,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _field(controller: _titleController, label: 'Başlık'),
          const SizedBox(height: 10),
          _field(controller: _artistController, label: 'Sanatçı'),
          const SizedBox(height: 10),
          _field(
            controller: _audioUrlController,
            label: 'Müzik URL',
            hint: 'https://...',
          ),
          const SizedBox(height: 10),
          _field(
            controller: _coverUrlController,
            label: 'Kapak URL',
            hint: 'https://...',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _field(
                  controller: _categoryController,
                  label: 'Kategori',
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
                child: _field(
                  controller: _orderController,
                  label: 'Sıra',
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
                  label: const Text(
                    'Kapak Yükle',
                    style: TextStyle(fontFamily: 'MontserratMedium'),
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
                      const Text(
                        'Aktif',
                        style: TextStyle(
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
                                setState(() => _isActive = value);
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
                  placeholder: (_, __) => Container(color: const Color(0xFFE9EDF0)),
                  errorWidget: (_, __, ___) => Container(color: const Color(0xFFE9EDF0)),
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
                _editingDocId.isEmpty ? 'Parçayı Kaydet' : 'Güncellemeyi Kaydet',
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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Text(
          'Henüz parça yok',
          style: TextStyle(
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
                      model.title.isNotEmpty ? model.title : 'İsimsiz Parça',
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
                      'Sıra ${model.order} • Kullanım ${model.useCount}',
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
          errorWidget: (_, __, ___) => Container(color: const Color(0xFFEDF1F4)),
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
          setState(() {});
        }
      },
    );
  }
}
