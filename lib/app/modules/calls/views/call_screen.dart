import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import 'package:crypted_app/core/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/app/data/data_source/call_data_sources.dart';
import 'package:crypted_app/app/core/services/zego/zego_call_config.dart';

/// Screen for active voice/video calls using ZEGO UIKit.
///
/// This screen displays the ZEGO call UI and manages:
/// - Call initialization and room joining
/// - Call duration tracking
/// - Call status updates in Firestore
/// - Error handling and recovery
class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  // Call data
  CallModel? _callModel;
  String? _callId;

  // State management
  bool _isInitializing = true;
  bool _isCallReady = false;
  String? _errorMessage;

  // Duration tracking
  Timer? _durationTimer;
  int _callDurationSeconds = 0;

  // Data source
  final CallDataSources _callDataSources = CallDataSources();

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _handleCallEnd();
    super.dispose();
  }

  /// Initialize the call from navigation arguments.
  Future<void> _initializeCall() async {
    try {
      // Parse call model from arguments
      _callModel = _parseCallArguments();

      if (_callModel == null) {
        _setError('Invalid call parameters');
        return;
      }

      // Check network connectivity
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none) || connectivityResults.isEmpty) {
        _setError('No internet connection');
        return;
      }

      // Generate or use existing call ID
      _callId = _callModel!.callId ??
          '${_callModel!.callerId}_${_callModel!.calleeId}_${DateTime.now().millisecondsSinceEpoch}';

      log('[CallScreen] Initializing call: $_callId');
      log('[CallScreen] Caller: ${_callModel!.callerId} -> Callee: ${_callModel!.calleeId}');
      log('[CallScreen] Type: ${_callModel!.callType?.name}');

      // Mark call as ready
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _isCallReady = true;
        });
        _startDurationTimer();
      }
    } catch (e, stackTrace) {
      log('[CallScreen] Error initializing call: $e');
      log('[CallScreen] Stack trace: $stackTrace');
      _setError('Failed to initialize call');
    }
  }

  /// Parse call arguments from navigation.
  CallModel? _parseCallArguments() {
    final args = Get.arguments;

    if (args is CallModel) {
      return args;
    }

    if (args is Map<String, dynamic>) {
      return CallModel.fromMap(args);
    }

    if (args is Map) {
      return CallModel.fromMap(Map<String, dynamic>.from(args));
    }

    return null;
  }

  /// Set error state and stop loading.
  void _setError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isInitializing = false;
        _isCallReady = false;
      });
    }
  }

  /// Start tracking call duration.
  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  /// Format duration as MM:SS.
  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  /// Handle call end - update Firestore and cleanup.
  Future<void> _handleCallEnd() async {
    if (_callModel?.callId == null && _callId == null) return;

    final callId = _callModel?.callId ?? _callId;
    if (callId == null) return;

    try {
      if (_callDurationSeconds > 0) {
        await _callDataSources.endCall(callId, _callDurationSeconds);
        log('[CallScreen] Call ended: $callId (${_callDurationSeconds}s)');
      } else {
        await _callDataSources.markCallAsCancelled(callId);
        log('[CallScreen] Call cancelled: $callId');
      }
    } catch (e) {
      log('[CallScreen] Error ending call: $e');
    }
  }

  /// Show end call confirmation dialog.
  Future<bool> _showEndCallConfirmation() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('End Call'),
        content: const Text('Are you sure you want to end this call?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Cancel',
              style: TextStyle(color: ColorsManager.grey),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'End Call',
              style: TextStyle(color: ColorsManager.error),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isInitializing) {
      return _buildLoadingScreen('Initializing call...');
    }

    // Show error state
    if (_errorMessage != null) {
      return _buildErrorScreen(_errorMessage!);
    }

    // Show call not ready state
    if (!_isCallReady || _callModel == null || _callId == null) {
      return _buildLoadingScreen('Starting call...');
    }

    // Show call UI
    return _buildCallScreen();
  }

  /// Build loading screen.
  Widget _buildLoadingScreen(String message) {
    return Scaffold(
      backgroundColor: ColorsManager.navbarColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: ColorsManager.primary,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                color: ColorsManager.grey,
                fontSize: FontSize.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error screen.
  Widget _buildErrorScreen(String message) {
    return Scaffold(
      backgroundColor: ColorsManager.navbarColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: ColorsManager.error,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Call Error',
                style: TextStyle(
                  color: ColorsManager.white,
                  fontSize: FontSize.large,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColorsManager.grey,
                  fontSize: FontSize.medium,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the actual call screen with ZEGO UI.
  Widget _buildCallScreen() {
    final isVideoCall = _callModel!.callType == CallType.video;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldEnd = await _showEndCallConfirmation();
        if (shouldEnd && mounted) {
          await _handleCallEnd();
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: ColorsManager.navbarColor,
        body: Stack(
          children: [
            // ZEGO Call UI
            ZegoUIKitPrebuiltCall(
              appID: AppConstants.appID,
              appSign: AppConstants.appSign,
              userID: _callModel!.callerId ?? '',
              userName: _callModel!.callerUserName ?? '',
              callID: _callId!,
              config: isVideoCall
                  ? ZegoCallConfig.getOneOnOneConfig(true)
                  : ZegoCallConfig.getOneOnOneConfig(false),
              events: ZegoUIKitPrebuiltCallEvents(
                onError: _handleZegoError,
                onCallEnd: _handleZegoCallEnd,
                user: ZegoCallUserEvents(
                  onEnter: (user) {
                    log('[CallScreen] User joined: ${user.name}');
                    // Mark call as connected when other user joins
                    if (_callModel?.callId != null) {
                      _callDataSources.markCallAsConnected(_callModel!.callId!);
                    }
                  },
                  onLeave: (user) {
                    log('[CallScreen] User left: ${user.name}');
                  },
                ),
              ),
            ),

            // Duration overlay
            Positioned(
              top: MediaQuery.of(context).padding.top + 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatDuration(_callDurationSeconds),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: FontSize.medium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle ZEGO SDK errors.
  void _handleZegoError(ZegoUIKitError error) {
    log('[CallScreen] ZEGO error: ${error.code} - ${error.message}');

    String userMessage;

    switch (error.code) {
      case 300001003:
        userMessage = 'Failed to join call room. Please try again.';
        break;
      case 1001004:
        userMessage = 'Connection failed. Check your internet connection.';
        break;
      case 1000002:
        userMessage = 'Failed to start media stream.';
        break;
      default:
        userMessage = 'Call error: ${error.message}';
    }

    Get.snackbar(
      'Call Error',
      userMessage,
      backgroundColor: ColorsManager.error,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );

    // End call on error
    _handleCallEnd();
    Get.back();
  }

  /// Handle call end event from ZEGO.
  void _handleZegoCallEnd(
    ZegoCallEndEvent event,
    VoidCallback defaultAction,
  ) {
    log('[CallScreen] Call ended by ZEGO: ${event.reason}');

    // Update status based on end reason
    if (_callModel?.callId != null) {
      switch (event.reason) {
        case ZegoCallEndReason.localHangUp:
        case ZegoCallEndReason.remoteHangUp:
          _callDataSources.endCall(_callModel!.callId!, _callDurationSeconds);
          break;
        case ZegoCallEndReason.kickOut:
          _callDataSources.markCallAsCancelled(_callModel!.callId!);
          break;
        default:
          _callDataSources.endCall(_callModel!.callId!, _callDurationSeconds);
      }
    }

    // Execute default action (navigate back)
    defaultAction();
  }
}
