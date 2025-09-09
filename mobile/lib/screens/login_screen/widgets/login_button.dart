import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final double scale;

  const LoginButton({
    required this.isLoading,
    required this.onPressed,
    required this.scale,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1AB560),
        padding: EdgeInsets.symmetric(vertical: 18 * scale), // more padding
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        minimumSize: Size(double.infinity, 54 * scale), // taller min height
      ),
      child: isLoading
          ? Center(
              child: SizedBox(
                height: 22 * scale,
                width: 22 * scale,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.0,
                ),
              ),
            )
          : Text(
              AppLocalizations.of(context)!.login,
              style: TextStyle(
                fontSize: 17 * scale, // slightly smaller
                color: Colors.white,
                height: 1.2, // ensure enough line height
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
