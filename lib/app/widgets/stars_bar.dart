// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../core/constants/theme/colors_manager.dart';

class StarsBar extends StatelessWidget {
  const StarsBar({
    super.key,
    required this.stars,
    this.color = ColorsManager.star,
  });

  final double stars;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      minRating: 1,
      maxRating: 5.0,
      initialRating: stars,
      itemSize: 20.0,
      allowHalfRating: true,
      ignoreGestures: true,
      direction: Axis.horizontal,
      itemCount: 5,
      unratedColor: ColorsManager.grey,
      itemBuilder: (context, _) => Icon(Icons.star, color: color),
      onRatingUpdate: (rating) {},
    );
  }
}
