import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/privacy_settings_model.dart';
import 'package:crypted_app/app/modules/settings_v2/core/services/privacy_settings_service.dart';

/// Security Audit Log Viewer
/// Displays a timeline of security events for the user's account
class SecurityAuditLogViewer extends StatefulWidget {
  const SecurityAuditLogViewer({super.key});

  /// Show the security audit log as a full-screen view
  static Future<void> show(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SecurityAuditLogViewer(),
      ),
    );
  }

  @override
  State<SecurityAuditLogViewer> createState() => _SecurityAuditLogViewerState();
}

class _SecurityAuditLogViewerState extends State<SecurityAuditLogViewer> {
  late PrivacySettingsService _service;

  // Filter state
  SecurityEventType? _selectedFilter;
  bool _isLoading = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = Get.find<PrivacySettingsService>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SecurityLogEntry> get _filteredLogs {
    var logs = _service.securityLog.toList();

    // Apply event type filter
    if (_selectedFilter != null) {
      logs = logs.where((log) => log.eventType == _selectedFilter).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      logs = logs.where((log) {
        return log.eventType.displayName.toLowerCase().contains(query) ||
            (log.deviceName?.toLowerCase().contains(query) ?? false) ||
            (log.location?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return logs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: Text(
          'Security Activity',
          style: StylesManager.semiBold(fontSize: FontSize.large),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showFilterSheet,
            icon: Badge(
              isLabelVisible: _selectedFilter != null,
              child: Icon(
                Iconsax.filter,
                color: _selectedFilter != null
                    ? ColorsManager.primary
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),

          // Content
          Expanded(
            child: Obx(() {
              if (_service.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final logs = _filteredLogs;

              if (logs.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  await _service.refresh();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length + 1, // +1 for header
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildLogHeader(logs.length);
                    }
                    return _buildLogEntry(logs[index - 1], index - 1);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        decoration: InputDecoration(
          hintText: 'Search activity...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Iconsax.search_normal, color: Colors.grey.shade400),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: Icon(Icons.close, color: Colors.grey.shade400),
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildLogHeader(int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Iconsax.shield_tick,
              color: ColorsManager.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: StylesManager.semiBold(fontSize: FontSize.medium),
                ),
                Text(
                  '$count events • Last 30 days',
                  style: StylesManager.regular(
                    fontSize: FontSize.small,
                    color: ColorsManager.grey,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedFilter != null)
            TextButton.icon(
              onPressed: () {
                setState(() => _selectedFilter = null);
              },
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                foregroundColor: ColorsManager.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(SecurityLogEntry entry, int index) {
    final isFirst = index == 0;
    final isLast = index == _filteredLogs.length - 1;

    return InkWell(
      onTap: () => _showLogDetails(entry),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getEventColor(entry.eventType),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getEventColor(entry.eventType).withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 80,
                    color: Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getEventColor(entry.eventType).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getEventIcon(entry.eventType),
                            color: _getEventColor(entry.eventType),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.eventType.displayName,
                                style: StylesManager.semiBold(fontSize: FontSize.medium),
                              ),
                              Text(
                                _formatTimestamp(entry.timestamp),
                                style: StylesManager.regular(
                                  fontSize: FontSize.small,
                                  color: ColorsManager.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                      ],
                    ),
                    if (entry.deviceName != null || entry.location != null) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      if (entry.deviceName != null)
                        _buildInfoRow(
                          icon: Iconsax.mobile,
                          label: 'Device',
                          value: entry.deviceName!,
                        ),
                      if (entry.location != null)
                        _buildInfoRow(
                          icon: Iconsax.location,
                          label: 'Location',
                          value: entry.location!,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: ColorsManager.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: StylesManager.regular(
              fontSize: FontSize.small,
              color: ColorsManager.grey,
            ),
          ),
          Text(
            value,
            style: StylesManager.medium(fontSize: FontSize.small),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.shield_search,
              size: 56,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedFilter != null || _searchQuery.isNotEmpty
                ? 'No matching events'
                : 'No security events',
            style: StylesManager.semiBold(fontSize: FontSize.large),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter != null || _searchQuery.isNotEmpty
                ? 'Try adjusting your filters'
                : 'Security events will appear here',
            style: StylesManager.regular(
              fontSize: FontSize.medium,
              color: ColorsManager.grey,
            ),
          ),
          if (_selectedFilter != null || _searchQuery.isNotEmpty) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedFilter = null;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'Filter by Event Type',
                    style: StylesManager.bold(fontSize: FontSize.large),
                  ),
                  const Spacer(),
                  if (_selectedFilter != null)
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedFilter = null);
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filter options
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: SecurityEventType.values.map((type) {
                  final isSelected = _selectedFilter == type;
                  return ListTile(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedFilter = type);
                      Navigator.pop(context);
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getEventColor(type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getEventIcon(type),
                        color: _getEventColor(type),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      type.displayName,
                      style: StylesManager.medium(
                        fontSize: FontSize.medium,
                        color: isSelected ? ColorsManager.primary : Colors.black87,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: ColorsManager.primary)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  void _showLogDetails(SecurityLogEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: _getEventColor(entry.eventType).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getEventColor(entry.eventType),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getEventIcon(entry.eventType),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.eventType.displayName,
                          style: StylesManager.bold(fontSize: FontSize.large),
                        ),
                        Text(
                          _formatTimestampFull(entry.timestamp),
                          style: StylesManager.regular(
                            fontSize: FontSize.small,
                            color: ColorsManager.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Details',
                    style: StylesManager.semiBold(
                      fontSize: FontSize.medium,
                      color: ColorsManager.grey,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildDetailRow('Event ID', entry.id),
                  _buildDetailRow('Event Type', entry.eventType.key),
                  _buildDetailRow('Timestamp', _formatTimestampFull(entry.timestamp)),
                  if (entry.deviceName != null)
                    _buildDetailRow('Device', entry.deviceName!),
                  if (entry.location != null)
                    _buildDetailRow('Location', entry.location!),
                  if (entry.ipAddress != null)
                    _buildDetailRow('IP Address', entry.ipAddress!),
                  if (entry.metadata != null && entry.metadata!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Additional Information',
                      style: StylesManager.semiBold(
                        fontSize: FontSize.medium,
                        color: ColorsManager.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...entry.metadata!.entries.map((e) =>
                      _buildDetailRow(e.key, e.value.toString())
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Padding(
              padding: EdgeInsets.fromLTRB(
                24, 0, 24, MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _copyLogDetails(entry);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Iconsax.copy),
                      label: const Text('Copy Details'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: ColorsManager.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManager.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: StylesManager.medium(
                fontSize: FontSize.medium,
                color: ColorsManager.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: StylesManager.medium(fontSize: FontSize.medium),
            ),
          ),
        ],
      ),
    );
  }

  void _copyLogDetails(SecurityLogEntry entry) {
    final buffer = StringBuffer();
    buffer.writeln('Security Event Details');
    buffer.writeln('='.padRight(30, '='));
    buffer.writeln('Event: ${entry.eventType.displayName}');
    buffer.writeln('Event ID: ${entry.id}');
    buffer.writeln('Timestamp: ${_formatTimestampFull(entry.timestamp)}');
    if (entry.deviceName != null) buffer.writeln('Device: ${entry.deviceName}');
    if (entry.location != null) buffer.writeln('Location: ${entry.location}');
    if (entry.ipAddress != null) buffer.writeln('IP Address: ${entry.ipAddress}');
    if (entry.metadata != null && entry.metadata!.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Additional Information:');
      entry.metadata!.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    Get.snackbar(
      'Copied',
      'Event details copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: ColorsManager.primary.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat.Hm().format(timestamp)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat.MMMd().format(timestamp);
    }
  }

  String _formatTimestampFull(DateTime timestamp) {
    return DateFormat('MMMM d, yyyy \'at\' h:mm a').format(timestamp);
  }

  IconData _getEventIcon(SecurityEventType type) {
    switch (type) {
      case SecurityEventType.login:
        return Iconsax.login;
      case SecurityEventType.logout:
        return Iconsax.logout;
      case SecurityEventType.passwordChange:
        return Iconsax.key;
      case SecurityEventType.twoStepEnabled:
        return Iconsax.shield_tick;
      case SecurityEventType.twoStepDisabled:
        return Iconsax.shield_cross;
      case SecurityEventType.deviceAdded:
        return Iconsax.mobile;
      case SecurityEventType.deviceRemoved:
        return Iconsax.trash;
      case SecurityEventType.blockedUser:
        return Iconsax.user_remove;
      case SecurityEventType.unblockedUser:
        return Iconsax.user_tick;
      case SecurityEventType.privacyChanged:
        return Iconsax.security_user;
      case SecurityEventType.appLockChanged:
        return Iconsax.lock;
    }
  }

  Color _getEventColor(SecurityEventType type) {
    switch (type) {
      case SecurityEventType.login:
        return Colors.green;
      case SecurityEventType.logout:
        return Colors.orange;
      case SecurityEventType.passwordChange:
        return Colors.blue;
      case SecurityEventType.twoStepEnabled:
        return Colors.green;
      case SecurityEventType.twoStepDisabled:
        return Colors.orange;
      case SecurityEventType.deviceAdded:
        return Colors.purple;
      case SecurityEventType.deviceRemoved:
        return Colors.red;
      case SecurityEventType.blockedUser:
        return Colors.red;
      case SecurityEventType.unblockedUser:
        return Colors.teal;
      case SecurityEventType.privacyChanged:
        return ColorsManager.primary;
      case SecurityEventType.appLockChanged:
        return Colors.indigo;
    }
  }
}

/// Security Activity Tile for Settings
/// A pre-built tile to show in privacy settings
class SecurityActivityTile extends StatelessWidget {
  final int eventCount;
  final VoidCallback? onTap;

  const SecurityActivityTile({
    super.key,
    required this.eventCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap ?? () => SecurityAuditLogViewer.show(context),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: ColorsManager.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Iconsax.shield_tick,
          color: ColorsManager.primary,
          size: 22,
        ),
      ),
      title: Text(
        'Security Activity',
        style: StylesManager.medium(fontSize: FontSize.medium),
      ),
      subtitle: Text(
        '$eventCount recent events',
        style: StylesManager.regular(
          fontSize: FontSize.small,
          color: ColorsManager.grey,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: ColorsManager.grey,
      ),
    );
  }
}
