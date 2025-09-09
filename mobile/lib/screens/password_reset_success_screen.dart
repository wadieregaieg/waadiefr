import 'package:freshk/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/successfully_created.png',
                    height: 150,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.check_circle,
                      size: 150,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 35),
                  Text(
                    AppLocalizations.of(context)!.passwordResetSuccessful,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF424242),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.yourPasswordHasBeenReset,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9F9F9F),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.popUntil(context, (route) {
                  return route.settings.name == AppRoutes.login;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1AB560),
              padding:
                  const EdgeInsets.symmetric(vertical: 15, horizontal: 148),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Full-width button
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.goToHome,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
