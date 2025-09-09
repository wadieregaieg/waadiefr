import 'dart:async';
import 'package:freshk/extensions/localized_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freshk/screens/reset_password_screen.dart';

class ResetOtpScreen extends StatefulWidget {
  final String? phoneNumber;

  const ResetOtpScreen({super.key, this.phoneNumber});

  @override
  _ResetOtpScreenState createState() => _ResetOtpScreenState();
}

class _ResetOtpScreenState extends State<ResetOtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _borderColor = const Color(0xFF9F9F9F);
  final _activeColor = const Color(0xFF1AB560);
  final _textColor = const Color(0xFF8E8E8E);

  bool _isVerifyEnabled = false;
  int _resendTimer = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendTimer = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && !value.contains(RegExp(r'[0-9]'))) return;

    if (value.length == 1 && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    setState(() {
      _isVerifyEnabled = _controllers.every((c) => c.text.isNotEmpty);
    });
  }

  String get _enteredOtp => _controllers.map((c) => c.text).join();
  void _verifyOtp() {
    if (_enteredOtp.length != 6) return;

    // Pass the OTP token to the reset password screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(otpToken: _enteredOtp),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(scale),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildInstructions(scale),
              SizedBox(height: 20 * scale),
              _buildOtpFields(scale),
              SizedBox(height: 20 * scale),
              _buildResendSection(scale),
              const SizedBox(height: 100), // This gap remains fixed.
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildVerifyButton(scale),
    );
  }

  AppBar _buildAppBar(double scale) {
    return AppBar(
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      backgroundColor: Colors.white,
      title: Text(
        context.loc.reset_password_otp_title,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
          fontSize: 28 * scale,
          color: Colors.black,
        ),
      ),
      iconTheme: IconThemeData(color: Colors.black, size: 24 * scale),
      elevation: 0,
    );
  }

  Widget _buildInstructions(double scale) {
    return Text(
      context.loc.reset_password_otp_instructions,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16 * scale,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildOtpFields(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          width: 50 * scale,
          height: 50 * scale,
          margin: EdgeInsets.symmetric(horizontal: 5 * scale),
          decoration: BoxDecoration(
            border: Border.all(
              color: _focusNodes[index].hasFocus ? _activeColor : _borderColor,
            ),
            borderRadius: BorderRadius.circular(8 * scale),
          ),
          child: Center(
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              style: TextStyle(
                color: _activeColor,
                fontSize: 20 * scale,
                fontWeight: FontWeight.bold,
              ),
              onChanged: (value) => _onOtpChanged(index, value),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
              cursorColor: _activeColor,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResendSection(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.loc.reset_password_otp_not_received,
          style: TextStyle(
            color: _textColor,
            fontSize: 14 * scale,
          ),
        ),
        _resendTimer > 0
            ? Text(
                '${(_resendTimer ~/ 60).toString().padLeft(2, '0')}:${(_resendTimer % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 14 * scale,
                ),
              )
            : GestureDetector(
                onTap: _startResendTimer,
                child: Text(
                  context.loc.resend,
                  style: TextStyle(
                    color: _activeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14 * scale,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildVerifyButton(double scale) {
    return Padding(
      padding: EdgeInsets.all(16 * scale),
      child: ElevatedButton(
        onPressed: _isVerifyEnabled ? _verifyOtp : null,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 50 * scale),
          backgroundColor: _isVerifyEnabled ? _activeColor : _borderColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10 * scale),
          ),
        ),
        child: Text(
          context.loc.verify,
          style: TextStyle(
            fontSize: 18 * scale,
            color: Colors.white,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }
}
