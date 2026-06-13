import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/data/school_modules.dart';
import '../../core/localization/module_localization.dart';
import '../../core/models/app_models.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final roles = UserRole.values;
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: TextButton.icon(
                  onPressed: () {
                    final next = session.locale.languageCode == 'ar'
                        ? const Locale('en')
                        : const Locale('ar');
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      session.selectLocale(next);
                    });
                  },
                  icon: const Icon(Icons.language_rounded),
                  label: Text(
                    session.locale.languageCode == 'ar'
                        ? t(context, 'english')
                        : t(context, 'arabic'),
                  ),
                ),
              ),
              const _OnboardingHero(),
              const SizedBox(height: 22),
              Text(
                t(context, 'choosePortal'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t(context, 'selectRole'),
                style: const TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 24),
              for (final role in roles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    decoration: AppTheme.softPanel(radius: 24),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _openLogin(context, role),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  gradient: role == UserRole.admin
                                      ? AppTheme.ctaGradient
                                      : AppTheme.promoGradient,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(
                                        alpha: .16,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _icon(role),
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      localizedRoleLabel(context, role),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${modulesForRole(role).length} ${t(context, 'screensAndWorkflows')}',
                                      style: const TextStyle(
                                        color: AppTheme.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton.filled(
                                tooltip: appIsArabic(context)
                                    ? 'فتح بوابة ${localizedRoleLabel(context, role)}'
                                    : 'Open ${roleLabels[role]} portal',
                                onPressed: () => _openLogin(context, role),
                                icon: const Icon(Icons.arrow_forward_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.coral,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/register'),
                child: Text(t(context, 'createAccount')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLogin(BuildContext context, UserRole role) {
    context.go(
      Uri(path: '/login', queryParameters: {'role': role.name}).toString(),
    );
  }

  IconData _icon(UserRole role) {
    return switch (role) {
      UserRole.admin => Icons.admin_panel_settings_rounded,
      UserRole.teacher => Icons.badge_rounded,
      UserRole.student => Icons.school_rounded,
      UserRole.parent => Icons.family_restroom_rounded,
    };
  }
}

class _OnboardingHero extends StatelessWidget {
  const _OnboardingHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 330,
      decoration: AppTheme.softPanel(
        gradient: AppTheme.heroGradient,
        radius: 34,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 38,
            child: Container(
              width: 178,
              height: 178,
              decoration: const BoxDecoration(
                color: AppTheme.honey,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned.directional(
            textDirection: Directionality.of(context),
            top: 36,
            start: 42,
            child: const _FloatingBadge(icon: Icons.school_rounded),
          ),
          Positioned.directional(
            textDirection: Directionality.of(context),
            top: 58,
            end: 48,
            child: const _FloatingBadge(icon: Icons.percent_rounded),
          ),
          const Positioned(top: 78, child: _BookBagIllustration()),
          Positioned.directional(
            textDirection: Directionality.of(context),
            bottom: 30,
            start: 24,
            end: 24,
            child: Column(
              children: [
                Text(
                  t(
                    context,
                    'onboardingTitle',
                  ).replaceAll(' anytime', '\nAnytime'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 25,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t(context, 'onboardingBody'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: .82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .86),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: AppTheme.coral),
    );
  }
}

class _BookBagIllustration extends StatelessWidget {
  const _BookBagIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.directional(
            textDirection: Directionality.of(context),
            top: 8,
            start: 42,
            child: _book(AppTheme.coral, -0.2),
          ),
          Positioned.directional(
            textDirection: Directionality.of(context),
            top: 2,
            end: 38,
            child: _book(AppTheme.mint, 0.2),
          ),
          Container(
            width: 110,
            height: 94,
            margin: const EdgeInsets.only(top: 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff35a9ff), Color(0xff176bd7)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff104fba).withValues(alpha: .25),
                  blurRadius: 20,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            child: Container(
              width: 56,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xff0e59be),
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _book(Color color, double turns) {
    return Transform.rotate(
      angle: turns,
      child: Container(
        width: 36,
        height: 58,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    );
  }
}
