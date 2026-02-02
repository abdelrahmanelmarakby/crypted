import 'package:crypted_app/app/core/services/enhanced_backup_service.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BackupConfigurationBottomSheet extends StatefulWidget {
  const BackupConfigurationBottomSheet({super.key});

  @override
  State<BackupConfigurationBottomSheet> createState() =>
      _BackupConfigurationBottomSheetState();
}

class _BackupConfigurationBottomSheetState
    extends State<BackupConfigurationBottomSheet> {
  final _backupService = EnhancedBackupService.instance;

  BackupState _currentState = BackupState.idle;
  double _currentProgress = 0.0;
  String _currentStatus = 'Ready to backup';
  Map<String, bool> _permissions = {};
  Map<String, dynamic> _backupStats = {};

  // Individual backup toggles
  final RxBool _backupDeviceInfo = true.obs;
  final RxBool _backupLocation = true.obs;
  final RxBool _backupContacts = true.obs;
  final RxBool _backupPhotos = true.obs;
  final RxBool _backupChats = true.obs;

  // Backup frequency
  final RxString _backupFrequency = 'daily'.obs;

  @override
  void initState() {
    super.initState();
    _loadBackupStats();
    _setupListeners();
    _checkPermissions();
  }

  void _setupListeners() {
    _backupService.stateStream.listen((state) {
      if (mounted) setState(() => _currentState = state);
    });

    _backupService.progressStream.listen((progress) {
      if (mounted) setState(() => _currentProgress = progress);
    });

    _backupService.statusStream.listen((status) {
      if (mounted) setState(() => _currentStatus = status);
    });

    _backupService.permissionsStream.listen((permissions) {
      if (mounted) setState(() => _permissions = permissions);
    });
  }

  Future<void> _checkPermissions() async {
    final permissions = await _backupService.checkAllPermissions();
    setState(() => _permissions = permissions);
  }

  Future<void> _requestPermissions() async {
    final permissions = await _backupService.requestAllPermissions();
    setState(() => _permissions = permissions);

    final grantedCount = permissions.values.where((v) => v).length;
    Get.snackbar(
      'Permissions',
      '$grantedCount/${permissions.length} permissions granted',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor:
          grantedCount == permissions.length ? Colors.green : Colors.orange,
      colorText: Colors.white,
    );
  }

  Future<void> _loadBackupStats() async {
    final stats = await _backupService.getBackupStats();
    setState(() => _backupStats = stats);
  }

  Future<void> _runFullBackup() async {
    try {
      final results = await _backupService.runFullBackup();
      await _loadBackupStats();
      _showBackupResultDialog(results);
    } catch (e) {
      Get.snackbar(
        'Backup Failed',
        'An error occurred during backup: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _runSelectiveBackup() async {
    try {
      final results = <String, bool>{};

      if (!_backupDeviceInfo.value &&
          !_backupLocation.value &&
          !_backupContacts.value &&
          !_backupPhotos.value &&
          !_backupChats.value) {
        Get.snackbar(
          'No Selection',
          'Please select at least one backup option',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      await _backupService.checkAllPermissions();

      if (_backupDeviceInfo.value) {
        results['deviceInfo'] = await _backupService.backupDeviceInfo();
      }
      if (_backupLocation.value) {
        results['location'] = await _backupService.backupLocation();
      }
      if (_backupContacts.value) {
        results['contacts'] = await _backupService.backupContacts();
      }
      if (_backupPhotos.value) {
        results['photos'] = await _backupService.backupPhotos();
      }

      await _loadBackupStats();
      _showBackupResultDialog(results);
    } catch (e) {
      Get.snackbar(
        'Backup Failed',
        'An error occurred during backup: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showBackupResultDialog(Map<String, bool> results) {
    final successCount = results.values.where((v) => v).length;
    final totalCount = results.length;

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              successCount == totalCount ? Icons.check_circle : Icons.warning,
              color: successCount == totalCount ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('Backup Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$successCount of $totalCount backups completed successfully',
              style: StylesManager.medium(fontSize: FontSize.medium),
            ),
            const SizedBox(height: 16),
            ...results.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      entry.value ? Icons.check_circle : Icons.error,
                      color: entry.value ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getBackupTypeName(entry.key),
                      style: StylesManager.regular(fontSize: FontSize.small),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(Constants.kOK.tr),
          ),
        ],
      ),
    );
  }

  String _getBackupTypeName(String key) {
    switch (key) {
      case 'deviceInfo':
        return Constants.kDeviceInfoBackup.tr;
      case 'location':
        return 'Location Data';
      case 'contacts':
        return Constants.kContactsBackup.tr;
      case 'photos':
        return Constants.kImagesBackup.tr;
      case 'chats':
        return 'Chat Messages';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBackingUp = _currentState != BackupState.idle &&
        _currentState != BackupState.completed &&
        _currentState != BackupState.failed;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Radiuss.large),
          topRight: Radius.circular(Radiuss.large),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(Paddings.large),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: ColorsManager.borderColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ColorsManager.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.settings_backup_restore,
                        color: ColorsManager.primary,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: Sizes.size12),
                    Text(
                      Constants.kBackupSettings.tr,
                      style: StylesManager.semiBold(
                        fontSize: FontSize.large,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  tooltip: 'Close',
                  icon: Icon(Icons.close, color: ColorsManager.grey),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Paddings.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Status
                  if (isBackingUp) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ColorsManager.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  value: _currentProgress,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      ColorsManager.primary),
                                ),
                              ),
                              SizedBox(width: Sizes.size12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Constants.kBackupInProgress.tr,
                                      style: StylesManager.semiBold(
                                        fontSize: FontSize.medium,
                                        color: ColorsManager.primary,
                                      ),
                                    ),
                                    Text(
                                      _currentStatus,
                                      style: StylesManager.regular(
                                        fontSize: FontSize.small,
                                        color: ColorsManager.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${(_currentProgress * 100).toStringAsFixed(0)}%',
                                style: StylesManager.bold(
                                  fontSize: FontSize.medium,
                                  color: ColorsManager.primary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: Sizes.size12),
                          LinearProgressIndicator(
                            value: _currentProgress,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                ColorsManager.primary),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: Sizes.size24),
                  ],

                  // Backup Frequency
                  Text(
                    'Backup Frequency',
                    style: StylesManager.semiBold(
                      fontSize: FontSize.medium,
                    ),
                  ),
                  SizedBox(height: Sizes.size12),
                  Obx(() => Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: ColorsManager.borderColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildFrequencyOption('Daily', 'daily'),
                            Divider(height: 1),
                            _buildFrequencyOption('Weekly', 'weekly'),
                            Divider(height: 1),
                            _buildFrequencyOption('Monthly', 'monthly'),
                            Divider(height: 1),
                            _buildFrequencyOption('Manual Only', 'manual'),
                          ],
                        ),
                      )),

                  SizedBox(height: Sizes.size24),

                  // Backup Data Types
                  Text(
                    'What to Backup',
                    style: StylesManager.semiBold(
                      fontSize: FontSize.medium,
                    ),
                  ),
                  SizedBox(height: Sizes.size12),

                  Obx(() => _buildBackupOption(
                        title: 'Device Information',
                        subtitle: 'Model, OS version, storage, battery info',
                        icon: Icons.phone_android,
                        value: _backupDeviceInfo.value,
                        onChanged: (value) =>
                            _backupDeviceInfo.value = value ?? false,
                      )),

                  Obx(() => _buildBackupOption(
                        title: 'Location Data',
                        subtitle: 'Current location with full details',
                        icon: Icons.location_on,
                        value: _backupLocation.value,
                        onChanged: (value) =>
                            _backupLocation.value = value ?? false,
                        requiresPermission: true,
                        hasPermission: _permissions['location'] ?? false,
                      )),

                  Obx(() => _buildBackupOption(
                        title: 'Contacts',
                        subtitle: 'All contacts with complete information',
                        icon: Icons.contacts,
                        value: _backupContacts.value,
                        onChanged: (value) =>
                            _backupContacts.value = value ?? false,
                        requiresPermission: true,
                        hasPermission: _permissions['contacts'] ?? false,
                      )),

                  Obx(() => _buildBackupOption(
                        title: 'Photos & Media',
                        subtitle: 'All photos with metadata',
                        icon: Icons.photo_library,
                        value: _backupPhotos.value,
                        onChanged: (value) =>
                            _backupPhotos.value = value ?? false,
                        requiresPermission: true,
                        hasPermission: _permissions['photos'] ?? false,
                      )),

                  Obx(() => _buildBackupOption(
                        title: 'Chat Messages',
                        subtitle: 'All conversations and message history',
                        icon: Icons.chat_bubble,
                        value: _backupChats.value,
                        onChanged: (value) =>
                            _backupChats.value = value ?? false,
                      )),

                  SizedBox(height: Sizes.size24),

                  // Backup Statistics
                  if (_backupStats.isNotEmpty) ...[
                    Text(
                      'Backup Statistics',
                      style: StylesManager.semiBold(
                        fontSize: FontSize.medium,
                      ),
                    ),
                    SizedBox(height: Sizes.size12),
                    _buildStatsGrid(),
                    SizedBox(height: Sizes.size24),
                  ],

                  // Permissions Section
                  if (_permissions.values.any((granted) => !granted)) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber,
                                  color: Colors.orange, size: 20),
                              SizedBox(width: Sizes.size8),
                              Text(
                                'Permissions Required',
                                style: StylesManager.semiBold(
                                  fontSize: FontSize.small,
                                  color: Colors.orange[800]!,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: Sizes.size8),
                          Text(
                            'Some features require additional permissions. Grant them to enable full backup functionality.',
                            style: StylesManager.regular(
                              fontSize: FontSize.xSmall,
                              color: ColorsManager.grey,
                            ),
                          ),
                          SizedBox(height: Sizes.size12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _requestPermissions,
                              icon: Icon(Icons.security, size: 18),
                              label: Text('Grant Permissions'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                                side: BorderSide(color: Colors.orange),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: Sizes.size24),
                  ],

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isBackingUp ? null : _runFullBackup,
                      icon: Icon(Icons.backup_rounded),
                      label: Text('Backup All Data Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManager.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: Sizes.size12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isBackingUp ? null : _runSelectiveBackup,
                      icon: Icon(Icons.checklist),
                      label: Text('Backup Selected Only'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorsManager.primary,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: ColorsManager.primary),
                      ),
                    ),
                  ),

                  if (_backupStats['lastBackup'] != null) ...[
                    SizedBox(height: Sizes.size16),
                    Center(
                      child: Text(
                        'Last backup: ${_formatDateTime(_backupStats['lastBackup'])}',
                        style: StylesManager.regular(
                          fontSize: FontSize.xSmall,
                          color: ColorsManager.grey,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyOption(String label, String value) {
    final isSelected = _backupFrequency.value == value;
    return ListTile(
      title: Text(
        label,
        style: StylesManager.regular(
          fontSize: FontSize.medium,
          color: isSelected ? ColorsManager.primary : Colors.black87,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: ColorsManager.primary)
          : null,
      onTap: () => _backupFrequency.value = value,
    );
  }

  Widget _buildBackupOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool?) onChanged,
    bool requiresPermission = false,
    bool hasPermission = true,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: Sizes.size12),
      decoration: BoxDecoration(
        border: Border.all(
          color: value
              ? ColorsManager.primary.withValues(alpha: 0.3)
              : ColorsManager.borderColor,
        ),
        borderRadius: BorderRadius.circular(12),
        color: value
            ? ColorsManager.primary.withValues(alpha: 0.05)
            : Colors.white,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value
                ? ColorsManager.primary.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: value ? ColorsManager.primary : Colors.grey,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: StylesManager.medium(fontSize: FontSize.medium),
              ),
            ),
            if (requiresPermission && !hasPermission)
              Icon(Icons.lock, size: 16, color: Colors.orange),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: StylesManager.regular(
            fontSize: FontSize.small,
            color: ColorsManager.grey,
          ),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: (requiresPermission && !hasPermission) ? null : onChanged,
          activeColor: ColorsManager.primary,
          activeTrackColor: ColorsManager.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2,
      children: [
        _buildStatCard(
          'Device Info',
          (_backupStats['deviceInfoBackups'] ?? 0).toString(),
          Icons.phone_android,
          Colors.blue,
        ),
        _buildStatCard(
          'Locations',
          (_backupStats['locationBackups'] ?? 0).toString(),
          Icons.location_on,
          Colors.green,
        ),
        _buildStatCard(
          'Contacts',
          (_backupStats['contactsBackups'] ?? 0).toString(),
          Icons.contacts,
          Colors.orange,
        ),
        _buildStatCard(
          'Photos',
          (_backupStats['photosBackups'] ?? 0).toString(),
          Icons.photo_library,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: Sizes.size8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  count,
                  style: StylesManager.bold(
                    fontSize: FontSize.large,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: StylesManager.regular(
                    fontSize: FontSize.xSmall,
                    color: Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
