import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/module_localization.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final TextEditingController _baseUrl;
  bool _loading = false;
  bool _showBaseUrl = false;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionController>();
    _baseUrl = TextEditingController(text: session.authStorage.baseUrl);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _baseUrl.dispose();
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
                          'SCHOOL MANAGEMENT',
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
                                    ? appIsArabic(context)
                                          ? 'البريد الإلكتروني مطلوب'
                                          : 'Email is required'
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
                                    ? appIsArabic(context)
                                          ? 'كلمة المرور مطلوبة'
                                          : 'Password is required'
                                    : null,
                              ),
                              if (_showBaseUrl) ...[
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _baseUrl,
                                  decoration: InputDecoration(
                                    labelText: appIsArabic(context)
                                        ? 'عنوان الخادم'
                                        : 'Server URL',
                                    hintText: 'http://192.168.1.101:8000/api',
                                    
                                    prefixIcon: const Icon(Icons.link_rounded),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return appIsArabic(context)
                                          ? 'عنوان الخادم مطلوب'
                                          : 'Server URL is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton(
                                  onPressed: () =>
                                      context.go('/forgot-password'),
                                  child: Text(t(context, 'forgotPassword')),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => setState(() => _showBaseUrl = !_showBaseUrl),
                                icon: Icon(_showBaseUrl
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded),
                                label: Text(appIsArabic(context)
                                    ? 'إعدادات الخادم'
                                    : 'Server settings'),
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
                                            await session.authStorage.setBaseUrl(_baseUrl.text.trim());
                                            await session.login(
                                              email: _email.text.trim(),
                                              password: _password.text,
                                            );
                                            if (!context.mounted) return;
                                            context.go(session.homeRoute);
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
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: Text(t(context, 'createAccount')),
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
