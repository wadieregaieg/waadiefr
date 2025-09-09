import 'package:freshk/extensions/localized_context.dart';
import 'package:freshk/utils/freshk_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:freshk/providers/user_provider.dart';
import 'package:freshk/screens/reset_otp_screen.dart';

class ForgotPasswordPhoneScreen extends StatefulWidget {
  const ForgotPasswordPhoneScreen({super.key});

  @override
  State<ForgotPasswordPhoneScreen> createState() =>
      _ForgotPasswordPhoneScreenState();
}

class _ForgotPasswordPhoneScreenState extends State<ForgotPasswordPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final _borderColor = const Color(0xFF9F9F9F);
  final _textColor = const Color(0xFF8E8E8E);
  final _errorColor = const Color(0xFFD32F2F);
  static final _phoneRegex = RegExp(r'^[0-9]{8}$');
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submitPhone() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      FocusScope.of(context).unfocus();

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final phoneNumber =
            "+216${_phoneController.text}"; // Assuming Tunisia format

        final message = await userProvider.requestPasswordReset(
          phoneNumber: phoneNumber,
        );

        if (mounted) {
          FreshkUtils.showSuccessSnackbar(context, message);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetOtpScreen(phoneNumber: phoneNumber),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInstructions(),
                const SizedBox(height: 20),
                _buildPhoneField(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      centerTitle: true,
      title: Text(
        context.loc.forgotPasswordTitle,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
          fontSize: 28,
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Text(
      context.loc.forgotPasswordInstructions,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildPhoneField() {
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
        labelStyle: TextStyle(color: _textColor),
        prefixIcon: Icon(Icons.phone, color: _textColor),
        border: _customBorder(),
        enabledBorder: _customBorder(),
        focusedBorder: _customBorder(),
        errorBorder: _errorBorder(),
        errorStyle: TextStyle(color: _errorColor),
      ),
      validator: (value) => _validatePhone(value),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitPhone,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: const Color(0xFF1AB560),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                context.loc.sendOtp,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontFamily: 'Roboto',
                ),
              ),
      ),
    );
  }

  OutlineInputBorder _customBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _borderColor),
    );
  }

  OutlineInputBorder _errorBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _errorColor),
    );
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
