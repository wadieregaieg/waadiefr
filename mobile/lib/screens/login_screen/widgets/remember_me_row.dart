import 'package:flutter/material.dart';
import 'package:freshk/routes.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RememberMeRow extends StatelessWidget {
  final bool rememberMe;
  final ValueChanged<bool?> onChanged;
  final double scale;
  final int tabIndex = 0;

  const RememberMeRow({
    required this.rememberMe,
    required this.onChanged,
    required this.scale,
    required int tabIndex,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: rememberMe,
              onChanged: onChanged,
            ),
            Text(
              AppLocalizations.of(context)!.rememberMe,
              style: TextStyle(fontSize: 14 * scale),
            ),
          ],
        ),
        if (tabIndex == 1)
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.forgotPassword);
            },
            child: Text(
              AppLocalizations.of(context)!.forgotPassword,
              style: TextStyle(
                fontSize: 14 * scale,
                color: const Color(0xFF1AB560),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
