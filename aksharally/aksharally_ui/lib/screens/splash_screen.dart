import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppTheme.spaceLG,
          AppTheme.spaceLG,
          AppTheme.spaceLG,
          AppTheme.spaceXL,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 680;
            final verticalPadding = isCompact
                ? AppTheme.spaceMD
                : AppTheme.spaceLG;
            final iconWidth = (constraints.maxWidth * 0.46)
                .clamp(128.0, 176.0)
                .toDouble();
            final minimumContentHeight = (constraints.maxHeight -
                    verticalPadding * 2)
                .clamp(0.0, double.infinity)
                .toDouble();

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: verticalPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    minHeight: minimumContentHeight,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Semantics(
                        image: true,
                        label: 'AksharAlly logo',
                        child: Image.asset(
                          'assets/images/aksharally_logo.webp',
                          width: iconWidth,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: isCompact ? 14 : 20),
                      Text(
                        'AksharAlly',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSM),
                      Text(
                        'Read with confidence.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.72),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: isCompact ? 28 : 40),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: const Text("Let's Begin"),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}