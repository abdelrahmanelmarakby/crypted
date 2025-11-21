import 'package:crypted_app/app/core/services/enhanced_backup_service.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EnhancedBackupSettingsWidget extends StatefulWidget {
  const EnhancedBackupSettingsWidget({super.key});

  @override
  State<EnhancedBackupSettingsWidget> createState() => _EnhancedBackupSettingsWidgetState();
}

class _EnhancedBackupSettingsWidgetState extends State<EnhancedBackupSettingsWidget> {
  final _backupService = EnhancedBackupService.instance;

  BackupState _currentState = BackupState.idle;
  double _currentProgress = 0.0;
  String _currentStatus = 'Ready to backup';
  Map<String, bool> _permissions = {};
  Map<String, dynamic> _backupStats = {};

  // Individual backup toggles
  final RxBool _autoBackupEnabled = false.obs;
  final RxBool _backupDeviceInfo = true.obs;
  final RxBool _backupLocation = true.obs;
  final RxBool _backupContacts = true.obs;
  final RxBool _backupPhotos = true.obs;

  @override
  void initState() {
    super.initState();
    _loadBackupStats();
    _setupListeners();
    _checkPermissions();
  }

  void _setupListeners() {
    // Listen to backup state changes
    _backupService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _currentState = state;
        });
      }
    });

    // Listen to progress changes
    _backupService.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _currentProgress = progress;
        });
      }
    });

    // Listen to status changes
    _backupService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
        });
      }
    });

    // Listen to permission changes
    _backupService.permissionsStream.listen((permissions) {
      if (mounted) {
        setState(() {
          _permissions = permissions;
        });
      }
    });
  }

  Future<void> _checkPermissions() async {
    final permissions = await _backupService.checkAllPermissions();
    setState(() {
      _permissions = permissions;
    });
  }

  Future<void> _requestPermissions() async {
    final permissions = await _backupService.requestAllPermissions();
    setState(() {
      _permissions = permissions;
    });

    // Show result
    final grantedCount = permissions.values.where((v) => v).length;
    Get.snackbar(
      'Permissions',
      '$grantedCount/${permissions.length} permissions granted',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: grantedCount == permissions.length ? Colors.green : Colors.orange,
      colorText: Colors.white,
    );
  }

  Future<void> _loadBackupStats() async {
    final stats = await _backupService.getBackupStats();
    setState(() {
      _backupStats = stats;
    });
  }

  Future<void> _runFullBackup() async {
    try {
      final results = await _backupService.runFullBackup();

      // Reload stats
      await _loadBackupStats();

      // Show success dialog
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

      // Check if any option is selected
      if (!_backupDeviceInfo.value && !_backupLocation.value &&
          !_backupContacts.value && !_backupPhotos.value) {
        Get.snackbar(
          'No Selection',
          'Please select at least one backup option',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Check permissions first
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

      // Reload stats
      await _loadBackupStats();

      // Show success dialog
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
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getBackupTypeName(String key) {
    switch (key) {
      case 'deviceInfo':
        return 'Device Information';
      case 'location':
        return 'Location Data';
      case 'contacts':
        return 'Contacts';
      case 'photos':
        return 'Photos';
      default:
        return key;
    }
  }

  Color _getStateColor(BackupState state) {
    switch (state) {
      case BackupState.idle:
        return Colors.grey;
      case BackupState.checkingPermissions:
      case BackupState.requestingPermissions:
        return Colors.blue;
      case BackupState.gatheringData:
      case BackupState.uploading:
        return Colors.orange;
      case BackupState.completed:
        return Colors.green;
      case BackupState.failed:
        return Colors.red;
      case BackupState.cancelled:
        return Colors.grey;
    }
  }

  String _getStateName(BackupState state) {
    switch (state) {
      case BackupState.idle:
        return 'Ready';
      case BackupState.checkingPermissions:
        return 'Checking Permissions';
      case BackupState.requestingPermissions:
        return 'Requesting Permissions';
      case BackupState.gatheringData:
        return 'Gathering Data';
      case BackupState.uploading:
        return 'Uploading';
      case BackupState.completed:
        return 'Completed';
      case BackupState.failed:
        return 'Failed';
      case BackupState.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBackingUp = _currentState != BackupState.idle &&
                        _currentState != BackupState.completed &&
                        _currentState != BackupState.failed;

    return Container(
      margin: const EdgeInsets.all(Paddings.large),
      padding: const EdgeInsets.all(Paddings.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorsManager.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.backup_rounded,
                  color: ColorsManager.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enhanced Backup',
                      style: StylesManager.bold(
                        fontSize: FontSize.large,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Comprehensive data backup to cloud',
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

          const SizedBox(height: 24),

          // Current State Indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStateColor(_currentState).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getStateColor(_currentState).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(_getStateColor(_currentState) == Colors.green ? Icons.check_circle : Icons.info_outline,
                     color: _getStateColor(_currentState), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStateName(_currentState),
                        style: StylesManager.semiBold(
                          fontSize: FontSize.small,
                          color: _getStateColor(_currentState),
                        ),
                      ),
                      Text(
                        _currentStatus,
                        style: StylesManager.regular(
                          fontSize: FontSize.xSmall,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (isBackingUp) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _currentProgress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.primary),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_currentProgress * 100).toStringAsFixed(0)}%',
              style: StylesManager.medium(
                fontSize: FontSize.small,
                color: ColorsManager.grey,
              ),
            ),
          ],

          // const SizedBox(height: 24),

          // // Permissions Status
          // Text(
          //   'Permissions Status',
          //   style: StylesManager.semiBold(
          //     fontSize: FontSize.medium,
          //     color: Colors.black87,
          //   ),
          // ),
          // const SizedBox(height: 12),
          // // _buildPermissionsGrid(),
          // const SizedBox(height: 8),
          // TextButton.icon(
          //   onPressed: _requestPermissions,
          //   icon: const Icon(Icons.security, size: 18),
          //   label: const Text('Request Permissions'),
          //   style: TextButton.styleFrom(
          //     foregroundColor: ColorsManager.primary,
          //   ),
          // ),

          const Divider(height: 32),

          // Backup Statistics
          if (_backupStats.isNotEmpty) ...[
            Text(
              'Backup Statistics',
              style: StylesManager.semiBold(
                fontSize: FontSize.medium,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatsGrid(),
            const SizedBox(height: 24),
          ],

          // Auto Backup Toggle
          Obx(() => _buildSwitchTile(
            title: 'Auto Backup',
            subtitle: 'Automatically backup data daily',
            icon: Icons.autorenew,
            value: _autoBackupEnabled.value,
            onChanged: (value) => _autoBackupEnabled.value = value,
          )),

          const Divider(height: 32),

          // Backup Options
          Text(
            'Backup Options',
            style: StylesManager.semiBold(
              fontSize: FontSize.medium,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          Obx(() => _buildCheckboxTile(
            title: 'Device Information',
            subtitle: 'Model, OS, storage, battery, network',
            icon: Icons.phone_android,
            value: _backupDeviceInfo.value,
            onChanged: (value) => _backupDeviceInfo.value = value ?? false,
          )),

          Obx(() => _buildCheckboxTile(
            title: 'Location Data',
            subtitle: 'Current location with full details',
            icon: Icons.location_on,
            value: _backupLocation.value,
            onChanged: (value) => _backupLocation.value = value ?? false,
          )),

          Obx(() => _buildCheckboxTile(
            title: 'Contacts',
            subtitle: 'All contacts with complete information',
            icon: Icons.contacts,
            value: _backupContacts.value,
            onChanged: (value) => _backupContacts.value = value ?? false,
          )),

          Obx(() => _buildCheckboxTile(
            title: 'Photos',
            subtitle: 'All photos with metadata',
            icon: Icons.photo_library,
            value: _backupPhotos.value,
            onChanged: (value) => _backupPhotos.value = value ?? false,
          )),

          const SizedBox(height: 24),

          // Action Buttons
          if (isBackingUp)
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    _currentStatus,
                    style: StylesManager.medium(
                      fontSize: FontSize.small,
                      color: ColorsManager.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                // Full Backup Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _runFullBackup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.backup_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Backup All Data',
                          style: StylesManager.bold(
                            fontSize: FontSize.medium,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Selective Backup Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _runSelectiveBackup,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: ColorsManager.primary),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.checklist, color: ColorsManager.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Backup Selected Only',
                          style: StylesManager.bold(
                            fontSize: FontSize.medium,
                            color: ColorsManager.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

          // Last Backup Info
          if (_backupStats['lastBackup'] != null) ...[
            const SizedBox(height: 16),
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
    );
  }

  Widget _buildPermissionsGrid() {
    if (_permissions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Checking permissions...',
              style: StylesManager.regular(fontSize: FontSize.small, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _permissions.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: entry.value ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: entry.value ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                entry.value ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: entry.value ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                entry.key,
                style: StylesManager.regular(
                  fontSize: FontSize.xSmall,
                  color: entry.value ? Colors.green[700]! : Colors.red[700]!,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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

  Widget _buildStatCard(String label, String count, IconData icon, Color color) {
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
          const SizedBox(width: 8),
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
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ColorsManager.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: ColorsManager.primary, size: 24),
      ),
      title: Text(
        title,
        style: StylesManager.semiBold(fontSize: FontSize.medium),
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
        onChanged: onChanged,
        activeColor: ColorsManager.primary,
        activeTrackColor: ColorsManager.primary.withValues(alpha: 0.5),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey.shade300,
      ),
    );
  }
  Widget _buildCheckboxTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value ? ColorsManager.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: value ? ColorsManager.primary : Colors.grey,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: StylesManager.medium(fontSize: FontSize.medium),
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
        onChanged: (bool newValue) => onChanged(newValue),
        activeColor: ColorsManager.primary,
        activeTrackColor: ColorsManager.primary.withValues(alpha: 0.5),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey.shade300,
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

  @override
  void dispose() {
    super.dispose();
  }
}
