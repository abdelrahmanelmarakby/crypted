import 'dart:developer';
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

/// App Tracking Transparency Service
/// Handles iOS ATT permission request as required by Apple App Store
/// This must be called BEFORE any data collection that could be used
/// for tracking the user across apps or websites.
class ATTService {
  static final ATTService _instance = ATTService._internal();
  factory ATTService() => _instance;
  ATTService._internal();

  TrackingStatus _status = TrackingStatus.notDetermined;
  bool _hasRequestedPermission = false;

  TrackingStatus get status => _status;
  bool get isAuthorized => _status == TrackingStatus.authorized;
  bool get hasRequestedPermission => _hasRequestedPermission;

  /// Initialize and request ATT permission on iOS
  /// Should be called early in app lifecycle, before any tracking/analytics
  Future<TrackingStatus> requestTrackingPermission() async {
    // ATT is only required on iOS
    if (!Platform.isIOS) {
      log('ATT: Skipping - not iOS platform');
      return TrackingStatus.authorized;
    }

    try {
      // First, check the current status
      _status = await AppTrackingTransparency.trackingAuthorizationStatus;
      log('ATT: Current status: $_status');

      // If status is not determined, request permission
      if (_status == TrackingStatus.notDetermined) {
        // Wait for app to be in active state before showing dialog
        // This prevents the dialog from being dismissed immediately
        await Future.delayed(const Duration(milliseconds: 500));

        log('ATT: Requesting tracking authorization...');
        _status = await AppTrackingTransparency.requestTrackingAuthorization();
        _hasRequestedPermission = true;
        log('ATT: User response: $_status');
      }

      return _status;
    } catch (e) {
      log('ATT: Error requesting permission: $e');
      return TrackingStatus.notDetermined;
    }
  }

  /// Get the IDFA (Identifier for Advertisers) if authorized
  /// Returns null if not authorized or not available
  Future<String?> getAdvertisingIdentifier() async {
    if (!Platform.isIOS) return null;

    try {
      if (_status == TrackingStatus.authorized) {
        final uuid = await AppTrackingTransparency.getAdvertisingIdentifier();
        return uuid;
      }
      return null;
    } catch (e) {
      log('ATT: Error getting advertising identifier: $e');
      return null;
    }
  }

  /// Check if tracking is allowed based on user's ATT decision
  bool canTrack() {
    if (!Platform.isIOS) return true;
    return _status == TrackingStatus.authorized;
  }
}
