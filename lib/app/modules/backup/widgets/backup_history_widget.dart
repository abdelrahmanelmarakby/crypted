import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import '../controllers/backup_controller.dart';
import 'package:intl/intl.dart';

class BackupHistoryWidget extends GetView<BackupController> {
  const BackupHistoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final history = controller.backupHistory;

      if (history.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'No backup history yet',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your backup history will appear here',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length > 5 ? 5 : history.length, // Limit to 5 items
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),
          itemBuilder: (context, index) {
            final item = history[index];
            return _buildHistoryTile(context, item);
          },
        ),
      );
    });
  }

  Widget _buildHistoryTile(BuildContext context, BackupHistoryItem item) {
    return InkWell(
      onTap: () => _showBackupDetails(context, item),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: item.success
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.red.shade400, Colors.red.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (item.success ? Colors.green : Colors.red).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                item.success ? Icons.backup : Icons.error_outline,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.formattedDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.itemsBackedUp} items backed up',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status Badge & Arrow
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (item.success ? Colors.green : Colors.red).shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.success ? 'Success' : 'Failed',
                    style: TextStyle(
                      color: (item.success ? Colors.green : Colors.red).shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupDetails(BuildContext context, BackupHistoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: item.success
                                      ? [Colors.green.shade400, Colors.green.shade600]
                                      : [Colors.red.shade400, Colors.red.shade600],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                item.success ? Icons.backup : Icons.error,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Backup Details',
                                    style: StylesManager.bold(
                                      fontSize: FontSize.xLarge,
                                      color: ColorsManager.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDetailedDate(item.date),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Stats Cards with clickable actions
                        if (item.stats != null) ...[
                          InkWell(
                            onTap: () => _showContactsDetails(context, item.stats!),
                            child: _buildDetailCard(
                              context,
                              icon: Icons.contacts_outlined,
                              label: 'Contacts',
                              value: '${item.stats!['contacts_count'] ?? 0}',
                              color: Colors.blue,
                              trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.blue),
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => _showImagesGallery(context, item.stats!),
                            child: _buildDetailCard(
                              context,
                              icon: Icons.image_outlined,
                              label: 'Images',
                              value: '${item.stats!['images_count'] ?? 0}',
                              color: Colors.purple,
                              trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.purple),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailCard(
                            context,
                            icon: Icons.video_library_outlined,
                            label: 'Files',
                            value: '${item.stats!['files_count'] ?? 0}',
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 28),

                          // Backup Components Status
                          if (item.stats!['backup_success'] != null) ...[
                            Text(
                              'Backup Components',
                              style: StylesManager.bold(
                                fontSize: FontSize.large,
                                color: ColorsManager.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSuccessCard(context, item.stats!['backup_success']),
                          ],
                        ],

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(35), color.withAlpha(70)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color.withAlpha(200),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color.withAlpha(150),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }

  /// Show contacts details in a modal
  void _showContactsDetails(BuildContext context, Map<String, dynamic> stats) {
    final contacts = stats['contacts'] as List<dynamic>? ?? [];

    if (contacts.isEmpty) {
      Get.snackbar(
        'No Contacts',
        'No contacts found in this backup',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.contacts, color: Colors.blue.shade700, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contacts Backup',
                              style: StylesManager.bold(
                                fontSize: FontSize.xLarge,
                                color: ColorsManager.black,
                              ),
                            ),
                            Text(
                              '${contacts.length} contacts',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: contacts.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) {
                      final contact = contacts[index] as Map<String, dynamic>;
                      final displayName = contact['displayName'] ?? 'Unknown';
                      final phones = contact['phones'] as List<dynamic>? ?? [];
                      final emails = contact['emails'] as List<dynamic>? ?? [];

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (phones.isNotEmpty)
                              ...phones.map((phone) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Text(
                                      phone['number'] ?? '',
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                    ),
                                  ],
                                ),
                              )),
                            if (emails.isNotEmpty)
                              ...emails.map((email) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.email, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Text(
                                      email['address'] ?? '',
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                    ),
                                  ],
                                ),
                              )),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Show images gallery in a modal
  void _showImagesGallery(BuildContext context, Map<String, dynamic> stats) {
    final images = stats['images'] as List<dynamic>? ?? [];

    if (images.isEmpty) {
      Get.snackbar(
        'No Images',
        'No images found in this backup',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.image, color: Colors.purple.shade700, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Images Gallery',
                              style: StylesManager.bold(
                                fontSize: FontSize.xLarge,
                                color: ColorsManager.black,
                              ),
                            ),
                            Text(
                              '${images.length} images',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final image = images[index] as Map<String, dynamic>;
                      final imageUrl = image['url'] as String?;

                      return GestureDetector(
                        onTap: () => _showFullImage(context, imageUrl, image),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade200,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imageUrl != null
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                          strokeWidth: 2,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.error_outline, color: Colors.red);
                                    },
                                  )
                                : const Icon(Icons.image_not_supported, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Show full image viewer
  void _showFullImage(BuildContext context, String? imageUrl, Map<String, dynamic> imageData) {
    if (imageUrl == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(0),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (imageData['width'] != null && imageData['height'] != null)
                      Text(
                        'Size: ${imageData['width']}x${imageData['height']}',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    if (imageData['createDate'] != null)
                      Text(
                        'Date: ${imageData['createDate']}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard(BuildContext context, Map<String, dynamic> success) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: success.entries.map((entry) {
          final isSuccess = entry.value == true;
          final componentName = entry.key
              .replaceAll('_', ' ')
              .split(' ')
              .map((word) => word[0].toUpperCase() + word.substring(1))
              .join(' ');

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: entry.key != success.keys.last
                    ? BorderSide(color: Colors.grey.shade200)
                    : BorderSide.none,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (isSuccess ? Colors.green : Colors.red).shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle : Icons.cancel,
                    color: (isSuccess ? Colors.green : Colors.red).shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    componentName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isSuccess ? Colors.green : Colors.red).shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isSuccess ? 'Success' : 'Failed',
                    style: TextStyle(
                      color: (isSuccess ? Colors.green : Colors.red).shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatDetailedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago at ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, yyyy \'at\' h:mm a').format(date);
    }
  }
}
