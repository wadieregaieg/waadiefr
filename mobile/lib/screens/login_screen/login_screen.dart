import 'package:freshk/constants.dart';
import 'package:freshk/extensions/localized_context.dart';
import 'package:freshk/providers/network_proivder.dart';
import 'package:freshk/providers/user_provider.dart';
import 'package:freshk/routes.dart';
import 'package:freshk/screens/login_screen/widgets/login_button.dart';
import 'package:freshk/screens/login_screen/widgets/email_password_fields.dart';
import 'package:freshk/utils/freshk_expections.dart';
import 'package:freshk/utils/freshk_utils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _hasAuthError = false;
  final _formKey = GlobalKey<FormState>();
  late final NetworkProvider networkProvider;

  // Controllers for username/password login
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _hasAuthError = false; // Clear any previous auth errors
      });

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('rememberMe', _rememberMe);

        // Username/password login logic
        await userProvider.authenticateWithJWT(
          _usernameController.text.trim(),
          _passwordController.text,
        );
        if (mounted == false) return;

        // Navigate to main screen on successful authentication
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.main,
          (Route<dynamic> route) => false,
        );
      } catch (e) {
        if (e is AuthenticationException) {
          setState(() {
            _hasAuthError = true;
          });
          final errorMsg = e.message.trim() ?? '';
          if (errorMsg ==
              'No active account found with the given credentials') {
            FreshkUtils.showErrorSnackbar(
                context, context.loc.invalidCredentials);
          } else {
            FreshkUtils.showErrorSnackbar(context,
                errorMsg.isNotEmpty ? errorMsg : context.loc.unexpectedError);
          }
        } else if (e is ValidationException) {
          // Show validation errors (e.g., invalid format, expired sessions)
          setState(() {
            _hasAuthError = false;
          });
          FreshkUtils.showErrorSnackbar(context, e.message);
        } else if (e is TransientServerException) {
          // Show transient server errors with retry option
          setState(() {
            _hasAuthError = false;
          });
          FreshkUtils.showServerErrorDialog(
            context,
            e.message,
            onRetry: () => _submitForm(),
            onDismiss: () {},
          );
        } else if (e is PersistentServerException) {
          // Show persistent server errors
          setState(() {
            _hasAuthError = false;
          });
          FreshkUtils.showServerErrorDialog(
            context,
            e.message,
            onDismiss: () {},
          );
        } else if (e is NetworkException) {
          // Show network-related errors
          setState(() {
            _hasAuthError = false;
          });
          FreshkUtils.showNetworkErrorDialog(
            context,
            e.message,
            onRetry: () => _submitForm(),
          );
        } else if (e is ServerException) {
          // Show generic server-related errors
          setState(() {
            _hasAuthError = false;
          });
          FreshkUtils.showErrorSnackbar(context, e.message);
        } else if (e is FreshkException) {
          // Show other FreshkException messages
          setState(() {
            _hasAuthError = false;
          });
          FreshkUtils.showErrorSnackbar(context, e.message);
        } else {
          setState(() {
            _hasAuthError = false;
          });
          debugPrint("Error during login: $e");
          FreshkUtils.showErrorSnackbar(context, context.loc.unexpectedError);
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    networkProvider = Provider.of<NetworkProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Add listeners to clear auth error when user starts typing
    _usernameController.addListener(() {
      if (_hasAuthError) {
        setState(() {
          _hasAuthError = false;
        });
      }
    });

    _passwordController.addListener(() {
      if (_hasAuthError) {
        setState(() {
          _hasAuthError = false;
        });
      }
    });

    // Remove automatic navigation on network change to prevent conflicts
    // The user should manually retry login when network is back
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    // Remove the network listener properly
    super.dispose();
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
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 20 * scale),
                      _buildLogo(scale),
                      _buildLoginTitle(scale),
                      SizedBox(height: 8 * scale),
                      _buildInputFields(scale),
                      SizedBox(height: 40 * scale),
                    ],
                  ),
                ),
              ),
            ),
            // Contact section pinned to bottom
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: _buildContactSection(scale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(double scale) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 650;

    // Adjust logo size based on screen height
    final logoHeight = isSmallScreen ? 160 * scale : 220 * scale;
    final logoWidth = isSmallScreen ? 200 * scale : 270 * scale;
    final topOffset = isSmallScreen ? 5 * scale : 10 * scale;

    return Transform.translate(
      offset: Offset(0, topOffset),
      child: Center(
        child: Image.asset(
          'assets/logo.png',
          height: logoHeight,
          width: logoWidth,
          semanticLabel: 'App Logo',
        ),
      ),
    );
  }

  Widget _buildLoginTitle(double scale) {
    return Transform.translate(
      offset: Offset(0, -10 * scale),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          AppLocalizations.of(context)!.login,
          style: TextStyle(
            fontSize: 20 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildInputFields(double scale) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 650;
    final spacing = isSmallScreen ? 12 * scale : 18 * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmailPasswordFields(
          usernameController: _usernameController,
          passwordController: _passwordController,
          scale: scale,
          hasAuthError: _hasAuthError,
          showForgotPassword: false,
          rememberMe: _rememberMe,
          onRememberMeChanged: (value) =>
              setState(() => _rememberMe = value ?? false),
          onForgotPassword: () {
            Navigator.pushNamed(context, AppRoutes.forgotPassword);
          },
        ),
        SizedBox(height: spacing),
        LoginButton(
            isLoading: _isLoading, onPressed: _submitForm, scale: scale),
        SizedBox(height: 16 * scale),
        // _buildSignUpLink(scale),
      ],
    );
  }

  Widget _buildContactSection(double scale) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16 * scale),
      color: Colors.transparent,
      child: Text(
        '${AppContacts.supportEmail} | ${AppContacts.whatsappNumber}',
        style: TextStyle(
          fontSize: 14 * scale,
          color: Colors.grey[600],
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSignUpLink(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.loc.dontHaveAnAccount,
          style: TextStyle(
            fontSize: 14 * scale,
            color: Colors.grey[600],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.signup),
          child: Text(
            context.loc.signUp,
            style: TextStyle(
              fontSize: 14 * scale,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
