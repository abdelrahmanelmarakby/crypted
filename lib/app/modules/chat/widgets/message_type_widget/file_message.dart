import 'package:crypted_app/app/data/models/messages/file_message_model.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class FileMessageWidget extends StatelessWidget {
  const FileMessageWidget({
    super.key,
    required this.message,
  });

  final FileMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Sizes.size200,
      height: Sizes.size70,
      decoration: BoxDecoration(
        color: ColorsManager.veryLightGrey,
        borderRadius: BorderRadius.circular(Radiuss.normal),
      ),
      child: InkWell(
        onTap: () async {
          if (message.file.isNotEmpty) {
            // فتح الرابط في المتصفح
            await launchUrl(Uri.parse(message.file));
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_drive_file,
                color: ColorsManager.primary, size: Sizes.size32),
            const SizedBox(width: Sizes.size12),
            Expanded(
              child: Text(
                message.fileName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ColorsManager.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: Sizes.size8),
            Icon(Icons.download_rounded,
                color: ColorsManager.primary, size: 28),
          ],
        ),
      ),
    );
  }
}
