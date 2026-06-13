import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/models/app_models.dart';
import 'core/router/app_router.dart';
import 'core/state/session_controller.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(SchoolMobileApp(prefs: prefs));
}

class SchoolMobileApp extends StatefulWidget {
  const SchoolMobileApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  State<SchoolMobileApp> createState() => _SchoolMobileAppState();
}

class _SchoolMobileAppState extends State<SchoolMobileApp> {
  late final SessionController _session;
  late GoRouter _router;
  bool? _lastAuthenticated;
  UserRole? _lastRole;

  @override
  void initState() {
    super.initState();
    _session = SessionController(widget.prefs);
    _router = createRouter(_session, navigatorKey: ChuckerFlutter.navigatorKey);
    _lastAuthenticated = _session.isAuthenticated;
    _lastRole = _session.currentRole;
    _session.addListener(_onSessionChanged);
    _session.bootstrap().then((_) {
      if (!mounted) return;
      _lastAuthenticated = _session.isAuthenticated;
      _lastRole = _session.currentRole;
      setState(() => _router = createRouter(_session));
    });
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    final authChanged = _lastAuthenticated != _session.isAuthenticated;
    final roleChanged = _lastRole != _session.currentRole;
    if (!authChanged && !roleChanged) return;

    _lastAuthenticated = _session.isAuthenticated;
    _lastRole = _session.currentRole;
    setState(() => _router = createRouter(_session));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _session,
      child: ListenableBuilder(
        listenable: _session,
        builder: (context, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'School Management',
            locale: _session.locale,
            supportedLocales: const [Locale('en'), Locale('ar')],
            localeListResolutionCallback: (locales, supportedLocales) =>
                _session.locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.light(_session.locale),
            routerConfig: _router,
            builder: (context, child) {
              if (_session.isBootstrapping) {
                return const Scaffold(
                  backgroundColor: AppTheme.surface,
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (child != null) return child;
              return const Scaffold(
                backgroundColor: AppTheme.surface,
                body: Center(child: CircularProgressIndicator()),
              );
            },
          );
        },
      ),
    );
  }
}
