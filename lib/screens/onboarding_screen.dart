import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/design_system.dart';
import '../widgets/shared_widgets.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: appState.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: SchoolGradients.hero,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: SchoolColors.primary.withValues(alpha: .22),
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Align(
                            alignment: AlignmentDirectional.topEnd,
                            child: TextButton.icon(
                              onPressed: () => appState.setLocale(
                                appState.isArabic
                                    ? const Locale('en')
                                    : const Locale('ar'),
                              ),
                              icon: const Icon(
                                Icons.language_rounded,
                                color: Colors.white,
                              ),
                              label: Text(
                                appState.isArabic
                                    ? t(context, 'english')
                                    : t(context, 'arabic'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const SchoolBagIllustration(size: 236),
                          const SizedBox(height: 20),
                          Text(
                            t(context, 'onboardingTitle'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t(context, 'onboardingBody'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: .84),
                                ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: 210,
                            child: GradientButton(
                              label: t(context, 'startNow'),
                              onPressed: appState.completeOnboarding,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
