import 'package:crypted_app/app/data/models/messages/location_message_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LocationMessageWidget extends StatelessWidget {
  const LocationMessageWidget({super.key, required this.message});

  final LocationMessage message;

  // Generate static map image URL (Google Maps Static API)
  String get _staticMapUrl {
    final lat = message.latitude;
    final lng = message.longitude;
    const zoom = 15;
    const size = '400x200';
    const apiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // Replace with your API key or use alternative

    // Using OpenStreetMap static map as fallback (free, no API key needed)
    return 'https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lng&zoom=$zoom&size=$size&markers=$lat,$lng,red';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
          minWidth: 260,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorsManager.primary.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map Preview
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  // Static Map Image
                  CachedNetworkImage(
                    imageUrl: _staticMapUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 160,
                      color: ColorsManager.navbarColor,
                      child: Center(
                        child: Icon(
                          Iconsax.map_1_copy,
                          size: 60,
                          color: ColorsManager.grey.withOpacity(0.3),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ColorsManager.primary.withOpacity(0.1),
                            ColorsManager.primary.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.map_1_copy,
                              size: 48,
                              color: ColorsManager.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Map Preview',
                              style: StylesManager.medium(
                                fontSize: FontSize.small,
                                color: ColorsManager.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Location Pin Overlay
                  Positioned(
                    top: 60,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Icon(
                        Iconsax.location_copy,
                        size: 40,
                        color: ColorsManager.error,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Location Details
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColorsManager.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Iconsax.location_copy,
                          color: ColorsManager.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Shared Location',
                          style: StylesManager.semiBold(
                            fontSize: FontSize.medium,
                            color: ColorsManager.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Coordinates
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorsManager.navbarColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.gps_copy,
                          size: 16,
                          color: ColorsManager.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${message.latitude.toStringAsFixed(6)}, ${message.longitude.toStringAsFixed(6)}',
                            style: StylesManager.regular(
                              fontSize: FontSize.xSmall,
                              color: ColorsManager.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Open in Maps Button
                  InkWell(
                    onTap: () async {
                      final url = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${message.latitude},${message.longitude}',
                      );

                      try {
                        final launched = await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );

                        if (!launched) {
                          throw 'Launch failed';
                        }
                      } catch (_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Unable to open map')),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: ColorsManager.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.map_copy,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Open in Maps',
                            style: StylesManager.semiBold(
                              fontSize: FontSize.small,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Iconsax.arrow_right_3_copy,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
