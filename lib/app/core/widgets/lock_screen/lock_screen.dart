import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/core/services/app_lock_service.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/gen/assets.gen.dart';

/// Full-screen lock screen that appears when the app is locked
/// Supports biometric authentication and PIN/password entry
class LockScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;
  final String? message;
  final bool showBiometricOnStart;

  const LockScreen({
    super.key,
    this.onUnlocked,
    this.message,
    this.showBiometricOnStart = true,
  });

  /// Show lock screen as a full-screen overlay
  static Future<bool> show({
    String? message,
    bool showBiometricOnStart = true,
  }) async {
    final result = await Get.to<bool>(
      () => LockScreen(
        message: message,
        showBiometricOnStart: showBiometricOnStart,
      ),
      fullscreenDialog: true,
      transition: Transition.fadeIn,
    );
    return result ?? false;
  }

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  final AppLockService _lockService = AppLockService.instance;
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Attempt biometric authentication on start if enabled
    if (widget.showBiometricOnStart && _lockService.isBiometricEnabled.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticateWithBiometrics();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isAuthenticating) {
      // Re-attempt biometric when app comes back to foreground
      if (_lockService.isBiometricEnabled.value) {
        _authenticateWithBiometrics();
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final authenticated = await _lockService.authenticate(
        reason: 'Authenticate to unlock Crypted',
      );

      if (authenticated) {
        _onUnlocked();
      } else {
        setState(() {
          _errorMessage = 'Authentication failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _onUnlocked() {
    HapticFeedback.mediumImpact();
    widget.onUnlocked?.call();
    Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        backgroundColor: ColorsManager.navbarColor,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // App Logo
              _buildLogo(),

              const SizedBox(height: 32),

              // Title
              Text(
                'Crypted',
                style: StylesManager.bold(
                  fontSize: FontSize.xLarge + 8,
                  color: ColorsManager.black,
                ),
              ),

              const SizedBox(height: 8),

              // Message
              Text(
                widget.message ?? 'Unlock to continue',
                style: StylesManager.regular(
                  fontSize: FontSize.medium,
                  color: ColorsManager.grey,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 1),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(flex: 1),

              // Biometric button
              if (_lockService.isBiometricAvailable.value)
                _buildBiometricButton(),

              const SizedBox(height: 24),

              // Use device credentials text button
              TextButton(
                onPressed: _isAuthenticating ? null : _authenticateWithBiometrics,
                child: Text(
                  'Use device credentials',
                  style: StylesManager.medium(
                    fontSize: FontSize.medium,
                    color: ColorsManager.primary,
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Footer
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'Your messages are protected',
                  style: StylesManager.regular(
                    fontSize: FontSize.small,
                    color: ColorsManager.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: ColorsManager.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.lock_outline,
          size: 48,
          color: ColorsManager.primary,
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return GestureDetector(
      onTap: _isAuthenticating ? null : _authenticateWithBiometrics,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: _isAuthenticating
              ? ColorsManager.primary.withValues(alpha: 0.3)
              : ColorsManager.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: ColorsManager.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _isAuthenticating
              ? const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(
                  _lockService.biometricIcon,
                  size: 36,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}

/// Compact lock indicator for chat list items
class LockedChatIndicator extends StatelessWidget {
  final bool isLocked;
  final bool compact;
  final VoidCallback? onTap;

  const LockedChatIndicator({
    super.key,
    required this.isLocked,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return const SizedBox.shrink();

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: ColorsManager.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.lock,
          color: ColorsManager.primary,
          size: 14,
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: ColorsManager.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              color: ColorsManager.primary,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'Locked',
              style: StylesManager.medium(
                fontSize: FontSize.xSmall,
                color: ColorsManager.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lock screen overlay that can be shown over any screen
class LockScreenOverlay extends StatelessWidget {
  final Widget child;
  final bool isLocked;

  const LockScreenOverlay({
    super.key,
    required this.child,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLocked)
          Positioned.fill(
            child: LockScreen(
              showBiometricOnStart: true,
            ),
          ),
      ],
    );
  }
}
