import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _totp = TextEditingController();
  bool _obscurePassword = true;
  int _logoTapCount = 0;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _totp.dispose();
    super.dispose();
  }

  void _onLogoTap() {
    _logoTapCount++;
    if (_logoTapCount >= 7) {
      _logoTapCount = 0;
      _showServerDialog();
    }
  }

  void _showServerDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ServerDialog(
        current: ref.read(endpointProvider),
        onSave: (url) => ref.read(endpointProvider.notifier).set(url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final busy = state is LoginSubmitting;
    final needsTotp = state is LoginNeedsTotp;
    final error = switch (state) {
      LoginIdle(:final error) => error,
      LoginNeedsTotp(:final error) => error,
      _ => null,
    };

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              children: [
                GestureDetector(
                  onTap: _onLogoTap,
                  behavior: HitTestBehavior.opaque,
                  child: const _Logo(),
                ),
                const SizedBox(height: 32),
                if (needsTotp) ..._totpSection(busy, error)
                else ..._loginSection(busy, error, ref.watch(endpointProvider)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _loginSection(bool busy, String? error, String endpoint) => [
    Text(
      'Welcome back',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    const SizedBox(height: 6),
    Text(
      'Sign in to your Ente account',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Colors.white60,
      ),
    ),
    const SizedBox(height: 32),
    TextField(
      controller: _email,
      enabled: !busy,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.mail_outlined, size: 20),
      ),
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _password,
      enabled: !busy,
      obscureText: _obscurePassword,
      autofillHints: const [AutofillHints.password],
      onSubmitted: (_) => busy ? null : _signIn(),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outlined, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    ),
    if (error != null) ...[
      const SizedBox(height: 16),
      _ErrorBanner(message: error),
    ],
    const SizedBox(height: 24),
    FilledButton(
      onPressed: busy ? null : _signIn,
      child: busy
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('Sign in'),
    ),
    if (endpoint != kDefaultEndpoint) ...[
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dns_outlined, size: 12, color: Colors.white38),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              endpoint,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ],
  ];

  List<Widget> _totpSection(bool busy, String? error) => [
    Text(
      'Two-factor authentication',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    const SizedBox(height: 6),
    Text(
      'Enter the 6-digit code from your authenticator app',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Colors.white60,
      ),
    ),
    const SizedBox(height: 32),
    TextField(
      controller: _totp,
      enabled: !busy,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 6,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 28,
        letterSpacing: 10,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      onSubmitted: (_) => busy ? null : _submitTotp(),
      decoration: const InputDecoration(
        counterText: '',
        hintText: '· · · · · ·',
      ),
    ),
    if (error != null) ...[
      const SizedBox(height: 16),
      _ErrorBanner(message: error),
    ],
    const SizedBox(height: 24),
    FilledButton(
      onPressed: busy ? null : _submitTotp,
      child: busy
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Text('Verify'),
    ),
    const SizedBox(height: 12),
    OutlinedButton(
      onPressed: busy
          ? null
          : () => ref.read(loginControllerProvider.notifier).cancelTotp(),
      child: const Text('Back'),
    ),
  ];

  void _signIn() {
    ref.read(loginControllerProvider.notifier).signIn(
      email: _email.text.trim(),
      password: _password.text,
      endpoint: '',
    );
  }

  void _submitTotp() {
    ref.read(loginControllerProvider.notifier).submitTotp(_totp.text);
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(29, 185, 84, 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color.fromRGBO(29, 185, 84, 0.4),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.photo_library_outlined,
            size: 36,
            color: Color.fromRGBO(29, 185, 84, 1),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Entegram',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _ServerDialog extends StatefulWidget {
  const _ServerDialog({required this.current, required this.onSave});
  final String current;
  final Future<void> Function(String) onSave;

  @override
  State<_ServerDialog> createState() => _ServerDialogState();
}

class _ServerDialogState extends State<_ServerDialog> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.current);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = _ctrl.text.trim();
    setState(() => _saving = true);
    try {
      await widget.onSave(url);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _reset() async {
    setState(() => _saving = true);
    try {
      await widget.onSave('');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Server'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your self-hosted Ente server URL.',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            enabled: !_saving,
            autofocus: true,
            keyboardType: TextInputType.url,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Server URL',
              hintText: 'http://192.168.1.10:8080',
              prefixIcon: Icon(Icons.dns_outlined, size: 20),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : _reset,
          child: const Text('Reset to default', style: TextStyle(color: Colors.white38)),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
