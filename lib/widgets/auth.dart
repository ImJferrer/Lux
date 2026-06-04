import 'package:flutter/material.dart';
import 'package:lux_app/services/auth_services.dart';

class _AuthSheet extends StatefulWidget {
  const _AuthSheet();

  @override
  _AuthSheetState createState() => _AuthSheetState();
}

class _AuthSheetState extends State<_AuthSheet> {
  final _mail = TextEditingController();
  final _pass = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await AuthService.signInWithEmail(_mail.text, _pass.text);
      } else {
        await AuthService.register(_mail.text, _pass.text);
      }
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sesión iniciada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await AuthService.signInWithGoogle();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión iniciada con Google')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, pad + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isLogin ? 'Iniciar sesión' : 'Crear cuenta',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _mail,
            decoration: const InputDecoration(labelText: 'Correo'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pass,
            decoration: const InputDecoration(labelText: 'Contraseña'),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: Text(_isLogin ? 'Entrar' : 'Registrar'),
          ),
          TextButton(
            onPressed: () => setState(() => _isLogin = !_isLogin),
            child: Text(_isLogin ? 'Crear cuenta' : 'Ya tengo cuenta'),
          ),
          const Divider(),
          OutlinedButton.icon(
            icon: const Icon(Icons.g_mobiledata),
            label: const Text('Entrar con Google'),
            onPressed: _loading ? null : _signInWithGoogle,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mail.dispose();
    _pass.dispose();
    super.dispose();
  }
}
