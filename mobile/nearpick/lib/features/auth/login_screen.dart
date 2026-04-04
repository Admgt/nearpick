import 'package:flutter/material.dart';
import 'package:nearpick/core/auth/auth_error_message.dart';

import '../../services/auth_service.dart';
import '../../ui/app_chrome.dart';
import 'register_screen.dart';

typedef LoginAction = Future<void> Function(String email, String password);
typedef PasswordResetAction = Future<void> Function(String email);
typedef RegisterScreenBuilder = Widget Function(BuildContext context);

class LoginScreen extends StatefulWidget {
  final LoginAction? onLogin;
  final PasswordResetAction? onPasswordReset;
  final RegisterScreenBuilder? registerScreenBuilder;

  const LoginScreen({
    super.key,
    this.onLogin,
    this.onPasswordReset,
    this.registerScreenBuilder,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _openPasswordResetDialog() async {
    var resetEmail = _emailCtrl.text.trim();
    var resetLoading = false;
    String? resetError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            Future<void> submitReset() async {
              final email = resetEmail.trim();
              if (email.isEmpty) {
                setDialogState(() {
                  resetError = 'Add meg az email-cimedet.';
                });
                return;
              }

              setDialogState(() {
                resetLoading = true;
                resetError = null;
              });

              try {
                final sendReset =
                    widget.onPasswordReset ??
                    (String email) {
                      return AuthService().sendPasswordResetEmail(email: email);
                    };
                await sendReset(email);
                if (!dialogContext.mounted || !mounted) return;
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Elkuldtuk a jelszo-visszaallitasi emailt: $email',
                    ),
                  ),
                );
              } catch (e) {
                setDialogState(() {
                  resetError = authErrorMessage(e);
                });
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() {
                    resetLoading = false;
                  });
                }
              }
            }

            return AlertDialog(
              title: const Text('Elfelejtett jelszo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    key: const ValueKey('password_reset_email_field'),
                    initialValue: resetEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'pelda@email.com',
                    ),
                    onChanged: (value) {
                      resetEmail = value;
                    },
                  ),
                  if (resetError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      resetError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: resetLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Megse'),
                ),
                ElevatedButton(
                  key: const ValueKey('password_reset_submit_button'),
                  onPressed: resetLoading ? null : submitReset,
                  child: resetLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Email kuldese'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NearPick - Bejelentkezés')),
      body: NearPickBackground(
        maxWidth: 560,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: SurfaceCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  TextField(
                    key: const ValueKey('login_email_field'),
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    key: const ValueKey('login_password_field'),
                    controller: _passwordCtrl,
                    decoration: const InputDecoration(labelText: 'Jelszó'),
                    obscureText: true,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const ValueKey('open_password_reset_button'),
                      onPressed: _openPasswordResetDialog,
                      child: const Text('Elfelejtett jelszo?'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    key: const ValueKey('login_submit_button'),
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
                    key: const ValueKey('open_register_button'),
                    onPressed: () {
                      final registerScreen =
                          widget.registerScreenBuilder?.call(context) ??
                          const RegisterScreen();
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => registerScreen));
                    },
                    child: const Text('Nincs fiókod? Regisztráció'),
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
