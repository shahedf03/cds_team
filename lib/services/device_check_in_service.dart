import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';

/// On-device half of §10: fingerprint match + GPS capture.
///
/// The biometric template never leaves the device — only the boolean result
/// of the match is ever handed to the caller.
class DeviceCheckInService {
  DeviceCheckInService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> get isBiometricAvailable async {
    try {
      final bool supported = await _auth.isDeviceSupported();
      final bool canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } on Exception {
      return false;
    }
  }

  /// Prompts for a fingerprint. Returns `true` only on a successful match —
  /// the network call must not happen otherwise.
  Future<bool> authenticate({
    String reason = 'Confirm your fingerprint to check in',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on Exception {
      return false;
    }
  }

  /// Current GPS fix, captured at the moment of a successful match.
  /// Throws [LocationException] with a message fit to show the user.
  Future<Position> currentPosition() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'Location services are off. Turn them on to check in.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Location permission is required to check in.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission is blocked. Enable it in Settings to check in.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }
}

class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}
