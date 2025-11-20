import 'package:local_auth/local_auth.dart';

class FaceAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return <BiometricType>[];
    }
  }

  Future<bool> isFaceAvailable() async {
    final types = await getAvailableBiometrics();
    return types.contains(BiometricType.face) || types.contains(BiometricType.strong);
  }

  Future<bool> isFingerprintAvailable() async {
    final types = await getAvailableBiometrics();
    return types.contains(BiometricType.fingerprint) || types.contains(BiometricType.weak);
  }

  Future<bool> authenticate({
    String reason = 'Xác thực sinh trắc học để tiếp tục',
    bool biometricOnly = true,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: false,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
