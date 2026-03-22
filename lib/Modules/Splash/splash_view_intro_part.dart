part of 'splash_view.dart';

extension _SplashViewIntroPart on _SplashViewState {
  void _disposeSplashTimers() {
    _startupWatchdogTimer?.cancel();
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
  }

  void _performStartTypewriter() {
    if (_remainingIntroBudget <= Duration.zero) {
      _typedLength = _SplashViewState._splashWord.length;
      _showCursor = false;
      return;
    }

    _typedLength = 1;
    final remainingChars = (_SplashViewState._splashWord.length - 1).clamp(
      0,
      _SplashViewState._splashWord.length,
    );
    if (remainingChars == 0) {
      _showCursor = false;
      return;
    }

    final stepMs = (_remainingIntroBudget.inMilliseconds /
            _SplashViewState._splashWord.length)
        .round()
        .clamp(1, 1000);

    _typingTimer = Timer.periodic(Duration(milliseconds: stepMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_typedLength >= _SplashViewState._splashWord.length) {
        _showCursor = false;
        timer.cancel();
        _updateSplashState(() {});
        return;
      }
      _updateSplashState(() {
        _typedLength += 1;
      });
    });

    _cursorTimer = Timer.periodic(const Duration(milliseconds: 220), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_typedLength >= _SplashViewState._splashWord.length) {
        _showCursor = false;
        timer.cancel();
        _updateSplashState(() {});
        return;
      }
      _updateSplashState(() {
        _showCursor = !_showCursor;
      });
    });
  }

  Widget _buildSplashView(BuildContext context) {
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenSplash),
      backgroundColor: Colors.black,
      body: Center(
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _SplashViewState._splashWord.substring(
                      0,
                      _typedLength.clamp(
                          0, _SplashViewState._splashWord.length),
                    ),
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                      fontFamily: 'Noe',
                      fontSize: 100,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedOpacity(
                    opacity: _showCursor ? 1 : 0,
                    duration: const Duration(milliseconds: 120),
                    child: Container(
                      width: 3,
                      height: 84,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
