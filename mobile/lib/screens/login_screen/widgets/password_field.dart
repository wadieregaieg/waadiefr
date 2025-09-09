import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final double scale;
  final bool obscureText;
  final VoidCallback onToggleVisibility;

  const PasswordField({
    required this.controller,
    required this.scale,
    required this.obscureText,
    required this.onToggleVisibility,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.enterPassword,
        prefixIcon: Icon(Icons.lock, size: 24 * scale),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            size: 24 * scale,
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12 * scale),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.passwordIsRequired;
        }
        if (value.length < 6) {
          return AppLocalizations.of(context)!.passwordTooShort;
        }
        return null;
      },
    );
  }
}
