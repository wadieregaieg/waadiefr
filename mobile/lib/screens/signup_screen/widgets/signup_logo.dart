import 'package:flutter/material.dart';

class SignUpLogo extends StatelessWidget {
  final double scale;

  const SignUpLogo({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, 10 * scale),
      child: Center(
        child: Image.asset(
          'assets/logo.png',
          height: 220 * scale,
          width: 270 * scale,
          semanticLabel: 'App Logo',
        ),
      ),
    );
  }
}
