import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginTabs extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;
  final double scale;
  final bool isUsernameTabEnabled; // Add this parameter

  const LoginTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.scale,
    this.isUsernameTabEnabled = true, // Default to enabled
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              AppLocalizations.of(context)!.phone,
              0,
              Icons.phone_outlined,
              scale,
              true, // Phone tab is always enabled
            ),
          ),
          Expanded(
            child: _buildTab(
              AppLocalizations.of(context)!.username,
              1,
              Icons.person_outline,
              scale,
              isUsernameTabEnabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
      String title, int index, IconData icon, double scale, bool isEnabled) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: isEnabled ? () => onTabChanged(index) : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12 * scale),
        decoration: BoxDecoration(
          color: isSelected && isEnabled
              ? const Color(0xFF1AB560)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18 * scale,
              color: isEnabled
                  ? (isSelected ? Colors.white : const Color(0xFF8E8E8E))
                  : Colors.grey.shade400,
            ),
            SizedBox(width: 6 * scale),
            Text(
              title,
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w500,
                color: isEnabled
                    ? (isSelected ? Colors.white : const Color(0xFF8E8E8E))
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
