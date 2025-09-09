import 'package:freshk/routes.dart';
import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void navigateToLogin() {
    final context = navigatorKey.currentContext;
    if (context != null && _canNavigate()) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    }
  }

  static void navigateToMain() {
    final context = navigatorKey.currentContext;
    if (context != null && _canNavigate()) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.main, (_) => false);
    }
  }

  static void navigateToNoNetwork() {
    final context = navigatorKey.currentContext;
    if (context != null && _canNavigate()) {
      // Check if no network screen is already on top
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute != AppRoutes.noNetwork) {
        Navigator.of(context).pushNamed(AppRoutes.noNetwork);
      }
    }
  }

  static void popRoute() {
    final context = navigatorKey.currentContext;
    if (context != null && Navigator.of(context).canPop() && _canNavigate()) {
      Navigator.of(context).pop();
    }
  }

  static void popToRoute(String routeName) {
    final context = navigatorKey.currentContext;
    if (context != null && _canNavigate()) {
      Navigator.of(context).popUntil(
        (route) => route.settings.name == routeName || route.isFirst,
      );
    }
  }

  static void popToMain() {
    final context = navigatorKey.currentContext;
    if (context != null && _canNavigate()) {
      Navigator.of(context).popUntil(
        (route) => route.settings.name == AppRoutes.main || route.isFirst,
      );
    }
  }

  static void replaceWith(String routeName, {Object? arguments}) {
    final context = navigatorKey.currentContext;
    if (context != null && _canNavigate()) {
      Navigator.of(context)
          .pushReplacementNamed(routeName, arguments: arguments);
    }
  }

  static void pushNamed(String routeName, {Object? arguments}) {
    final context = navigatorKey.currentContext;
    if (context != null && _canNavigate()) {
      Navigator.of(context).pushNamed(routeName, arguments: arguments);
    }
  }

  static void pushReplacementNamed(String routeName, {Object? arguments}) {
    final context = navigatorKey.currentContext;
    if (context != null && _canNavigate()) {
      Navigator.of(context)
          .pushReplacementNamed(routeName, arguments: arguments);
    }
  }

  static void pushNamedAndRemoveUntil(
      String routeName, RoutePredicate predicate,
      {Object? arguments}) {
    final context = navigatorKey.currentContext;
    if (context != null && _canNavigate()) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(routeName, predicate, arguments: arguments);
    }
  }

  static bool canPop() {
    final context = navigatorKey.currentContext;
    return context != null && Navigator.of(context).canPop();
  }

  static String? getCurrentRouteName() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      return ModalRoute.of(context)?.settings.name;
    }
    return null;
  }

  static bool isCurrentRoute(String routeName) {
    return getCurrentRouteName() == routeName;
  }

  static bool _canNavigate() {
    final context = navigatorKey.currentContext;
    if (context == null) return false;

    // Check if widget is still mounted
    final widget = context.widget;
    if (widget is StatefulWidget) {
      final state = (widget).createState();
      // Additional safety check - ensure we're not in a disposed state
      return context.mounted;
    }

    return true;
  }

  static void safePop() {
    final context = navigatorKey.currentContext;
    if (context != null && Navigator.of(context).canPop() && _canNavigate()) {
      try {
        Navigator.of(context).pop();
      } catch (e) {
        debugPrint('Error during navigation pop: $e');
      }
    }
  }
}
