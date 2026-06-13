import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_guard.dart';
import '../../core/models/app_models.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.role});

  final UserRole role;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'admin@example.com');
  final _password = TextEditingController(text: 'password123');
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: AppTheme.softPanel(radius: 32),
                    child: Column(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.heroGradient,
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Welcome back',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '${widget.role.name.toUpperCase()} PORTAL',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _email,
                                decoration: InputDecoration(
                                  labelText: t(context, 'email'),
                                  prefixIcon: const Icon(Icons.mail_rounded),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Email is required'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _password,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: t(context, 'password'),
                                  prefixIcon: const Icon(Icons.lock_rounded),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Password is required'
                                    : null,
                              ),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton(
                                  onPressed: () =>
                                      context.go('/forgot-password'),
                                  child: Text(t(context, 'forgotPassword')),
                                ),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _loading
                                      ? null
                                      : () async {
                                          if (!_formKey.currentState!
                                              .validate()) {
                                            return;
                                          }
                                          setState(() => _loading = true);
                                          final session = context
                                              .read<SessionController>();
                                          try {
                                            await session.login(
                                              email: _email.text.trim(),
                                              password: _password.text,
                                              role: widget.role,
                                            );
                                            if (!context.mounted) return;
                                            final from = GoRouterState.of(
                                              context,
                                            ).uri.queryParameters['from'];
                                            if (AuthGuard.isSafeReturnPath(
                                              from,
                                            )) {
                                              context.go(from!);
                                            } else {
                                              context.go(session.homeRoute);
                                            }
                                          } catch (error) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(error.toString()),
                                              ),
                                            );
                                          } finally {
                                            if (mounted) {
                                              setState(() => _loading = false);
                                            }
                                          }
                                        },
                                  icon: _loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.arrow_forward_rounded),
                                  label: Text(t(context, 'login')),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(t(context, 'changePortal')),
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
