import 'package:flutter/material.dart';
import 'hls_player.dart';
import 'hls_controller.dart';

class HLSPlayerExample extends StatefulWidget {
  const HLSPlayerExample({super.key});

  @override
  State<HLSPlayerExample> createState() => _HLSPlayerExampleState();
}

class _HLSPlayerExampleState extends State<HLSPlayerExample> {
  late HLSController _controller;

  // Örnek HLS video URL'leri
  final List<String> _videoUrls = [
    'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8',
    'https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8',
    'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
  ];

  int _currentVideoIndex = 0;
  bool _autoPlay = true;
  bool _loop = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = HLSController();

    // Listen to state changes
    _controller.onStateChanged.listen((state) {
      debugPrint('Player State: $state');
    });

    // Listen to errors
    _controller.onError.listen((error) {
      debugPrint('Player Error: $error');
      _showErrorDialog(error);
    });

    // Listen to position changes
    _controller.onPositionChanged.listen((position) {
      // debugPrint('Position: ${position.inSeconds}s');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Hatası'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _changeVideo(int index) {
    setState(() {
      _currentVideoIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HLS Video Player'),
        backgroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // Video Player
          HLSPlayer(
            url: _videoUrls[_currentVideoIndex],
            controller: _controller,
            autoPlay: _autoPlay,
            loop: _loop,
            showControls: _showControls,
            aspectRatio: 16 / 9,
            backgroundColor: Colors.black,
            loadingWidget: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),

          // Player Info
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Video Selection
                  const Text(
                    'Video Seçin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_videoUrls.length, (index) {
                    return RadioListTile<int>(
                      title: Text('Video ${index + 1}'),
                      subtitle: Text(
                        _videoUrls[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: index,
                      // ignore: deprecated_member_use
                      groupValue: _currentVideoIndex,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        if (value != null) _changeVideo(value);
                      },
                    );
                  }),

                  const Divider(height: 32),

                  // Player Controls
                  const Text(
                    'Oynatıcı Ayarları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  SwitchListTile(
                    title: const Text('Otomatik Oynat'),
                    value: _autoPlay,
                    onChanged: (value) {
                      setState(() {
                        _autoPlay = value;
                      });
                    },
                  ),

                  SwitchListTile(
                    title: const Text('Döngü'),
                    value: _loop,
                    onChanged: (value) {
                      setState(() {
                        _loop = value;
                      });
                      _controller.setLoop(value);
                    },
                  ),

                  SwitchListTile(
                    title: const Text('Kontrolleri Göster'),
                    value: _showControls,
                    onChanged: (value) {
                      setState(() {
                        _showControls = value;
                      });
                    },
                  ),

                  const Divider(height: 32),

                  // Manual Controls
                  const Text(
                    'Manuel Kontroller',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _controller.play(),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Oynat'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _controller.pause(),
                        icon: const Icon(Icons.pause),
                        label: const Text('Duraklat'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _controller.seekTo(0),
                        icon: const Icon(Icons.replay),
                        label: const Text('Başa Sar'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final current = await _controller.getCurrentTime();
                          _controller.seekTo(current + 10);
                        },
                        icon: const Icon(Icons.forward_10),
                        label: const Text('+10s'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Mute Control
                  StreamBuilder<PlayerState>(
                    stream: _controller.onStateChanged,
                    builder: (context, snapshot) {
                      return ElevatedButton.icon(
                        onPressed: () {
                          _controller.setMuted(!_controller.isMuted);
                        },
                        icon: Icon(
                          _controller.isMuted
                              ? Icons.volume_off
                              : Icons.volume_up,
                        ),
                        label: Text(
                          _controller.isMuted ? 'Sesi Aç' : 'Sesi Kapat',
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 32),

                  // Player Stats
                  const Text(
                    'Oynatıcı Bilgileri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  StreamBuilder<PlayerState>(
                    stream: _controller.onStateChanged,
                    builder: (context, snapshot) {
                      final state = snapshot.data ?? PlayerState.idle;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('Durum', _getStateText(state)),
                              const SizedBox(height: 8),
                              StreamBuilder<Duration>(
                                stream: _controller.onPositionChanged,
                                builder: (context, snapshot) {
                                  final position =
                                      snapshot.data ?? Duration.zero;
                                  return _buildInfoRow(
                                    'Pozisyon',
                                    _formatDuration(position),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              StreamBuilder<Duration>(
                                stream: _controller.onDurationChanged,
                                builder: (context, snapshot) {
                                  final duration =
                                      snapshot.data ?? Duration.zero;
                                  return _buildInfoRow(
                                    'Süre',
                                    _formatDuration(duration),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                'URL',
                                _controller.currentUrl ?? 'N/A',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getStateText(PlayerState state) {
    switch (state) {
      case PlayerState.idle:
        return 'Boşta';
      case PlayerState.loading:
        return 'Yükleniyor...';
      case PlayerState.ready:
        return 'Hazır';
      case PlayerState.playing:
        return 'Oynatılıyor';
      case PlayerState.paused:
        return 'Duraklatıldı';
      case PlayerState.buffering:
        return 'Tamponlanıyor...';
      case PlayerState.completed:
        return 'Tamamlandı';
      case PlayerState.error:
        return 'Hata: ${_controller.errorMessage ?? "Bilinmeyen"}';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
