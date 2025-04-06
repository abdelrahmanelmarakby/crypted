// ignore_for_file: deprecated_member_use

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  PermissionsHelper._();

  static final PermissionsHelper instance = PermissionsHelper._();

  Future<void> requestPermission({
    required Permission permission,
    Function? onGranted,
    Function? onDenied,
    Function? onPermanentlyDenied,
  }) async {
    final status = await permission.status;
    switch (status) {
      case PermissionStatus.granted:
        onGranted?.call();
        break;
      case PermissionStatus.denied:
        final result = await permission.request();
        if (result.isGranted) {
          onGranted?.call();
        } else if (result.isPermanentlyDenied) {
          if (onPermanentlyDenied != null) {
            onPermanentlyDenied();
          }
        } else {
          if (onDenied != null) {
            onDenied();
          }
        }
        break;
      case PermissionStatus.permanentlyDenied:
        if (onPermanentlyDenied != null) {
          onPermanentlyDenied();
        }
        break;
      default:
        if (onDenied != null) {
          onDenied();
        }
    }
  }

  Future<void> requestLocationPermission({
    Function? onGranted,
    Function? onDenied,
    Function? onPermanentlyDenied,
  }) async {
    await requestPermission(
      permission: Permission.location,
      onGranted: onGranted,
      onDenied: onDenied,
      onPermanentlyDenied: onPermanentlyDenied,
    );
  }

  Future<void> requestStoragePermission({
    Function? onGranted,
    Function? onDenied,
    Function? onPermanentlyDenied,
  }) async {
    await requestPermission(
      permission: Permission.storage,
      onGranted: onGranted,
      onDenied: onDenied,
      onPermanentlyDenied: onPermanentlyDenied,
    );
  }

  Future<void> requestCameraPermission({
    Function? onGranted,
    Function? onDenied,
    Function? onPermanentlyDenied,
  }) async {
    await requestPermission(
      permission: Permission.camera,
      onGranted: onGranted,
      onDenied: onDenied,
      onPermanentlyDenied: onPermanentlyDenied,
    );
  }

  Future<void> requestMicrophonePermission({
    Function? onGranted,
    Function? onDenied,
    Function? onPermanentlyDenied,
  }) async {
    await requestPermission(
      permission: Permission.microphone,
      onGranted: onGranted,
      onDenied: onDenied,
      onPermanentlyDenied: onPermanentlyDenied,
    );
  }

  Future<void> requestPhonePermission({
    Function? onGranted,
    Function? onDenied,
    Function? onPermanentlyDenied,
  }) async {
    await requestPermission(
      permission: Permission.phone,
      onGranted: onGranted,
      onDenied: onDenied,
      onPermanentlyDenied: onPermanentlyDenied,
    );
  }

  Future<void> requestCalendarPermission({
    Function? onGranted,
    Function? onDenied,
    Function? onPermanentlyDenied,
  }) async {
    await requestPermission(
      permission: Permission.calendarFullAccess,
      onGranted: onGranted,
      onDenied: onDenied,
      onPermanentlyDenied: onPermanentlyDenied,
    );
  }

  Future<List<Placemark>> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return placemarkFromCoordinates(position.latitude, position.longitude);
  }
}
