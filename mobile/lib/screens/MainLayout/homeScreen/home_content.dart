import 'dart:async';
import 'package:freshk/constants.dart';
import 'package:freshk/extensions/localized_context.dart';
import 'package:freshk/models/product.dart';
import 'package:freshk/models/product_category.dart';
import 'package:freshk/providers/products_provider.dart';
import 'package:freshk/screens/MainLayout/homeScreen/widgets/home_search_bar.dart';
import 'package:freshk/screens/MainLayout/homeScreen/widgets/home_categories.dart';
import 'package:freshk/screens/MainLayout/homeScreen/widgets/home_product_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  late final ProductProvider productProvider;
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  bool _isSearchControllerInitialized = false;

  @override
  bool get wantKeepAlive => true; // Keep the widget alive between tab switches

  @override
  void initState() {
    super.initState();
    productProvider = Provider.of<ProductProvider>(context, listen: false);
    _searchController.addListener(() {
      if (_isSearchControllerInitialized) {
        _onSearchChanged();
      }
    });
    _searchQuery = '';
    // Add scroll controller for infinite scrolling
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (productProvider.product.isEmpty) {
        productProvider.fetchProductsAndCategories();
      }
      // Mark the search controller as initialized after the first frame
      _isSearchControllerInitialized = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset category and search when returning to HomeContent
    if (productProvider.currentCategory != 'All' || _searchQuery.isNotEmpty) {
      setState(() {
        productProvider.currentCategory = 'All';
        _searchQuery = '';
        _searchController.clear();
      });
      // Temporarily disable the listener to avoid triggering refresh on clear
      _isSearchControllerInitialized = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isSearchControllerInitialized = true;
      });
      _refreshProductsList();
    }
  }

  void _resetCategoryIfInvalid() {
    // Reset category if it's no longer valid (e.g., after navigation)
    if (productProvider.currentCategory != 'All' &&
        !_isValidCategory(productProvider.currentCategory)) {
      if (kDebugMode) {
        print(
            '🔄 Resetting invalid category: ${productProvider.currentCategory}');
      }

      setState(() {
        productProvider.currentCategory = 'All';
      });

      // Refresh products to show all products
      _refreshProductsList();
    }
  }

  bool _isValidCategory(String categoryName) {
    return categoryName == 'All' ||
        productProvider.categories.any((cat) => cat.name == categoryName);
  }

  void _onSearchChanged() {
    final newQuery = _searchController.text.trim().toLowerCase();

    // Only proceed if the query has actually changed
    if (newQuery == _searchQuery) {
      return;
    }

    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = newQuery;
        if (_searchQuery.isNotEmpty &&
            productProvider.currentCategory != 'All') {
          productProvider.currentCategory = 'All';
        }
      });
      _refreshProductsList();
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // User has scrolled to near the bottom, load more data
      _loadMoreProducts();
    }
  }

  Future<void> _loadMoreProducts() async {
    if (productProvider.loading &&
        productProvider.loadingMore &&
        !productProvider.hasMoreProducts) {
      return;
    }

    if (kDebugMode) {
      print(
          '🔄 Loading more products for category: ${productProvider.currentCategory}');
    }

    // Get the category ID for filtering
    final selectedCategoryId = productProvider.currentCategory == 'All'
        ? null
        : productProvider.categories
            .firstWhere(
              (cat) =>
                  cat.name.toLowerCase() ==
                  productProvider.currentCategory.toLowerCase(),
              orElse: () => ProductCategory(id: -1, name: '', description: ''),
            )
            .id;

    // Don't pass category ID if it's not found
    final categoryId = selectedCategoryId == -1 ? null : selectedCategoryId;

    await productProvider.loadMoreProducts(
      categoryId: categoryId,
      searchTerm: _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  void _selectCategory(String category) {
    if (kDebugMode) {
      print(
          '🏷️ Selecting category: $category (current: ${productProvider.currentCategory})');
    }

    setState(() {
      if (_searchQuery.isNotEmpty) {
        _searchQuery = '';
        _searchController.clear();
      }

      // Improved category selection logic
      if (productProvider.currentCategory == category) {
        productProvider.currentCategory = 'All'; // Deselect if already selected
      } else {
        productProvider.currentCategory = category;
      }
    });

    if (kDebugMode) {
      print('🏷️ New selected category: ${productProvider.currentCategory}');
    }

    // Reset products and fetch with the new category filter
    _refreshProductsList();
  }

  Future<void> _refreshProductsList() async {
    if (productProvider.loading || productProvider.loadingMore) return;

    if (kDebugMode) {
      print(
          '🔄 Refreshing products list for category: ${productProvider.currentCategory}, search: $_searchQuery');
    }

    // Get the category ID for filtering
    final selectedCategoryId = productProvider.currentCategory == 'All'
        ? null
        : productProvider.categories
            .firstWhere(
              (cat) =>
                  cat.name.toLowerCase() ==
                  productProvider.currentCategory.toLowerCase(),
              orElse: () => ProductCategory(id: -1, name: '', description: ''),
            )
            .id;

    // Don't pass category ID if it's not found
    final categoryId = selectedCategoryId == -1 ? null : selectedCategoryId;

    if (kDebugMode) {
      print('🔄 Using categoryId: $categoryId for filtering');
    }

    try {
      await productProvider.fetchProductsAndCategories(
        showLoading: true,
        categoryId: categoryId,
        searchTerm: _searchQuery.isEmpty ? null : _searchQuery,
        reset: true, // Force reset to ensure fresh data
      );

      if (kDebugMode) {
        print(
            '✅ Products refreshed successfully. Count: ${productProvider.product.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error refreshing products: $e');
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    return productProvider.product;
  }

  Future<void> _handleRefresh() async {
    await _refreshProductsList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Compute a responsive scale factor.
    final screenWidth = MediaQuery.of(context).size.width;
    // Use AppDimensions.padding if defined, otherwise a default value.
    const padding = AppDimensions.padding;
    const designWidth = 375.0;
    final availableWidth = screenWidth - (2 * padding);
    final scale = availableWidth / designWidth;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      displacement: 40,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSearchBar(
              controller: _searchController,
              onClear: () {
                _debounceTimer?.cancel();
                // Temporarily disable the listener to avoid triggering refresh on clear
                _isSearchControllerInitialized = false;
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
                // Re-enable the listener after clearing
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _isSearchControllerInitialized = true;
                });
                _refreshProductsList();
              },
              onSubmitted: (_) => _refreshProductsList(),
              hintText: context.loc.searchForCropsPlaceholder,
            ),
            SizedBox(height: AppDimensions.spacingMedium * scale),
            _buildSectionHeader(context.loc.categories, ''),
            SizedBox(height: AppDimensions.spacingSmall * scale),
            Consumer<ProductProvider>(
              builder: (context, products, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _resetCategoryIfInvalid();
                });

                return HomeCategories(
                  categories: products.categories,
                  currentCategory: productProvider.currentCategory,
                  scale: scale,
                  onSelectCategory: _selectCategory,
                  allLabel: context.loc.all,
                );
              },
            ),
            SizedBox(height: AppDimensions.spacingMedium * scale),
            _buildSectionHeader(context.loc.products, ''),
            SizedBox(height: AppDimensions.spacingSmall * scale),
            Consumer<ProductProvider>(
              builder: (context, provider, child) {
                return HomeProductGrid(
                  products: _filteredProducts,
                  loading: provider.loading,
                  loadingMore: provider.loadingMore,
                  hasMoreProducts: provider.hasMoreProducts,
                  scale: scale,
                  noMoreProductsText: context.loc.noMoreProductsToLoad,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String actionText,
      {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyles.sectionHeader),
        if (actionText.isNotEmpty)
          TextButton(
            onPressed: onViewAll,
            child: Text(
              actionText,
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}
