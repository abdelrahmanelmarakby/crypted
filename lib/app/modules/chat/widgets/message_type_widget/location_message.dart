import 'package:crypted_app/app/data/models/messages/location_message_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationMessageWidget extends StatelessWidget {
  const LocationMessageWidget({super.key, required this.message});

  final LocationMessage message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: Sizes.size200,
        height: Sizes.size150,
        decoration: BoxDecoration(
          color: ColorsManager.veryLightGrey,
          borderRadius: BorderRadius.circular(Radiuss.normal),
        ),
        child: InkWell(
          onTap: () async {
            final url = Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=${message.latitude},${message.longitude}');

            try {
              final launched = await launchUrl(
                url,
                mode: LaunchMode
                    .externalApplication, // يجبر Android يفتح في المتصفح
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                size: Sizes.size48,
                color: ColorsManager.primary,
              ),
              const SizedBox(height: Sizes.size8),
              Text(
                "Sender's site",
                style: TextStyle(color: ColorsManager.black),
              ),
              Text(
                '${message.latitude.toStringAsFixed(5)}, ${message.longitude.toStringAsFixed(5)}',
                style: StylesManager.regular(
                    color: ColorsManager.grey, fontSize: 12),
              ),
              const SizedBox(height: Sizes.size8),
              Text(
                'Click to view site',
                style: StylesManager.regular(
                    color: ColorsManager.primary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
