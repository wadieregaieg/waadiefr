import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class Base64ProductImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const Base64ProductImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheHeight: 400,
      filterQuality: FilterQuality.high,
      useOldImageOnUrlChange: true,
      placeholder: (context, url) => Center(
          child: SizedBox(
              height: 50, width: 50, child: const CircularProgressIndicator())),
      errorWidget: (context, url, error) =>
          placeholder ?? const Icon(Icons.broken_image, size: 40),
    );
  }
}
