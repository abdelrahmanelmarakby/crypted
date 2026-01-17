import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypted_app/app/modules/media_gallery/controllers/media_gallery_controller.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// Media Gallery View - displays photos, videos, files, links, and audio
class MediaGalleryView extends GetView<MediaGalleryController> {
  const MediaGalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Tab Bar
          _buildTabBar(),

          // Tab Content
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.errorMessage?.value?.isNotEmpty ?? false) {
                return _buildErrorState();
              }

              return TabBarView(
                controller: controller.tabController,
                children: MediaType.values.map((type) {
                  return _buildMediaGrid(type);
                }).toList(),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() {
        if (!controller.isSelectionMode.value) return const SizedBox.shrink();
        return _buildSelectionActions();
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Get.back(),
      ),
      title: Obx(() {
        if (controller.isSelectionMode.value) {
          return Text('${controller.selectedIds.length} selected');
        }
        return Text(controller.roomName ?? 'Media');
      }),
      actions: [
        Obx(() {
          if (controller.isSelectionMode.value) {
            return IconButton(
              icon: const Icon(Icons.close),
              onPressed: controller.toggleSelectionMode,
            );
          }
          return IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
              Get.snackbar('Info', 'Search coming soon');
            },
          );
        }),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: controller.tabController,
        isScrollable: true,
        labelColor: ColorsManager.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: ColorsManager.primary,
        tabs: MediaType.values.map((type) {
          return Obx(() {
            final count = controller.getCountForType(type);
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getIconForType(type), size: 18),
                  const SizedBox(width: 4),
                  Text(_getLabelForType(type)),
                  if (count > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: ColorsManager.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: ColorsManager.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          });
        }).toList(),
      ),
    );
  }

  Widget _buildMediaGrid(MediaType type) {
    return Obx(() {
      final items = controller.getMediaForType(type);

      if (items.isEmpty) {
        return _buildEmptyState(type);
      }

      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: type == MediaType.links || type == MediaType.files
            ? _buildListView(items, type)
            : _buildGridView(items, type),
      );
    });
  }

  Widget _buildGridView(List<MessageModel> items, MediaType type) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: type == MediaType.audio ? 2 : 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: type == MediaType.audio ? 1.5 : 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildGridItem(item, type, index);
      },
    );
  }

  Widget _buildListView(List<MessageModel> items, MediaType type) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildListItem(item, type, index);
      },
    );
  }

  Widget _buildGridItem(MessageModel item, MediaType type, int index) {
    final isSelected = controller.isSelected(item.messageId ?? '');

    return GestureDetector(
      onTap: () {
        if (controller.isSelectionMode.value) {
          controller.toggleSelection(item.messageId ?? '');
        } else {
          controller.openMediaViewer(item, index);
        }
      },
      onLongPress: () {
        if (!controller.isSelectionMode.value) {
          controller.isSelectionMode.value = true;
        }
        controller.toggleSelection(item.messageId ?? '');
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Media thumbnail
          if (type == MediaType.photos || type == MediaType.videos)
            _buildImageThumbnail(item, type),
          if (type == MediaType.audio)
            _buildAudioThumbnail(item),

          // Selection overlay
          if (isSelected)
            Container(
              color: ColorsManager.primary.withValues(alpha: 0.3),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 32,
              ),
            ),

          // Video indicator
          if (type == MediaType.videos)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(MessageModel item, MediaType type) {
    final imageUrl = item.photoUrl ?? item.videoUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: Icon(
          type == MediaType.photos ? Icons.image : Icons.videocam,
          color: Colors.grey,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.error, color: Colors.grey),
      ),
    );
  }

  Widget _buildAudioThumbnail(MessageModel item) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.audiotrack,
            color: ColorsManager.primary,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            item.audioDuration ?? '0:00',
            style: TextStyle(
              fontSize: 12,
              color: ColorsManager.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(MessageModel item, MediaType type, int index) {
    final isSelected = controller.isSelected(item.messageId ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildListItemIcon(item, type),
        title: Text(
          _getItemTitle(item, type),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _getItemSubtitle(item, type),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: controller.isSelectionMode.value
            ? Checkbox(
                value: isSelected,
                onChanged: (_) =>
                    controller.toggleSelection(item.messageId ?? ''),
                activeColor: ColorsManager.primary,
              )
            : IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showItemOptions(item, type),
              ),
        onTap: () {
          if (controller.isSelectionMode.value) {
            controller.toggleSelection(item.messageId ?? '');
          } else {
            _openItem(item, type);
          }
        },
        onLongPress: () {
          if (!controller.isSelectionMode.value) {
            controller.isSelectionMode.value = true;
          }
          controller.toggleSelection(item.messageId ?? '');
        },
        selected: isSelected,
        selectedTileColor: ColorsManager.primary.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildListItemIcon(MessageModel item, MediaType type) {
    IconData icon;
    Color color;

    switch (type) {
      case MediaType.files:
        icon = _getFileIcon(item.fileName);
        color = _getFileColor(item.fileName);
        break;
      case MediaType.links:
        icon = Icons.link;
        color = Colors.blue;
        break;
      default:
        icon = Icons.file_present;
        color = Colors.grey;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }

  String _getItemTitle(MessageModel item, MediaType type) {
    if (type == MediaType.files) {
      return item.fileName ?? 'Unknown file';
    }
    if (type == MediaType.links) {
      final links = controller.extractLinks(item.text);
      return links.isNotEmpty ? links.first : 'Link';
    }
    return 'Item';
  }

  String _getItemSubtitle(MessageModel item, MediaType type) {
    if (type == MediaType.files) {
      return item.fileSize ?? 'Unknown size';
    }
    if (type == MediaType.links) {
      return item.text ?? '';
    }
    return '';
  }

  IconData _getFileIcon(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file;
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String? fileName) {
    if (fileName == null) return Colors.grey;
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'zip':
      case 'rar':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  void _showItemOptions(MessageModel item, MediaType type) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download'),
              onTap: () {
                Get.back();
                controller.downloadMedia(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Get.back();
                Get.snackbar('Info', 'Share coming soon');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Get.back();
                controller.toggleSelection(item.messageId ?? '');
                await controller.deleteSelected();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openItem(MessageModel item, MediaType type) {
    if (type == MediaType.links) {
      // Open link in browser
      Get.snackbar('Info', 'Opening link...');
    } else {
      // Open in viewer
      controller.openMediaViewer(item, 0);
    }
  }

  Widget _buildEmptyState(MediaType type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForType(type),
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_getLabelForType(type).toLowerCase()} yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Obx(() => Text(
                controller.errorMessage?.value ?? 'An error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              )),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton.icon(
              onPressed: controller.shareSelected,
              icon: const Icon(Icons.share),
              label: const Text('Share'),
            ),
            TextButton.icon(
              onPressed: controller.selectAll,
              icon: const Icon(Icons.select_all),
              label: const Text('Select All'),
            ),
            TextButton.icon(
              onPressed: controller.deleteSelected,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(MediaType type) {
    switch (type) {
      case MediaType.photos:
        return Icons.photo;
      case MediaType.videos:
        return Icons.videocam;
      case MediaType.files:
        return Icons.insert_drive_file;
      case MediaType.links:
        return Icons.link;
      case MediaType.audio:
        return Icons.audiotrack;
    }
  }

  String _getLabelForType(MediaType type) {
    switch (type) {
      case MediaType.photos:
        return 'Photos';
      case MediaType.videos:
        return 'Videos';
      case MediaType.files:
        return 'Files';
      case MediaType.links:
        return 'Links';
      case MediaType.audio:
        return 'Audio';
    }
  }
}
