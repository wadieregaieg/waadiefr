import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UsernameField extends StatelessWidget {
  final TextEditingController controller;
  final double scale;

  const UsernameField({
    required this.controller,
    required this.scale,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.enterYourUsername,
        prefixIcon: Icon(Icons.person, size: 24 * scale),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12 * scale),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.usernameIsRequired;
        }
        return null;
      },
    );
  }
}
