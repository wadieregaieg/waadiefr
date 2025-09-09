import 'package:freshk/extensions/localized_context.dart';
import 'package:freshk/routes.dart';
import 'package:freshk/utils/freshk_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:freshk/providers/user_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _borderColor = const Color(0xFF9F9F9F);
  final _textColor = const Color(0xFF8E8E8E);
  final _errorColor = const Color(0xFFD32F2F);
  static final _phoneRegex = RegExp(r'^[0-9]{8}$');
  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  bool _isLoading = false;
  int _selectedTabIndex = 0; // 0 for email, 1 for phone

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      FocusScope.of(context).unfocus();

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        String message;

        if (_selectedTabIndex == 0) {
          // Email reset
          message = await userProvider.requestPasswordReset(
            email: _emailController.text.trim(),
          );
        } else {
          // Phone reset
          final phoneNumber = "+216${_phoneController.text}"; // Tunisia format
          message = await userProvider.requestPasswordReset(
            phoneNumber: phoneNumber,
          );
        }

        if (mounted) {
          FreshkUtils.showSuccessSnackbar(context, message);
          // Navigate to OTP screen for phone, or show success for email
          if (_selectedTabIndex == 1) {
            Navigator.pushNamed(
              context,
              AppRoutes.resetOtp,
              arguments: "+216${_phoneController.text}",
            );
          } else {
            // For email, just show success and go back to login
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          }
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
    const designWidth = 375.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;
    final availableWidth = screenWidth - (2 * horizontalPadding);
    final scale = availableWidth / designWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20 * scale),
                _buildInstructions(scale),
                SizedBox(height: 30 * scale),
                _buildTabSection(scale),
                SizedBox(height: 20 * scale),
                _buildInputField(scale),
                SizedBox(height: 40 * scale),
                _buildSubmitButton(scale),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        context.loc.forgotPasswordTitle,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildInstructions(double scale) {
    return Text(
      _selectedTabIndex == 0
          ? 'Enter your email address and we\'ll send you a link to reset your password.'
          : context.loc.forgotPasswordInstructions,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16 * scale,
        color: Colors.grey[700],
        height: 1.4,
      ),
    );
  }

  Widget _buildTabSection(double scale) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      padding: EdgeInsets.all(4 * scale),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              'Email',
              0,
              scale,
              Icons.email_outlined,
            ),
          ),
          Expanded(
            child: _buildTab(
              'Phone',
              1,
              scale,
              Icons.phone_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, double scale, IconData icon) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
          // Clear form when switching tabs
          _emailController.clear();
          _phoneController.clear();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 12 * scale,
          horizontal: 16 * scale,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8 * scale),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18 * scale,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            SizedBox(width: 8 * scale),
            Text(
              label,
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(double scale) {
    if (_selectedTabIndex == 0) {
      return _buildEmailField(scale);
    } else {
      return _buildPhoneField(scale);
    }
  }

  Widget _buildEmailField(double scale) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(
        labelText: 'Enter your email address',
        labelStyle: TextStyle(color: _textColor, fontSize: 14 * scale),
        prefixIcon:
            Icon(Icons.email_outlined, color: _textColor, size: 20 * scale),
        border: _customBorder(scale),
        enabledBorder: _customBorder(scale),
        focusedBorder: _focusedBorder(scale),
        errorBorder: _errorBorder(scale),
        errorStyle: TextStyle(color: _errorColor, fontSize: 12 * scale),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 16 * scale,
        ),
      ),
      validator: (value) => _validateEmail(value),
    );
  }

  Widget _buildPhoneField(double scale) {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      autofillHints: const [AutofillHints.telephoneNumber],
      decoration: InputDecoration(
        labelText: context.loc.enterYourPhoneNumber,
        labelStyle: TextStyle(color: _textColor, fontSize: 14 * scale),
        prefixIcon:
            Icon(Icons.phone_outlined, color: _textColor, size: 20 * scale),
        prefixText: '+216 ',
        prefixStyle: TextStyle(
          color: Colors.black,
          fontSize: 16 * scale,
          fontWeight: FontWeight.w500,
        ),
        border: _customBorder(scale),
        enabledBorder: _customBorder(scale),
        focusedBorder: _focusedBorder(scale),
        errorBorder: _errorBorder(scale),
        errorStyle: TextStyle(color: _errorColor, fontSize: 12 * scale),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 16 * scale,
        ),
      ),
      validator: (value) => _validatePhone(value),
    );
  }

  Widget _buildSubmitButton(double scale) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16 * scale),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        elevation: 0,
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
              _selectedTabIndex == 0 ? 'Send Reset Link' : context.loc.sendOtp,
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  OutlineInputBorder _customBorder(double scale) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12 * scale),
      borderSide: BorderSide(color: _borderColor, width: 1.5),
    );
  }

  OutlineInputBorder _focusedBorder(double scale) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12 * scale),
      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
    );
  }

  OutlineInputBorder _errorBorder(double scale) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12 * scale),
      borderSide: BorderSide(color: _errorColor, width: 1.5),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return context.loc.phoneNumberRequired;
    }
    if (!_phoneRegex.hasMatch(value)) {
      return context.loc.enterValid8DigitNumber;
    }
    return null;
  }
}
