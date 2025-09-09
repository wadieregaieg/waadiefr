import 'package:freshk/utils/freshk_utils.dart';
import 'package:freshk/widgets/base64_product_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final String productName;

  const ProductImage(
      {Key? key, required this.imageUrl, required this.productName})
      : super(key: key);
  final imageFit = BoxFit.fitWidth;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.isNotEmpty == true
        ? imageUrl!
        : FreshkUtils.getFallbackImage(productName);

    // Check if the url is a base64 image
    final isBase64 = url.startsWith('data:image/');

    if (isBase64) {
      return Base64ProductImage(
        imageUrl: url,
        height: 350,
        width: double.infinity,
        fit: imageFit,
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: imageFit,
      imageBuilder: (context, imageProvider) => Image(
        image: imageProvider,
        height: 350,
        width: double.infinity,
        fit: imageFit,
      ),
      placeholder: (context, url) => url.startsWith('assets/')
          ? Image.asset(url, height: 350, width: double.infinity, fit: imageFit)
          : Image.network(url,
              height: 350, width: double.infinity, fit: imageFit),
      errorWidget: (context, url, error) => url.startsWith('assets/')
          ? Image.asset(url, height: 350, width: double.infinity, fit: imageFit)
          : Image.network(url,
              height: 350, width: double.infinity, fit: imageFit),
    );
  }
}
