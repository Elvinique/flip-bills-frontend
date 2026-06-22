import 'dart:developer';
import 'package:local_auth/local_auth.dart';

/// Wraps [LocalAuthentication] with a clean async API.
/// Returns `true` if the user authenticated (or if biometrics aren't
/// available — fail-open so the UX isn't blocked on unsupported devices).
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final _auth = LocalAuthentication();

  /// Returns `true` when the device supports biometrics AND has enrolled
  /// fingerprints / face.
  Future<bool> get isAvailable async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      log('BiometricService.isAvailable error: $e');
      return false;
    }
  }

  /// Prompt the user to authenticate before a sensitive operation.
  ///
  /// [reason] is shown in the system dialog.
  /// Returns `true` if authentication succeeded OR biometrics aren't available.
  Future<bool> authenticate({
    String reason = 'Confirm your identity to proceed',
  }) async {
    try {
      final available = await isAvailable;
      if (!available) {
        // Fail-open: device doesn't support biometrics — allow the operation.
        log('BiometricService: biometrics not available, skipping');
        return true;
      }
      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // allow PIN fallback
          stickyAuth: true,
        ),
      );
      log('BiometricService.authenticate: $didAuthenticate');
      return didAuthenticate;
    } catch (e) {
      log('BiometricService.authenticate error: $e');
      // Fail-open on unexpected errors so we don't hard-block the user.
      return true;
    }
  }
}
