
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:crypted/gen/assets.gen.dart';

import '../../core/constants/theme/colors_manager.dart';
import 'custom_shimmer.dart';

class AppCashedImage extends StatelessWidget {
  final String imageUrl;
  final double? radius, width, height;
  final BoxFit? fit;
  final Color? borderColor;
  final double? borderWidth;
  final bool isCircular;
  final Color? color;
  const AppCashedImage({
    required this.imageUrl,
    this.width = 150,
    this.height = 150,
    this.radius,
    this.fit,
    this.borderColor,
    this.borderWidth,
    this.isCircular = false,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: borderColor == null
            ? null
            : Border.all(
                color: borderColor ?? Theme.of(context).primaryColor,
                width: borderWidth ?? 0,
              ),
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircular ? null : BorderRadius.circular(radius ?? 12),
      ),
      child: CachedNetworkImage(
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            color: color ?? ColorsManager.primary1000.withOpacity(.2),
            shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircular
                ? null
                : BorderRadius.only(
                    topLeft: Radius.circular(radius ?? 12),
                    topRight: Radius.circular(radius ?? 12),
                    bottomLeft: Radius.circular(radius ?? 12),
                    bottomRight: Radius.circular(radius ?? 12),
                  ),
            image: DecorationImage(
              image: imageProvider,
              fit: fit ?? BoxFit.cover,
            ),
          ),
        ),
        imageUrl: imageUrl,
        width: width,
        height: height,
        progressIndicatorBuilder: (context, url, downloadProgress) {
          return MainShimmerWidget(
            child: Container(
              height: height,
              width: width,
              decoration: BoxDecoration(
                shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isCircular
                    ? null
                    : BorderRadius.only(
                        topLeft: Radius.circular(radius ?? 12),
                        topRight: Radius.circular(radius ?? 12),
                        bottomLeft: Radius.circular(radius ?? 12),
                        bottomRight: Radius.circular(radius ?? 12),
                      ),
              ),
            ),
          );
        },
        errorWidget: (context, url, error) {
          return Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isCircular
                  ? null
                  : BorderRadius.only(
                      topLeft: Radius.circular(radius ?? 12),
                      topRight: Radius.circular(radius ?? 12),
                      bottomLeft: Radius.circular(radius ?? 12),
                      bottomRight: Radius.circular(radius ?? 12),
                    ),
            ),
            child: Assets.images.logo.image()/* const Icon(
              Icons.error,
              color: ColorsManager.primary1000,
            ), */
          );
        },
      ),
    );
  }
}
