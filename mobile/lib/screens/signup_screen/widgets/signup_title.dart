import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SignUpTitle extends StatelessWidget {
  final double scale;

  const SignUpTitle({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -10 * scale),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          AppLocalizations.of(context)!.signUp,
          style: TextStyle(
            fontSize: 20 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
