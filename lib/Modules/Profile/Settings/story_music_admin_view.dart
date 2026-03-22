import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/story_music_library_service.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/music_model.dart';

part 'story_music_admin_view_actions_part.dart';
part 'story_music_admin_view_content_part.dart';

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
    AudioFocusCoordinator.instance.registerAudioPlayer(_audioPlayer);
    _canAccessFuture = AdminAccessService.canAccessTask('story_music');
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
    AudioFocusCoordinator.instance.unregisterAudioPlayer(_audioPlayer);
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updateViewState(VoidCallback updater) {
    if (!mounted) return;
    setState(updater);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'admin.story_music.title'.tr),
            Expanded(
              child: FutureBuilder<bool>(
                future: _canAccessFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data != true) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'admin.no_access'.tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
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
}
