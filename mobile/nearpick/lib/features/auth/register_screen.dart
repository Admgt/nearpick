import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

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
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Név'),
              ),
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
                onPressed: _loading
                    ? null
                    : () async {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        try {
                          await AuthService().register(
                            email: _emailCtrl.text.trim(),
                            password: _passwordCtrl.text.trim(),
                            displayName: _nameCtrl.text.trim(),
                            role: _role,
                          );
                          if (mounted) Navigator.of(context).pop();
                        } catch (e) {
                          setState(() {
                            _error = e.toString();
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
