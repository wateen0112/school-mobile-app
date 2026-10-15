import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/models/app_models.dart';
import 'app/app_state.dart';
import 'core/navigation/notification_navigation.dart';
import 'core/network/background_notification_service.dart';
import 'core/router/app_navigator.dart';
import 'core/router/app_router.dart';
import 'core/state/session_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/splash_screen.dart';
import 'features/transportation/services/driver_location_foreground_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  await BackgroundNotificationService.initialize();
  await DriverLocationForegroundService.initialize();
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
  late final AppState _appState;
  late GoRouter _router;
  bool? _lastAuthenticated;
  UserRole? _lastRole;
  bool _splashVisible = true;

  @override
  void initState() {
    super.initState();
    _session = SessionController(widget.prefs);
    _appState = AppState(widget.prefs);
    _router = createRouter(_session, navigatorKey: appNavigatorKey);
    _lastAuthenticated = _session.isAuthenticated;
    _lastRole = _session.currentRole;
    _session.addListener(_onSessionChanged);

    // Bootstrap the session to restore auth state
    _session.bootstrap();

    // Show splash screen for at least 2.5 seconds to allow animation to complete
    setState(() {});

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _splashVisible = false);
      }
    });
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  Future<void> _handleInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message == null) return;
    final route = routeForNotificationPayload(message.data);
    if (!mounted || route == null) return;
    _router.push(route.$1, extra: route.$2);
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _session),
        ChangeNotifierProvider.value(value: _appState),
      ],
      child: ListenableBuilder(
        listenable: _session,
        builder: (context, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: _session.locale.languageCode == 'ar'
                ? 'نظام إدارة المدرسة'
                : 'School Management',
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
              // Show splash screen for first 2 seconds or until bootstrap completes
              if (_splashVisible && _session.isBootstrapping) {
                return const SplashScreen();
              }
              if (_splashVisible) {
                // Show splash screen even if not bootstrapping (first 2 seconds)
                return const SplashScreen();
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
