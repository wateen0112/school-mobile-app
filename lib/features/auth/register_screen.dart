import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  UserRole _role = UserRole.parent;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthFormScaffold(
      title: 'Register',
      icon: Icons.person_add_alt_1_rounded,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: t(context, 'name')),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: InputDecoration(labelText: t(context, 'email')),
              validator: _required,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<UserRole>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: UserRole.values
                  .map(
                    (role) =>
                        DropdownMenuItem(value: role, child: Text(role.name)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _role = value ?? UserRole.parent),
            ),
            const SizedBox(height: 12),
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(labelText: t(context, 'password')),
              validator: _required,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final session = context.read<SessionController>();
                await session.register(_name.text, _email.text, _role);
                if (!context.mounted) return;
                context.go(
                  Uri(
                    path: '/login',
                    queryParameters: {'role': _role.name},
                  ).toString(),
                );
              },
              child: Text(t(context, 'createAccount')),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;
}

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _AuthFormScaffold(
      title: 'Forgot password',
      icon: Icons.lock_reset_rounded,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(labelText: t(context, 'email')),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t(context, 'resetLinkSent'))),
            ),
            child: Text(t(context, 'sendResetLink')),
          ),
        ],
      ),
    );
  }
}

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _AuthFormScaffold(
      title: 'Verify email',
      icon: Icons.mark_email_read_rounded,
      child: Column(
        children: [
          const Icon(Icons.mark_email_read_rounded, size: 72),
          const SizedBox(height: 16),
          Text(t(context, 'checkEmailVerify')),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {},
            child: Text(t(context, 'resendVerifyEmail')),
          ),
        ],
      ),
    );
  }
}

class _AuthFormScaffold extends StatelessWidget {
  const _AuthFormScaffold({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  decoration: AppTheme.softPanel(radius: 32),
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        child: Container(
                          width: 78,
                          height: 78,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.heroGradient,
                          ),
                          child: Icon(icon, color: Colors.white, size: 38),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 20),
                      child,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
