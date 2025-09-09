import 'package:freshk/routes.dart';
import 'package:flutter/material.dart';
import '../extensions/localized_context.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Base design width.
    const designWidth = 375.0;
    final screenWidth = MediaQuery.of(context).size.width;
    // Compute scale factor if the screen width is less than the design width.
    final scaleFactor =
        screenWidth < designWidth ? screenWidth / designWidth : 1.0;

    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: Transform.scale(
          scale: scaleFactor,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/successfully_created.png',
                        height: 150 * scaleFactor,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.check_circle,
                          size: 150 * scaleFactor,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 35 * scaleFactor),
                      Text(
                        context.loc.successfully,
                        style: TextStyle(
                          fontSize: 24 * scaleFactor,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF424242),
                          letterSpacing: 1 * scaleFactor,
                        ),
                      ),
                      SizedBox(height: 12 * scaleFactor),
                      Text(
                        context.loc.accountCreatedMessage,
                        style: TextStyle(
                          fontSize: 14 * scaleFactor,
                          color: const Color(0xFF9F9F9F),
                          letterSpacing: 1 * scaleFactor,
                        ),
                      ),
                      SizedBox(height: 20 * scaleFactor),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0 * scaleFactor),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.popUntil(context, (route) {
                          return route.settings.name == AppRoutes.main ||
                              route.isFirst;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1AB560),
                      padding: EdgeInsets.symmetric(
                        vertical: 15 * scaleFactor,
                        horizontal: 12 * scaleFactor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12 * scaleFactor),
                      ),
                    ),
                    child: Text(
                      context.loc.goToHome,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16 * scaleFactor,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 18 * scaleFactor),
            ],
          ),
        ),
      ),
    );
  }
}
