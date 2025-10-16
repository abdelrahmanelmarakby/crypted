import 'package:crypted_app/app/data/models/messages/image_message_model.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';

class ImageMessageWidget extends StatelessWidget {
  const ImageMessageWidget({super.key, required this.message});

  final PhotoMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Sizes.size200,
      height: Sizes.size100,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Radiuss.normal),
      ),
      child: Center(
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => Dialog(
                backgroundColor: Colors.transparent,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: InteractiveViewer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Radiuss.normal),
                      child: Image.network(
                        message.imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radiuss.normal),
            child: Image.network(
              message.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
