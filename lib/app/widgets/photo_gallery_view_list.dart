// ignore_for_file: library_private_types_in_public_api

import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

import '../../core/constants/theme/colors_manager.dart';


/// this widget is used for viewing the image in full size
class PhotoGalleryViewList extends StatefulWidget {
  final List<XFile> photos;
  final int index;

  const PhotoGalleryViewList({
    super.key,
    required this.photos,
    required this.index,
  });

  @override
  _PhotoGalleryViewListState createState() => _PhotoGalleryViewListState();
}

class _PhotoGalleryViewListState extends State<PhotoGalleryViewList> {
  late ImageProvider imageProvider;

  @override
  void initState() {
    super.initState();

    /// check if url is provided or a path to a file
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: CarouselSlider(
        items: widget.photos.map((e) {
          bool validURL = Uri.parse(e.path).isAbsolute;

          validURL
              ? imageProvider = NetworkImage(e.path)
              : imageProvider = FileImage(File(e.path));
          return Stack(
            children: [
              PhotoView(
                heroAttributes: const PhotoViewHeroAttributes(
                  tag: 'photo_gallery_hero',
                ),
                loadingBuilder: (context, event) => Center(
                  child: SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      value: event == null
                          ? 0
                          : event.cumulativeBytesLoaded /
                              event.expectedTotalBytes!,
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
          );
        }).toList(),
        options: CarouselOptions(
          height: MediaQuery.sizeOf(context).height,
          initialPage: widget.index,
          viewportFraction: 1,
        ),
      ),
    );
  }
}