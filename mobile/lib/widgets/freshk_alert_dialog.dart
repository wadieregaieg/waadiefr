import 'package:freshk/utils/app_theme.dart';
import 'package:flutter/material.dart';

class FreshkAlerDialog extends StatelessWidget {
  const FreshkAlerDialog({
    super.key,
    this.scale = 1,
    required this.title,
    required this.content,
    required this.cancelBtnText,
    required this.confirmBtnText,
    required this.onCancel,
    required this.onConfirm,
  });
  final double scale;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String title;
  final String content;
  final String cancelBtnText;
  final String confirmBtnText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actionsAlignment: MainAxisAlignment.center,
      contentPadding: EdgeInsets.all(20 * scale),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        title,
        textAlign: TextAlign.center,
      ),
      content: Text(
        content,
        style:
            TextStyle(fontSize: 12 * scale, color: Colors.black54, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
                vertical: 12 * scale, horizontal: 20 * scale),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18 * scale),
              side: BorderSide(color: AppThemeData.themeData.primaryColor),
            ),
          ),
          child: Text(
            cancelBtnText,
            style: TextStyle(
              color: AppThemeData.themeData.primaryColor,
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextButton(
          onPressed: onConfirm,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
                vertical: 12 * scale, horizontal: 20 * scale),
            backgroundColor: AppThemeData.themeData.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18 * scale),
            ),
          ),
          child: Text(
            confirmBtnText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
