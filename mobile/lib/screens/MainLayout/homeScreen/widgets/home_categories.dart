import 'package:flutter/material.dart';
import 'package:freshk/widgets/category_chip.dart';
import 'package:freshk/models/product_category.dart';
import 'package:freshk/constants.dart';
import 'package:freshk/extensions/localized_context.dart';

/// A horizontal list of selectable product categories for the home screen.
/// Shows a skeleton loader when [categories] is empty.
class HomeCategories extends StatelessWidget {
  final List<ProductCategory> categories;
  final String currentCategory;
  final double scale;
  final void Function(String) onSelectCategory;
  final String allLabel;

  static const String allCategoryKey = 'All';
  static const int skeletonCount = 5;

  const HomeCategories({
    super.key,
    required this.categories,
    required this.currentCategory,
    required this.scale,
    required this.onSelectCategory,
    required this.allLabel,
  });

  String _getCategoryIcon(String categoryName) {
    // Normalize the category name for easier matching
    final name = categoryName.trim().toLowerCase();

    // Define sets for each category type
    const fruitNames = {'fruits', 'fruit'};
    const vegetableNames = {
      'vegetables',
      'vegetable',
      'veggie',
      'légumes',
      'légume'
    };
    const herbNames = {
      'herbs',
      'herb',
      'spices',
      'spice',
      'épices',
      'épice',
      'herbes',
      'herbe'
    };

    if (fruitNames.contains(name)) {
      return 'assets/navIcons/apple.png';
    } else if (vegetableNames.contains(name)) {
      return 'assets/navIcons/vegetable.png';
    } else if (herbNames.contains(name)) {
      return 'assets/navIcons/leaf.png';
    } else {
      return ''; // Default icon for "All" or unknown categories
    }
  }

  String _getCategoryName(BuildContext context, String categoryName) {
    final name = categoryName.trim().toLowerCase();
    // Map normalized names to localization keys
    if (name == 'fruits' || name == 'fruit') {
      return context.loc.fruits;
    } else if (name == 'vegetables' ||
        name == 'vegetable' ||
        name == 'veggie' ||
        name == 'légumes' ||
        name == 'légume') {
      return context.loc.vegetables;
    } else if (name == 'herbs' ||
        name == 'herb' ||
        name == 'spices' ||
        name == 'spice' ||
        name == 'épices' ||
        name == 'épice' ||
        name == 'herbes' ||
        name == 'herbe') {
      return context.loc.herbs;
    } else if (name == allCategoryKey.toLowerCase() ||
        name == allLabel.toLowerCase()) {
      return context.loc.all;
    } else {
      return categoryName;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      // Skeleton loading state
      return SizedBox(
        height: 45 * scale,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: skeletonCount,
          separatorBuilder: (_, __) =>
              SizedBox(width: AppDimensions.spacingSmall * scale),
          itemBuilder: (context, index) {
            return const CategoryChip(
              label: '__skeleton__',
              icon: null,
              image: null,
              isSelected: false,
              scale: 1.0,
            );
          },
        ),
      );
    }

    final List<String> allCategories = [
      allLabel,
      ...categories.map((cat) => cat.name).toList(),
    ];
    return SizedBox(
      height: 45 * scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: allCategories.length,
        separatorBuilder: (_, __) =>
            SizedBox(width: AppDimensions.spacingMedium * scale),
        itemBuilder: (context, index) {
          final categoryName = allCategories[index];
          final isAllCategory = index == 0;
          final isSelected = isAllCategory
              ? currentCategory == allCategoryKey || currentCategory == allLabel
              : currentCategory == categoryName;
          final icon = isAllCategory ? Icons.apps : null;
          final image =
              !isAllCategory && _getCategoryIcon(categoryName).isNotEmpty
                  ? _getCategoryIcon(categoryName)
                  : null;
          final localizedLabel = _getCategoryName(context, categoryName);

          return Semantics(
            button: true,
            label: 'Category: $localizedLabel',
            selected: isSelected,
            child: GestureDetector(
              onTap: () => onSelectCategory(
                  isAllCategory ? allCategoryKey : categoryName),
              child: CategoryChip(
                label: localizedLabel,
                icon: icon,
                image: image,
                isSelected: isSelected,
                scale: scale,
              ),
            ),
          );
        },
      ),
    );
  }
}
