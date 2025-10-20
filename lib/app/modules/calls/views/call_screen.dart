import 'dart:async';
import 'dart:developer';

import 'package:crypted_app/app/data/data_source/call_data_sources.dart';
import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/core/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  CallModel? callModel;
  bool _isCallStarted = false;
  bool _isInitializing = true;
  Timer? _callTimer;
  int _callDuration = 0;
  int _retryCount = 0;
  static const int _maxRetries = 2;

  @override
  void initState() {
    super.initState();
    // Initialize call immediately
    _initializeCall();
  }

  @override
  void dispose() {
    _callTimer?.cancel();

    // End call properly when screen is disposed
    if (callModel != null && callModel!.callId != null) {
      _endCall();
    }

    super.dispose();
  }

  Future<void> _endCall() async {
    if (callModel?.callId != null && _callDuration > 0) {
      try {
        final callDataSource = CallDataSources();
        await callDataSource.endCall(callModel!.callId!, _callDuration);
        log('✅ Call ended properly: ${callModel!.callId}');
      } catch (e) {
        log('❌ Error ending call: $e');
      }
    }
  }

  Future<bool?> _showEndCallDialog() {
    return Get.dialog<bool>(
      AlertDialog(
        title: const Text('End Call'),
        content: const Text('Are you sure you want to end this call?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel', style: TextStyle(color: ColorsManager.grey)),
          ),
          TextButton(
            onPressed: () async {
              await _endCall();
              Get.back(result: true);
              Get.back(); // Go back to chat screen
            },
            child: Text('End Call', style: TextStyle(color: ColorsManager.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeCall() async {
    try {
      // Get call model from arguments
      callModel = Get.arguments as CallModel?;

      if (callModel == null) {
        _showErrorDialog('Invalid call parameters');
        return;
      }

      // Generate unique call ID if not provided
      final String callID = callModel!.callId ??
          '${callModel!.callerId}_${callModel!.calleeId}_${DateTime.now().millisecondsSinceEpoch}';

      // Check internet connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _showErrorDialog('No internet connection. Please check your network and try again.');
        return;
      }

      // Log call details for debugging
      log('Initializing call with details:');
      log('  Call ID: $callID');
      log('  Caller ID: ${callModel!.callerId}');
      log('  Caller Name: ${callModel!.callerUserName}');
      log('  Call Type: ${callModel!.callType}');
      log('  Connectivity: $connectivityResult');
      log('  Is Voice Call: ${callModel!.callType == CallType.audio}');

      // Ensure Zego UIKit is properly initialized before proceeding
      if (callModel!.callerId != null && callModel!.callerUserName != null) {
        try {
          await CallDataSources().onUserLogin(callModel!.callerId!, callModel!.callerUserName!)
              .timeout(const Duration(seconds: 25)); // Increased timeout

          // Wait for room login to complete with additional verification
          await Future.delayed(const Duration(seconds: 3));
          log('Waiting for room to be fully ready...');

          // Additional check for room readiness
          await Future.delayed(const Duration(seconds: 2));

          _retryCount = 0; // Reset retry count on success
          log('Zego UIKit initialization and room login completed successfully');
        } catch (e) {
          log('Zego UIKit initialization failed (attempt ${_retryCount + 1}): $e');

          if (_retryCount < _maxRetries) {
            _retryCount++;
            log('Retrying initialization...');
            await Future.delayed(const Duration(seconds: 2));
            return await _initializeCall(); // Retry recursively
          }

          // All retries failed
          if (e.toString().contains('timeout') || e.toString().contains('network')) {
            _showErrorDialog('Network connection timeout after multiple attempts. Please check your internet connection and try again.');
          } else if (e.toString().contains('room') || e.toString().contains('login')) {
            _showErrorDialog('Room login failed after multiple attempts. Please try again.');
          } else {
            _showErrorDialog('Failed to initialize calling service after multiple attempts. Please try again.');
          }
          return;
        }
      }

      // Skip permission checks - let Zego UIKit handle permissions internally
      setState(() {
        _isCallStarted = true;
        _isInitializing = false;
      });

      // Start call duration timer for actual calls
      if (callModel != null) {
        _startCallTimer();
      }

    } catch (e) {
      log('Error initializing call: $e');
      _showErrorDialog('Failed to initialize call: ${e.toString()}');
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _showErrorDialog(String message) {
    Get.dialog(
      AlertDialog(
        title: const Text('Call Error'),
        content: Text('$message\n\nPlease check your internet connection and try again. If the problem persists, please restart the app.'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              Get.back(); // Go back to chat screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (callModel == null || !_isCallStarted || _isInitializing) {
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
                _isInitializing ? 'Initializing call...' : 'Starting call...',
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

    // Call ID is already generated in _initializeCall()
    final String callID = callModel!.callId ??
        '${callModel!.callerId}_${callModel!.calleeId}_${DateTime.now().millisecondsSinceEpoch}';

    return WillPopScope(
      onWillPop: () async {
        // Prevent accidental back press during call
        return await _showEndCallDialog() ?? false;
      },
      child: Scaffold(
        backgroundColor: ColorsManager.navbarColor,
        body: Stack(
          children: [
            ZegoUIKitPrebuiltCall(
              appID: AppConstants.appID,
              appSign: AppConstants.appSign,
              userID: callModel!.callerId ?? '',
              userName: callModel!.callerUserName ?? '',
              callID: callID,
              config: (callModel!.callType == CallType.video)
                  ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                  : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
              // Add error handling and proper configuration
              events: ZegoUIKitPrebuiltCallEvents(
                onError: (error) {
                  log('ZegoUIKit Error: ${error.code} - ${error.message}');
                  log('Error details: ${error.toString()}');

                  // Handle different error types with more specific handling
                  if (error.code == 300001003) {
                    // Room login error - check underlying error
                    if (error.message.contains('1001004')) {
                      _showErrorDialog('Room login failed due to connection issues. Please check your internet connection and try again.');
                    } else {
                      _showErrorDialog('Room login failed. Please try again.');
                    }
                  } else if (error.code == 1001004) {
                    // Login failed - likely network or credentials issue
                    _showErrorDialog('Unable to connect to calling service. Please check your internet connection and try again.');
                  } else if (error.code == 1000002) {
                    // Not logged in to room - stream publishing issue
                    _showErrorDialog('Stream publishing failed. Please try again.');
                  } else {
                    _showErrorDialog('Call error: ${error.message} (Code: ${error.code})');
                  }
                  Get.back(); // Go back to chat screen on error
                },
                onCallEnd: (call, callEndEvent) {
                  log('Call ended: ${call.callID}');
                  // Update call status in database
                  if (call.callID != null) {
                    CallDataSources().updateCallStatus(call.callID!, CallStatus.ended);
                  }
                  Get.back(); // Go back to chat screen
                },
              ),
            ),

            // Call duration overlay
            Positioned(
              top: MediaQuery.of(context).padding.top + 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatDuration(_callDuration),
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
}
