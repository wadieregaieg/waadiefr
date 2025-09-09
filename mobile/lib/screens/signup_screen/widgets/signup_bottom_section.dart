import 'package:freshk/extensions/localized_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:freshk/screens/login_screen/login_screen.dart';

class SignUpBottomSection extends StatelessWidget {
  final double scale;

  const SignUpBottomSection({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 16 * scale),
        _buildLoginPrompt(context, scale),
      ],
    );
  }

  Widget _buildLoginPrompt(BuildContext context, double scale) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: context.loc.alreadyHaveAnAccount,
          style:
              TextStyle(color: const Color(0xFF8E8E8E), fontSize: 14 * scale),
          children: [
            TextSpan(
              text: context.loc.logInHere,
              style: TextStyle(
                color: const Color(0xFF1AB560),
                fontWeight: FontWeight.bold,
                fontSize: 14 * scale,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
