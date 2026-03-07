import 'package:flutter/material.dart';
import 'package:nearpick/core/auth/auth_error_message.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

typedef LoginAction = Future<void> Function(String email, String password);

class LoginScreen extends StatefulWidget {
  final LoginAction? onLogin;

  const LoginScreen({super.key, this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NearPick - Bejelentkezés')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: 'Jelszó'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      try {
                        final login =
                            widget.onLogin ??
                            (String email, String password) {
                              return AuthService().login(
                                email: email,
                                password: password,
                              );
                            };
                        await login(
                          _emailCtrl.text.trim(),
                          _passwordCtrl.text.trim(),
                        );
                      } catch (e) {
                        setState(() {
                          _error = authErrorMessage(e);
                        });
                      } finally {
                        setState(() => _loading = false);
                      }
                    },
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Belépés'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text('Nincs fiókod? Regisztráció'),
            ),
          ],
        ),
      ),
    );
  }
}
