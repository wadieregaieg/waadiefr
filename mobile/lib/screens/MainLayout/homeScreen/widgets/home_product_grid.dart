import 'package:flutter/material.dart';
import 'package:freshk/models/product.dart';
import 'package:freshk/screens/MainLayout/homeScreen/widgets/product_card.dart';
import 'package:freshk/constants.dart';
import 'package:shimmer/shimmer.dart';

class HomeProductGrid extends StatelessWidget {
  final List<Product> products;
  final bool loading;
  final bool loadingMore;
  final bool hasMoreProducts;
  final double scale;
  final String noMoreProductsText;

  const HomeProductGrid({
    super.key,
    required this.products,
    required this.loading,
    required this.loadingMore,
    required this.hasMoreProducts,
    required this.scale,
    required this.noMoreProductsText,
  });

  @override
  Widget build(BuildContext context) {
    Widget skeleton = GridView.builder(
      key: const ValueKey('shimmer'),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppDimensions.spacingMedium * scale,
        mainAxisSpacing: AppDimensions.spacingMedium * scale,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          color: Colors.white,
          elevation: 2.0,
          shadowColor: Colors.black.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppDimensions.radiusMedium)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(color: Colors.grey[200]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 80, height: 12, color: Colors.grey[200]),
                    SizedBox(height: 8),
                    Container(width: 40, height: 12, color: Colors.grey[200]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Widget grid = Column(
      children: [
        GridView.builder(
          key: const ValueKey('products'),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: AppDimensions.spacingMedium * scale,
            mainAxisSpacing: AppDimensions.spacingMedium * scale,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) =>
              ProductCard(product: products[index]),
        ),
        if (loadingMore)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        if (!hasMoreProducts && products.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                noMoreProductsText,
                style: const TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
      ],
    );

    return AnimatedCrossFade(
      firstChild: skeleton,
      secondChild: grid,
      crossFadeState:
          loading ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: const Duration(milliseconds: 350),
      firstCurve: Curves.easeIn,
      secondCurve: Curves.easeOut,
      sizeCurve: Curves.easeInOut,
    );
  }
}
