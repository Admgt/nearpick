// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:nearpick/core/auth/auth_error_message.dart';
import '../../services/auth_service.dart';
import '../../ui/app_chrome.dart';

typedef RegisterAction =
    Future<void> Function(
      String email,
      String password,
      String displayName,
      String role,
      String companyName,
    );

class RegisterScreen extends StatefulWidget {
  final RegisterAction? onRegister;

  const RegisterScreen({super.key, this.onRegister});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'consumer';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NearPick - Regisztráció')),
      body: NearPickBackground(
        maxWidth: 620,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Center(
          child: SingleChildScrollView(
            child: SurfaceCard(
              padding: const EdgeInsets.all(28),
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
                  if (_role == 'merchant')
                    TextField(
                      key: const ValueKey('register_company_name_field'),
                      controller: _companyNameCtrl,
                      decoration: const InputDecoration(labelText: 'Ceg neve'),
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
                            final companyName = _companyNameCtrl.text.trim();
                            if (_role == 'merchant' && companyName.isEmpty) {
                              setState(() {
                                _error = 'Kereskedokent add meg a ceg nevet.';
                              });
                              return;
                            }
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
                                    String companyName,
                                  ) {
                                    return AuthService().register(
                                      email: email,
                                      password: password,
                                      displayName: displayName,
                                      role: role,
                                      companyName: companyName,
                                    );
                                  };
                              await register(
                                _emailCtrl.text.trim(),
                                _passwordCtrl.text.trim(),
                                _nameCtrl.text.trim(),
                                _role,
                                companyName,
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
        ),
      ),
    );
  }
}
