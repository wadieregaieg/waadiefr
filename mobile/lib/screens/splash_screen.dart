import 'package:freshk/providers/network_proivder.dart';
import 'package:freshk/providers/user_provider.dart';
import 'package:freshk/services/update_service.dart';
import 'package:freshk/screens/server_error.dart';
import 'package:freshk/utils/dio_instance.dart';
import 'package:freshk/utils/freshk_expections.dart';
import 'package:freshk/utils/freshk_utils.dart';
import 'package:freshk/widgets/update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freshk/utils/navigation_service.dart';
import 'dart:io' show Platform;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<bool> _checkServerHealth() async {
    try {
      final response = await DioInstance.dio.get("/api/health/");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error checking server health: $e');
      return false;
    }
  }

  Future<void> _initializeApp() async {
    // First check for updates

    final healthCheck = await _checkServerHealth();
    if (!healthCheck) {
      // If server is not healthy, show error and navigate to server error screen
      debugPrint(
          'Server health check failed, navigating to ServerError screen');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ServerError()),
      );
      return;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      // Only check for updates on mobile platforms
      await _checkForUpdates();
    } else {
      // For web or desktop, skip update check
      debugPrint('Skipping update check for non-mobile platform');
    }
    await _checkForUpdates();

    // Then handle authentication
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final networkProvider =
        Provider.of<NetworkProvider>(context, listen: false);

    // Wait a bit for network provider to initialize
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      SharedPreferences.getInstance().then((prefs) {
        final rememberMe = prefs.getBool('rememberMe') ?? false;
        if (rememberMe) {
          _handleAuthentication(userProvider);
        } else {
          _navigateToLogin();
        }
      }).catchError((error) {
        debugPrint('Error accessing SharedPreferences: $error');
        // If we can't access preferences, fall back to login screen
        _navigateToLogin();
      });
    });
  }

  Future<void> _checkForUpdates() async {
    try {
      final updateInfo = await UpdateService.checkForUpdate();

      if (updateInfo != null && updateInfo.updateAvailable) {
        if (!mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: !updateInfo.forceUpdate,
          builder: (context) => UpdateDialog(
            updateInfo: updateInfo,
            onUpdateLater: () {
              // Continue with normal app flow if it's not a forced update
              if (!updateInfo.forceUpdate) {
                debugPrint('User chose to update later');
              }
            },
          ),
        );

        // If it's a forced update and dialog was dismissed, don't continue
        if (updateInfo.forceUpdate) {
          return;
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      // Continue with normal app flow even if update check fails
    }
  }

  Future<void> _handleAuthentication(UserProvider userProvider) async {
    userProvider.currentUser = null; // Reset current user to ensure fresh state

    // Check network before attempting authentication
    final networkProvider =
        Provider.of<NetworkProvider>(context, listen: false);
    if (!networkProvider.isOnline) {
      debugPrint('No network available for authentication');
      _navigateToLogin();
      return;
    }

    try {
      final isAuthenticated = await userProvider.checkUserAuth();

      if (isAuthenticated) {
        if (!mounted) return;
        debugPrint('Authentication successful, navigating to Main Home');
        NavigationService.navigateToMain();
      } else {
        // Authentication was not successful, navigate to login
        if (!mounted) return;
        debugPrint('Authentication failed, navigating to login');
        _navigateToLogin();
      }
    } catch (error) {
      if (!mounted) return;

      if (error is NetworkException) {
        // Network error during authentication
        debugPrint("Network error during authentication: $error");
        if (networkProvider.isOnline) {
          // Network says online but getting network errors - server issue
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ServerError()),
          );
        } else {
          // Network is offline, let network provider handle it
          _navigateToLogin();
        }
      } else if (error is TransientServerException) {
        // Transient server error - show retry option
        debugPrint("Transient server error during authentication: $error");
        FreshkUtils.showServerErrorDialog(
          context,
          error.message,
          onRetry: () => _handleAuthentication(userProvider),
          onDismiss: () => _navigateToLogin(),
        );
      } else if (error is PersistentServerException) {
        // Persistent server error - show server unavailable message
        debugPrint("Persistent server error during authentication: $error");
        FreshkUtils.showServerErrorDialog(
          context,
          error.message,
          onDismiss: () => _navigateToLogin(),
        );
      } else if (error is FreshkException) {
        FreshkUtils.showErrorSnackbar(context, error.message);
        _navigateToLogin();
      } else {
        // Handle other exceptions
        debugPrint("Error during authentication: $error");
        FreshkUtils.showErrorSnackbar(
            context, "An unexpected error occurred. Please try again.");
        _navigateToLogin();
      }
    }
  }

  void _navigateToLogin() async {
    // Add a short delay for splash effect, then navigate to login screen
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    NavigationService.navigateToLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogo(),
            const SizedBox(height: 20),
            _buildProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/logo.png',
      height: 100,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading logo: $error');
        return Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              'Failed to load app logo',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1AB560)),
    );
  }
}
