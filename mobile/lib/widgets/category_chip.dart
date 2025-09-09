import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? image;
  final bool isSelected;
  final double scale;

  const CategoryChip({
    Key? key,
    required this.label,
    required this.isSelected,
    this.icon,
    this.image,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (label == '__skeleton__') {
      // Shimmer skeleton for category chip
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding:
              EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20 * scale),
            border: Border.all(color: Colors.grey),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20 * scale,
                height: 20 * scale,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
              ),
              SizedBox(width: 8 * scale),
              Container(
                width: 50 * scale,
                height: 14 * scale,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(7 * scale),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding:
          EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: isSelected ? AppColors.primary : Colors.grey),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 250),
        style: TextStyle(
          fontSize: 14 * scale,
          color: isSelected ? AppColors.primary : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon,
                  size: 20 * scale,
                  color: isSelected ? AppColors.primary : Colors.grey),
            if (image != null && image!.isNotEmpty)
              Image.asset(
                image!,
                width: 20 * scale,
                height: 20 * scale,
                color: isSelected ? AppColors.primary : Colors.grey,
              ),
            SizedBox(width: 8 * scale),
            Text(label),
          ],
        ),
      ),
    );
  }
}
