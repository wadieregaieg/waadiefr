import 'package:flutter/material.dart';
import 'package:freshk/constants.dart';
import 'package:freshk/extensions/localized_context.dart';
import 'package:freshk/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BottomNav extends StatelessWidget {
  const BottomNav(
      {super.key, required this.selectedIndex, required this.onTap});
  final int selectedIndex;
  final Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                index: 0,
                icon: FontAwesomeIcons.house,
                label: context.loc.home,
              ),
              _buildNavItem(
                context,
                index: 1,
                icon: FontAwesomeIcons.receipt,
                label: context.loc.history,
              ),
              _buildCartItem(context),
              _buildNavItem(
                context,
                index: 3,
                icon: FontAwesomeIcons.user,
                label: context.loc.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;
    return AnimatedContainer(
      height: 55,
      width: 85,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onTap(index),
          child: Container(
            width: 80, // Increased to match cart item for better balance
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  height: isSelected ? 20 : 18,
                  child: Center(
                    child: FaIcon(
                      icon,
                      color:
                          isSelected ? AppColors.primary : Colors.grey.shade600,
                      size: isSelected ? 20 : 18,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  height: isSelected ? 14 : 12,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade600,
                        fontSize: isSelected ? 12 : 10,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      child: Text(label),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final isSelected = selectedIndex == 2;
        final hasItems = cart.itemCount > 0;
        
        return AnimatedContainer(
          height: 55,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onTap(2),
              child: Container(
                width: 80, // Increased width to accommodate badge
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          height: isSelected ? 20 : 18,
                          child: Center(
                            child: FaIcon(
                              FontAwesomeIcons.cartShopping,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade600,
                              size: isSelected ? 20 : 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          height: isSelected ? 14 : 12,
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade600,
                                fontSize: isSelected ? 12 : 10,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              child: Text(context.loc.cart),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hasItems)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        right: -8, // Moved further right to prevent clipping
                        top: selectedIndex == 2 ? -7 : -5,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                            maxWidth: 24, // Added max width to prevent overflow
                          ),
                          child: Text(
                            cart.itemCount > 99
                                ? '99+'
                                : cart.itemCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9, // Slightly smaller font to fit better
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis, // Handle overflow gracefully
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
