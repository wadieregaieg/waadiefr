import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:freshk/utils/freshk_utils.dart';

class EmailPasswordFields extends StatefulWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final double scale;
  final bool hasAuthError;
  final bool showForgotPassword;
  final bool rememberMe;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback? onForgotPassword;

  const EmailPasswordFields({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.scale,
    this.hasAuthError = false,
    this.showForgotPassword = true,
    required this.rememberMe,
    required this.onRememberMeChanged,
    this.onForgotPassword,
  });

  @override
  State<EmailPasswordFields> createState() => _EmailPasswordFieldsState();
}

class _EmailPasswordFieldsState extends State<EmailPasswordFields> {
  bool _obscurePassword = true;
  final _borderColor = const Color(0xFF9F9F9F);
  final _textColor = const Color(0xFF8E8E8E);
  final _errorColor = const Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.usernameController,
          keyboardType: TextInputType.text,
          decoration: _inputDecoration(
            label: AppLocalizations.of(context)!.enterYourUsername,
            icon: Icons.person_outline,
            scale: widget.scale,
          ),
          validator: _validateUsername,
        ),
        SizedBox(height: 16 * widget.scale),
        TextFormField(
          controller: widget.passwordController,
          obscureText: _obscurePassword,
          decoration: _inputDecoration(
            label: AppLocalizations.of(context)!.password,
            icon: Icons.lock_outline,
            scale: widget.scale,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: _borderColor,
                size: 24 * widget.scale,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: _validatePassword,
        ),
        SizedBox(height: 12 * widget.scale),
        // Remember Me and Forgot Password row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Remember Me with improved design
            GestureDetector(
              onTap: () => widget.onRememberMeChanged(!widget.rememberMe),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20 * widget.scale,
                    height: 20 * widget.scale,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4 * widget.scale),
                      border: Border.all(
                        color: widget.rememberMe
                            ? const Color(0xFF1AB560)
                            : _borderColor,
                        width: 2,
                      ),
                      color: widget.rememberMe
                          ? const Color(0xFF1AB560)
                          : Colors.transparent,
                    ),
                    child: widget.rememberMe
                        ? Icon(
                            Icons.check,
                            size: 14 * widget.scale,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  SizedBox(width: 8 * widget.scale),
                  Text(
                    AppLocalizations.of(context)!.rememberMe,
                    style: TextStyle(
                      fontSize: 14 * widget.scale,
                      color: const Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Forgot Password
            if (widget.showForgotPassword)
              TextButton(
                onPressed: widget.onForgotPassword ??
                    () {
                      FreshkUtils.showInfoSnackbar(
                          context,
                          AppLocalizations.of(context)!
                              .forgotPasswordFeatureComingSoon);
                    },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * widget.scale,
                    vertical: 4 * widget.scale,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  AppLocalizations.of(context)!.forgotPassword,
                  style: TextStyle(
                    fontSize: 14 * widget.scale,
                    color: const Color(0xFF1AB560),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  OutlineInputBorder _customBorder(double scale) {
    final borderColor = widget.hasAuthError ? _errorColor : _borderColor;
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12 * scale),
      borderSide: BorderSide(color: borderColor, width: 1 * scale),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required double scale,
    Widget? suffixIcon,
  }) {
    final labelColor = widget.hasAuthError ? _errorColor : _textColor;
    final iconColor = widget.hasAuthError ? _errorColor : _borderColor;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: labelColor, fontSize: 14 * scale),
      prefixIcon: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8 * scale),
        child: Icon(icon, color: iconColor, size: 24 * scale),
      ),
      suffixIcon: suffixIcon,
      prefixIconConstraints: BoxConstraints(
        minWidth: 40 * scale,
        minHeight: 40 * scale,
      ),
      border: _customBorder(scale),
      enabledBorder: _customBorder(scale),
      focusedBorder: _customBorder(scale),
      errorBorder: _customBorder(scale),
      focusedErrorBorder: _customBorder(scale),
      contentPadding:
          EdgeInsets.symmetric(vertical: 16 * scale, horizontal: 12 * scale),
    );
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.usernameIsRequired;
    }
    if (value.length < 3) return "Username must be at least 3 characters";
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.enterPassword;
    }
    if (value.length < 6) {
      return AppLocalizations.of(context)!.passwordMustBeAtLeast6Characters;
    }
    return null;
  }
}
