import 'package:flutter/material.dart';
import '../shell/app_shell.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  final _token = TextEditingController();

  bool _sending = false;
  bool _verifying = false;

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final state = AppScope.of(context);
    final email = _email.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await state.sendEmailOtp(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent. Check your email.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    final state = AppScope.of(context);
    final email = _email.text.trim();
    final token = _token.text.trim();

    if (email.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and OTP')),
      );
      return;
    }

    setState(() => _verifying = true);
    try {
      await state.verifyEmailOtp(email: email, token: token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verify failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Email login')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.isAnonymous
                      ? 'Upgrade your account'
                      : 'Manage your account',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'We will email you a one-time code. Enter it here to sign in.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: (_sending || !state.emailOtpSupported) ? null : _sendOtp,
              child: Text(_sending ? 'Sending...' : 'Send OTP'),
            ),
          ),

          const SizedBox(height: 18),

          TextField(
            controller: _token,
            decoration: const InputDecoration(
              labelText: 'OTP code',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: (_verifying || !state.emailOtpSupported) ? null : _verify,
              child: Text(_verifying ? 'Verifying...' : 'Verify & sign in'),
            ),
          ),

          const SizedBox(height: 14),

          if (!state.isAnonymous) ...[
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: () async {
                  await state.signOut();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out')),
                  );
                  Navigator.of(context).pop();
                },
                child: const Text('Sign out'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
