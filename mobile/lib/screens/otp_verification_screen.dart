import 'dart:async';
import 'package:freshk/providers/user_provider.dart';
import 'package:freshk/routes.dart';
import 'package:freshk/utils/freshk_expections.dart';
import 'package:freshk/utils/freshk_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key});

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _borderColor = const Color(0xFF9F9F9F);
  final _activeColor = const Color(0xFF1AB560);
  final _textColor = const Color(0xFF8E8E8E);

  int _resendTimer = 30;
  Timer? _timer;
  bool _isVerifyEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNodes[0].requestFocus());
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

    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    setState(() {
      _isVerifyEnabled = _controllers.every((c) => c.text.isNotEmpty);
    });
  }

  String get _enteredOtp => _controllers.map((c) => c.text).join();

  Future<void> _resendOtp() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final phoneNumber = ModalRoute.of(context)!.settings.arguments as String;

    try {
      await userProvider.requestOtp(phoneNumber);
      if (mounted) {
        _startResendTimer();
        // Clear existing OTP fields
        for (var controller in _controllers) {
          controller.clear();
        }
        setState(() {
          _isVerifyEnabled = false;
        });
        _focusNodes[0].requestFocus();
        FreshkUtils.showSuccessSnackbar(
          context,
          AppLocalizations.of(context)!.otpResentSuccess,
        );
      }
    } catch (e) {
      if (mounted) {
        if (e is FreshkException) {
          FreshkUtils.showErrorSnackbar(context, e.message);
        } else {
          FreshkUtils.showErrorSnackbar(
            context,
            AppLocalizations.of(context)!.otpResendFailed,
          );
        }
      }
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
    });
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final phoneNumber = ModalRoute.of(context)!.settings.arguments as String;

    try {
      await userProvider.verifyOtp(
        phoneNumber,
        _enteredOtp,
      );
      if (mounted == false) return;

      // Navigate to the next screen on successful verification
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.main,
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (e is ValidationException) {
        // Handle invalid OTP errors with localized message
        FreshkUtils.showErrorSnackbar(
          context,
          AppLocalizations.of(context)!.invalidExpiredVerificationCode,
        );
      } else if (e is FreshkException) {
        // Show specific error message from FreshkException
        FreshkUtils.showErrorSnackbar(
          context,
          e.message,
        );
      } else if (e is FormatException) {
        // Handle format errors, e.g., invalid OTP format
        FreshkUtils.showErrorSnackbar(
          context,
          AppLocalizations.of(context)!.invalidOtpFormat,
        );
      } else {
        // Handle other unexpected errors
        FreshkUtils.showErrorSnackbar(
          context,
          AppLocalizations.of(context)!.unexpectedError,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(scale),
          body: _buildBody(scale),
          bottomNavigationBar: _buildVerifyButton(scale),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isLoading
              ? Container(
                  key: const ValueKey('loading'),
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('not_loading')),
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
        AppLocalizations.of(context)!.verifyOtp,
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
    );
  }

  Widget _buildInstructions(double scale) {
    return Text(
      AppLocalizations.of(context)!.otpSentToNumber,
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
        );
      }),
    );
  }

  Widget _buildResendSection(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.didntReceiveCode,
          style: TextStyle(color: _textColor, fontSize: 14 * scale),
        ),
        _resendTimer > 0
            ? Text(
                '${(_resendTimer ~/ 60).toString().padLeft(2, '0')}:${(_resendTimer % 60).toString().padLeft(2, '0')}',
                style: TextStyle(color: _textColor, fontSize: 14 * scale),
              )
            : GestureDetector(
                onTap: _resendOtp,
                child: Text(
                  AppLocalizations.of(context)!.resend,
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
      padding: EdgeInsets.all(16.0 * scale),
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
          AppLocalizations.of(context)!.verify,
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
