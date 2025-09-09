import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PhoneNumberField extends StatelessWidget {
  final TextEditingController controller;
  final double scale;
  final bool hasAuthError;
  final bool rememberMe;
  final ValueChanged<bool?> onRememberMeChanged;

  const PhoneNumberField({
    Key? key,
    required this.controller,
    required this.scale,
    this.hasAuthError = false,
    required this.rememberMe,
    required this.onRememberMeChanged,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final borderColor =
        hasAuthError ? const Color(0xFFD32F2F) : const Color(0xFF9F9F9F);
    final labelColor =
        hasAuthError ? const Color(0xFFD32F2F) : const Color(0xFF8E8E8E);
    final iconColor =
        hasAuthError ? const Color(0xFFD32F2F) : const Color(0xFF9F9F9F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.phone,
            labelStyle: TextStyle(fontSize: 14 * scale, color: labelColor),
            prefixIcon: Icon(Icons.phone, size: 24 * scale, color: iconColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: BorderSide(color: borderColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: BorderSide(color: borderColor),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.enterYourPhoneNumber;
            }
            if (!RegExp(r'^([2459][0-9]{7})$').hasMatch(value)) {
              return AppLocalizations.of(context)!.pleaseEnterValidPhoneNumber;
            }
            return null;
          },
        ),
        SizedBox(height: 12 * scale),
        // Remember Me for phone login
        Row(
          children: [
            GestureDetector(
              onTap: () => onRememberMeChanged(!rememberMe),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20 * scale,
                    height: 20 * scale,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4 * scale),
                      border: Border.all(
                        color:
                            rememberMe ? const Color(0xFF1AB560) : borderColor,
                        width: 2,
                      ),
                      color: rememberMe
                          ? const Color(0xFF1AB560)
                          : Colors.transparent,
                    ),
                    child: rememberMe
                        ? Icon(
                            Icons.check,
                            size: 14 * scale,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  SizedBox(width: 8 * scale),
                  Text(
                    AppLocalizations.of(context)!.rememberMe,
                    style: TextStyle(
                      fontSize: 14 * scale,
                      color: const Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
