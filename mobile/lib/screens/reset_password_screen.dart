import 'package:freshk/utils/freshk_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:freshk/providers/user_provider.dart';
import 'package:freshk/screens/password_reset_success_screen.dart';
import '../extensions/localized_context.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? otpToken;

  const ResetPasswordScreen({super.key, this.otpToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _borderColor = const Color(0x0ff9f9f9);
  final _textColor = const Color(0xFF8E8E8E);
  final _errorColor = const Color(0xFFD32F2F);

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  static final _passwordRegex = RegExp(r'^.{6,}$');

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      FocusScope.of(context).unfocus();

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final otpToken = widget.otpToken ?? '';

        await userProvider.confirmPasswordReset(
          otpToken,
          _newPasswordController.text,
        );

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PasswordResetSuccessScreen(),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          FreshkUtils.showErrorSnackbar(context, e.toString());
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a design width of 375.0 (e.g. Galaxy S5) as base.
    const designWidth = 375.0;
    final screenWidth = MediaQuery.of(context).size.width;
    // Horizontal padding is 5% of screen width on each side.
    final horizontalPadding = screenWidth * 0.05;
    // Available width after padding.
    final availableWidth = screenWidth - (2 * horizontalPadding);
    final scale = availableWidth / designWidth;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(scale),
          body: _buildBody(scale),
          bottomNavigationBar: _buildSubmitButton(scale),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  AppBar _buildAppBar(double scale) {
    return AppBar(
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        context.loc.resetPassword,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
          fontSize: 28 * scale,
        ),
      ),
    );
  }

  Widget _buildBody(double scale) {
    return SafeArea(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInstructions(scale),
              SizedBox(height: 20 * scale),
              _buildNewPasswordField(scale),
              SizedBox(height: 20 * scale),
              _buildConfirmPasswordField(scale),
              const SizedBox(height: 100), // This gap remains fixed.
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions(double scale) {
    return Text(
      context.loc.createStrongPasswordInstruction,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16 * scale,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildNewPasswordField(double scale) {
    return TextFormField(
      controller: _newPasswordController,
      obscureText: _obscureNewPassword,
      autofillHints: const [AutofillHints.newPassword],
      inputFormatters: [FilteringTextInputFormatter.deny(' ')],
      decoration:
          _buildInputDecoration(context.loc.enterYourPassword, scale).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
            color: _textColor,
          ),
          onPressed: () =>
              setState(() => _obscureNewPassword = !_obscureNewPassword),
          tooltip: _obscureNewPassword
              ? context.loc.showPassword
              : context.loc.hidePassword,
        ),
      ),
      validator: (value) => _validatePassword(value, isConfirmation: false),
    );
  }

  Widget _buildConfirmPasswordField(double scale) {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      autofillHints: const [AutofillHints.newPassword],
      inputFormatters: [FilteringTextInputFormatter.deny(' ')],
      decoration: _buildInputDecoration(context.loc.reenterYourPassword, scale)
          .copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
            color: _textColor,
          ),
          onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword),
          tooltip: _obscureConfirmPassword
              ? context.loc.showPassword
              : context.loc.hidePassword,
        ),
      ),
      validator: (value) => _validatePassword(value, isConfirmation: true),
    );
  }

  Widget _buildSubmitButton(double scale) {
    return Padding(
      padding: EdgeInsets.all(16.0 * scale),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 50 * scale),
          backgroundColor: const Color(0xFF1AB560),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10 * scale),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20 * scale,
                width: 20 * scale,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                context.loc.resetPassword,
                style: TextStyle(
                  fontSize: 18 * scale,
                  color: Colors.white,
                  fontFamily: 'Roboto',
                ),
              ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, double scale) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _textColor),
      prefixIcon: const Icon(Icons.lock, color: Color(0xFF9F9F9F)),
      border: _customBorder(scale),
      enabledBorder: _customBorder(scale),
      focusedBorder: _customBorder(scale),
      errorBorder: _errorBorder(scale),
      errorStyle: TextStyle(color: _errorColor),
    );
  }

  OutlineInputBorder _customBorder(double scale) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12 * scale),
      borderSide: BorderSide(color: _borderColor),
    );
  }

  OutlineInputBorder _errorBorder(double scale) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12 * scale),
      borderSide: BorderSide(color: _errorColor),
    );
  }

  String? _validatePassword(String? value, {required bool isConfirmation}) {
    if (value == null || value.isEmpty) {
      return isConfirmation
          ? context.loc.pleaseConfirmYourPassword
          : context.loc.passwordIsRequired;
    }

    if (!isConfirmation && !_passwordRegex.hasMatch(value)) {
      return context.loc.passwordMustBeSixCharacters;
    }

    if (isConfirmation && value != _newPasswordController.text) {
      return context.loc.passwordsDoNotMatch;
    }

    return null;
  }
}
