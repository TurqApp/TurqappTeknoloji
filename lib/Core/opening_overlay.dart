import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/connectivity_helper.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';

class OpeningOverlay extends StatefulWidget {
  final Duration minDelay;
  final Duration maxDelay;
  final int precacheCount;
  const OpeningOverlay({
    super.key,
    this.minDelay = const Duration(milliseconds: 120),
    this.maxDelay = const Duration(milliseconds: 1200),
    this.precacheCount = 6,
  });

  @override
  State<OpeningOverlay> createState() => _OpeningOverlayState();
}

class _OpeningOverlayState extends State<OpeningOverlay>
    with SingleTickerProviderStateMixin {
  static bool _displayedOnce = false;
  bool _visible = false;
  late final AnimationController _ac;
  Timer? _maxTimer;
  Timer? _minTimer;
  bool _configured = false;
  late Duration _minDelay;
  late Duration _maxDelay;
  late int _precacheCount;

  AgendaController get _agenda => AgendaController.ensure();

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 200),
    );
    // Sadece ilk uygulama açılışında çalışsın
    if (_displayedOnce) return;
    // Konfigürasyon türet, sonra zamanlayıcıları başlat
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _deriveDynamicConfig();
      if (!mounted) return;
      _schedule();
    });
  }

  void _schedule() {
    // Eğer ilk kısa sürede hazır değilse overlay’i göster
    _minTimer = Timer(_minDelay, () {
      if (!mounted) return;
      if (_agenda.agendaList.length < _precacheCount) {
        setState(() {
          _visible = true;
        });
        _ac.forward();
      }
    });
    // En fazla maxDelay kadar kalsın
    _maxTimer = Timer(_maxDelay, () {
      if (!mounted) return;
      _hide();
    });

    // Liste hazır olduğunda otomatik kapan
    ever<List<PostsModel>>(_agenda.agendaList, (list) {
      if (!mounted) return;
      if (list.length >= _precacheCount) {
        _hide();
        _precacheTop(list);
      }
    });
  }

  Future<void> _precacheTop(List<PostsModel> list) async {
    try {
      final wifi = await ConnectivityHelper.isWifi();
      if (!wifi) return; // mobil veride pre-cache yapma
      final ctx = context;
      final top = list.take(_precacheCount);
      for (final p in top) {
        String? url;
        if (p.thumbnail.isNotEmpty) {
          url = p.thumbnail;
        } else if (p.img.isNotEmpty) {
          url = p.img.first;
        }
        if (url != null && url.isNotEmpty) {
          await precacheImage(CachedNetworkImageProvider(url), ctx)
              .catchError((_) {});
        }
      }
    } catch (_) {}
  }

  void _hide() {
    if (!_visible) {
      _displayedOnce = true;
      return;
    }
    _ac.reverse().whenComplete(() {
      if (!mounted) return;
      setState(() {
        _visible = false;
        _displayedOnce = true;
      });
    });
  }

  Future<void> _deriveDynamicConfig() async {
    if (_configured) return;
    // Varsayılanlar
    _minDelay = widget.minDelay;
    _maxDelay = widget.maxDelay;
    _precacheCount = widget.precacheCount;

    // Heuristik: bağlantı ve ekran genişliği
    final wifi = await ConnectivityHelper.isWifi();
    final width = MediaQuery.of(context).size.width;
    final isLarge = width >= 400;

    if (wifi) {
      _minDelay = const Duration(milliseconds: 120);
      _maxDelay = const Duration(milliseconds: 1200);
      _precacheCount = isLarge ? 8 : 6;
    } else {
      _minDelay = const Duration(milliseconds: 150);
      _maxDelay = const Duration(milliseconds: 900);
      _precacheCount = 4;
    }

    _configured = true;
  }

  @override
  void dispose() {
    _minTimer?.cancel();
    _maxTimer?.cancel();
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || _displayedOnce) return const SizedBox.shrink();
    return FadeTransition(
      opacity: _ac.drive(CurveTween(curve: Curves.easeOut)),
      child: Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CupertinoActivityIndicator(),
          ],
        ),
      ),
    );
  }
}
