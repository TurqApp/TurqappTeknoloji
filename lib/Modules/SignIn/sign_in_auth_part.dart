part of 'sign_in.dart';

extension SignInAuthPart on _SignInState {
  Widget _brandTypewriter() {
    return _LoginBrandTypewriter(
      key: ValueKey('login-brand-${controller.selection.value}'),
    );
  }
}

class _LoginBrandTypewriter extends StatefulWidget {
  const _LoginBrandTypewriter({super.key});

  @override
  State<_LoginBrandTypewriter> createState() => _LoginBrandTypewriterState();
}

class _LoginBrandTypewriterState extends State<_LoginBrandTypewriter> {
  static const String _word = 'TurqApp';
  Timer? _typingTimer;
  Timer? _cursorTimer;
  Timer? _betaTimer;
  int _typedLength = 0;
  bool _showCursor = true;
  bool _showBeta = false;

  @override
  void initState() {
    super.initState();
    _startTypewriter();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    _betaTimer?.cancel();
    super.dispose();
  }

  void _startTypewriter() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    _typedLength = 1;
    _showCursor = true;
    _showBeta = false;

    _typingTimer = Timer.periodic(const Duration(milliseconds: 110), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_typedLength >= _word.length) {
        timer.cancel();
        _showCursor = false;
        _betaTimer?.cancel();
        _betaTimer = Timer(const Duration(milliseconds: 140), () {
          if (!mounted) return;
          setState(() {
            _showBeta = true;
          });
        });
        setState(() {});
        return;
      }
      setState(() {
        _typedLength += 1;
      });
    });

    _cursorTimer = Timer.periodic(const Duration(milliseconds: 220), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_typedLength >= _word.length) {
        timer.cancel();
        setState(() {});
        return;
      }
      setState(() {
        _showCursor = !_showCursor;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _word.substring(0, _typedLength.clamp(0, _word.length)),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 58,
            fontFamily: 'Noe',
            letterSpacing: 1.0,
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: _showCursor ? 5 : 0,
          margin: EdgeInsets.only(right: _showBeta ? 3 : 0),
          child: AnimatedOpacity(
            opacity: _showCursor ? 1 : 0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              width: 3,
              height: 50,
              color: Colors.black,
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: _showBeta ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              'BETA',
              style: TextStyle(
                color: Colors.black38,
                fontSize: 11,
                letterSpacing: 1.8,
                fontFamily: 'MontserratSemiBold',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
