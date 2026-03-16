// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:nearpick/core/auth/auth_error_message.dart';
import '../../services/auth_service.dart';

typedef RegisterAction =
    Future<void> Function(
      String email,
      String password,
      String displayName,
      String role,
    );

class RegisterScreen extends StatefulWidget {
  final RegisterAction? onRegister;

  const RegisterScreen({super.key, this.onRegister});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'consumer';
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NearPick - Regisztráció')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                key: const ValueKey('register_name_field'),
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Név'),
              ),
              TextField(
                key: const ValueKey('register_email_field'),
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                key: const ValueKey('register_password_field'),
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Jelszó'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              const Text('Felhasználó típusa:'),
              RadioListTile(
                title: const Text('Vásárló'),
                value: 'consumer',
                groupValue: _role,
                onChanged: (v) => setState(() => _role = v as String),
              ),
              RadioListTile(
                title: const Text('Kereskedő'),
                value: 'merchant',
                groupValue: _role,
                onChanged: (v) => setState(() => _role = v as String),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                key: const ValueKey('register_submit_button'),
                onPressed: _loading
                    ? null
                    : () async {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        try {
                          final register =
                              widget.onRegister ??
                              (
                                String email,
                                String password,
                                String displayName,
                                String role,
                              ) {
                                return AuthService().register(
                                  email: email,
                                  password: password,
                                  displayName: displayName,
                                  role: role,
                                );
                              };
                          await register(
                            _emailCtrl.text.trim(),
                            _passwordCtrl.text.trim(),
                            _nameCtrl.text.trim(),
                            _role,
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
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
                    : const Text('Regisztráció'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
