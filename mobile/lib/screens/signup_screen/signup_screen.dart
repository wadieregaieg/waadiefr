import 'package:flutter/material.dart';
import 'package:freshk/screens/signup_screen/widgets/signup_logo.dart';
import 'package:freshk/screens/signup_screen/widgets/signup_title.dart';
import 'package:freshk/screens/signup_screen/widgets/signup_bottom_section.dart';
import 'package:freshk/screens/signup_screen/widgets/signup_form.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const designWidth = 375.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;
    final availableWidth = screenWidth - (2 * horizontalPadding);
    final scale = availableWidth / designWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SignUpLogo(scale: scale),
              SignUpTitle(scale: scale),
              SizedBox(height: 12 * scale),
              SignUpForm(scale: scale),
              SizedBox(
                  height:
                      0 * scale), // Add spacing between form and bottom section
              SignUpBottomSection(scale: scale),
              SizedBox(
                  height: 24 *
                      scale), // Add bottom padding for better accessibility
            ],
          ),
        ),
      ),
    );
  }
}
