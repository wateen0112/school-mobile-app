import 'package:flutter/material.dart';

import '../app/api_client.dart';
import '../app/app_state.dart';
import '../app/design_system.dart';
import '../widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _baseUrl = TextEditingController(
    text: widget.appState.baseUrl,
  );
  final _email = TextEditingController(text: 'admin@example.com');
  final _password = TextEditingController(text: 'password123');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _baseUrl.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.appState.setBaseUrl(_baseUrl.text);
      await SchoolApiClient(
        appState: widget.appState,
      ).login(_email.text, _password.text);
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.appState.isArabic
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.school_rounded,
                    color: SchoolColors.secondary,
                    size: 34,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t(context, 'appName'),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.appState.setLocale(
                      widget.appState.isArabic
                          ? const Locale('en')
                          : const Locale('ar'),
                    ),
                    icon: const Icon(Icons.language_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const SchoolBagIllustration(size: 180),
              const SizedBox(height: 24),
              SoftCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        t(context, 'login'),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _baseUrl,
                        decoration: InputDecoration(
                          labelText: t(context, 'apiBaseUrl'),
                          prefixIcon: const Icon(Icons.link_rounded),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? t(context, 'apiBaseUrl')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: t(context, 'email'),
                          prefixIcon: const Icon(Icons.mail_rounded),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? t(context, 'email')
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
                        validator: (value) => value == null || value.isEmpty
                            ? t(context, 'password')
                            : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: SchoolColors.danger),
                        ),
                      ],
                      const SizedBox(height: 20),
                      GradientButton(
                        label: t(context, 'login'),
                        icon: Icons.arrow_forward_rounded,
                        onPressed: _loading ? null : _login,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
