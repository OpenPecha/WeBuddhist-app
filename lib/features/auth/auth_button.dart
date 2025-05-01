import 'package:flutter/material.dart';
import 'auth_service.dart';

class AuthButton extends StatefulWidget {
  const AuthButton({super.key});

  @override
  State<AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<AuthButton> {
  bool _loading = false;
  String? _error;

  void _handleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final authService = AuthService();
    final credentials = await authService.loginWithGoogle();
    setState(() {
      _loading = false;
      _error = credentials == null ? 'Login failed' : null;
    });
    // You can use credentials here for further logic (e.g., navigation)
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _loading ? null : _handleLogin,
          child:
              _loading
                  ? const CircularProgressIndicator()
                  : const Text('Login with Google'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }
}
