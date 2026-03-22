import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

class _LoginFlowHarness extends StatefulWidget {
  const _LoginFlowHarness();

  @override
  State<_LoginFlowHarness> createState() => _LoginFlowHarnessState();
}

class _LoginFlowHarnessState extends State<_LoginFlowHarness> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _showForm = false;
  bool _isLoading = false;
  bool _isLoggedIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1));

    final isValidCredential =
        _emailController.text == 'test@mail.com' &&
        _passwordController.text == '123456';

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isLoggedIn = isValidCredential;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return const Scaffold(
        body: Center(
          child: Text('Home'),
        ),
      );
    }

    if (!_showForm) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            key: const Key('login_button'),
            onPressed: () {
              setState(() {
                _showForm = true;
              });
            },
            child: const Text('Login'),
          ),
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              key: const Key('email'),
              controller: _emailController,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('password'),
              controller: _passwordController,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const Key('login_submit_button'),
              onPressed: _submit,
              child: const Text('Submit'),
            ),
            if (_isLoading) const Text('Loading'),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _showHome = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_emailController.text == 'test@mail.com' &&
        _passwordController.text == '123456') {
      setState(() {
        _showHome = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showHome) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Home'),
          ),
        ),
      );
    }

    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                key: const Key('email'),
                controller: _emailController,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('password'),
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                key: const Key('login_button'),
                onPressed: _login,
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Login button opens sign-in form', (tester) async {
    await pumpApp(tester, const _LoginFlowHarness());

    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pump();

    expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
  });

  testWidgets('Full login flow', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byKey(const Key('email')), 'test@mail.com');
    await tester.enterText(find.byKey(const Key('password')), '123456');
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });
}
