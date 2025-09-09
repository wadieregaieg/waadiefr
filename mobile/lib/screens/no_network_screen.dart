import 'package:freshk/providers/network_proivder.dart';
import 'package:freshk/extensions/localized_context.dart';
import 'package:freshk/utils/navigation_service.dart';
import 'package:freshk/routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:freshk/utils/freshk_utils.dart';

class NoNetworkScreen extends StatefulWidget {
  const NoNetworkScreen({super.key});

  @override
  State<NoNetworkScreen> createState() => _NoNetworkScreenState();
}

class _NoNetworkScreenState extends State<NoNetworkScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);

    // Listen for network changes to automatically dismiss
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final networkProvider = context.read<NetworkProvider>();
      networkProvider.addListener(_onNetworkChanged);
    });
  }

  @override
  void dispose() {
    final networkProvider = context.read<NetworkProvider>();
    networkProvider.removeListener(_onNetworkChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onNetworkChanged() {
    final networkProvider = context.read<NetworkProvider>();
    if (networkProvider.isOnline && mounted) {
      // Network is back, but don't auto-pop to prevent conflicts
      // Let the user manually retry or the network provider handle it
      // Only pop if we're certain this is the correct navigation action
      if (NavigationService.isCurrentRoute(AppRoutes.noNetwork)) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && NetworkProvider().isOnline) {
            Navigator.of(context).pop();
          }
        });
      }
    }
  }

  Future<void> _onRetryPressed() async {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
    });

    final networkProvider = context.read<NetworkProvider>();

    // Check connectivity manually
    final isConnected = await networkProvider.checkConnectivity();

    if (isConnected && mounted) {
      // Connection restored, go back
      Navigator.of(context).pop();
    } else {
      // Still no connection, show feedback
      if (mounted) {
        FreshkUtils.showErrorSnackbar(
            context, AppLocalizations.of(context)!.noInternetConnection);
      }
    }

    if (mounted) {
      setState(() {
        _isRetrying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated WiFi Icon
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.wifi_off,
                          color: Colors.redAccent,
                          size: 80,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  AppLocalizations.of(context)!.noInternetConnection,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Subtitle
                Text(
                  AppLocalizations.of(context)!.checkNetworkSettings,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Additional help text
                Text(
                  AppLocalizations.of(context)!.makeSureWifiOrMobileData,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Retry Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isRetrying ? null : _onRetryPressed,
                    icon: _isRetrying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(_isRetrying
                        ? AppLocalizations.of(context)!.loading
                        : AppLocalizations.of(context)!.retry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Network status indicator
                Consumer<NetworkProvider>(
                  builder: (context, networkProvider, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: networkProvider.isOnline
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: networkProvider.isOnline
                              ? Colors.green
                              : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            networkProvider.isOnline
                                ? Icons.wifi
                                : Icons.wifi_off,
                            size: 16,
                            color: networkProvider.isOnline
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            networkProvider.isOnline
                                ? context.loc.connected
                                : context.loc.disconnected,
                            style: TextStyle(
                              color: networkProvider.isOnline
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
