// ignore_for_file: library_private_types_in_public_api

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:crypted/core/constants/theme/colors_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

/// this widget is used for viewing the image in full size
class PhotoGalleryView extends StatefulWidget {
  final XFile photo;

  const PhotoGalleryView({
    super.key,
    required this.photo,
  });
  @override
  _PhotoGalleryViewState createState() => _PhotoGalleryViewState();
}

class _PhotoGalleryViewState extends State<PhotoGalleryView> {
  late ImageProvider imageProvider;
  @override
  void initState() {
    super.initState();

    /// check if url is provided or a path to a file
    bool validURL = Uri.parse(widget.photo.path).isAbsolute;

    validURL
        ? imageProvider = NetworkImage(widget.photo.path)
        : imageProvider = FileImage(File(widget.photo.path));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Stack(
        children: [
          PhotoView(
            heroAttributes: const PhotoViewHeroAttributes(
              tag: 'photo_gallery_hero',
            ),
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: SvgPicture.asset('assets/images/image_error.svg'),
              );
            },
            loadingBuilder: (context, event) => Center(
              child: SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                ),
              ),
            ),
            imageProvider: imageProvider,
          ),
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).padding.top + 16,
                horizontal: size.width / 18,
              ),
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(
                  Icons.close,
                  color: ColorsManager.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}