import 'package:freshk/constants.dart';
import 'package:freshk/models/product.dart';
import 'package:freshk/routes.dart';
import 'package:freshk/utils/freshk_utils.dart';
import 'package:freshk/widgets/base64_product_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});
  final imageFit = BoxFit.fitWidth;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.image?.isNotEmpty == true
        ? product.image!
        : FreshkUtils.getFallbackImage(product.name);
    final isBase64 = imageUrl.startsWith('data:image/');
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.productDetail,
        arguments: product, // Passing the product object to the detail screen
      ),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusMedium),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9, // Adjust this ratio as needed
                  child: isBase64
                      ? Base64ProductImage(
                          imageUrl: imageUrl,
                          width: 200,
                          height: 200,
                          fit: imageFit,
                        )
                      : CachedNetworkImage(
                          fit: imageFit,
                          imageUrl: imageUrl,
                          imageBuilder: (context, imageProvider) => Image(
                              image: imageProvider,
                              height: 200,
                              width: 200,
                              fit: imageFit),
                          placeholder: (context, url) =>
                              url.startsWith('assets/')
                                  ? Image.asset(url,
                                      height: 200, width: 200, fit: imageFit)
                                  : Image.network(url,
                                      height: 200, width: 200, fit: imageFit),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.broken_image),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: TextStyles.bodyText),
                  const SizedBox(height: AppDimensions.spacingSmall),
                  Text("${product.price} TND/KG",
                      style: TextStyles.secondaryText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
