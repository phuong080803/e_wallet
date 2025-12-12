import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BiometricController extends GetxController {
  static const _metaEnabledKey = 'biometric_face_enabled';
  static const _metaFpEnabledKey = 'biometric_fingerprint_enabled';
  static const _metaPreferredKey = 'biometric_preferred_method';
  final LocalAuthentication _auth = LocalAuthentication();
  final _supabase = Supabase.instance.client;

  final RxBool isBusy = false.obs;

  Future<bool> deviceSupportsBiometrics() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> isFaceAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final types = await _auth.getAvailableBiometrics();
      return types.contains(BiometricType.face) || types.contains(BiometricType.strong);
    } catch (_) {
      return false;
    }
  }

  Future<bool> isFingerprintAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final types = await _auth.getAvailableBiometrics();
      return types.contains(BiometricType.fingerprint) || types.contains(BiometricType.strong);
    } catch (_) {
      return false;
    }
  }

  Future<bool> isFaceEnabled() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      final metadata = user.userMetadata ?? {};
      final enabled = metadata[_metaEnabledKey];
      return enabled == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> setFaceEnabled(bool enabled) async {
    isBusy.value = true;
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Vui lòng đăng nhập lại');
      final currentMetadata = user.userMetadata ?? {};
      final newMetadata = Map<String, dynamic>.from(currentMetadata);
      newMetadata[_metaEnabledKey] = enabled;
      newMetadata['biometric_updated_at'] = DateTime.now().toIso8601String();
      await _supabase.auth.updateUser(UserAttributes(data: newMetadata));
    } finally {
      isBusy.value = false;
    }
  }

  Future<bool> isFingerprintEnabled() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      final metadata = user.userMetadata ?? {};
      final enabled = metadata[_metaFpEnabledKey];
      return enabled == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> setFingerprintEnabled(bool enabled) async {
    isBusy.value = true;
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Vui lòng đăng nhập lại');
      final currentMetadata = user.userMetadata ?? {};
      final newMetadata = Map<String, dynamic>.from(currentMetadata);
      newMetadata[_metaFpEnabledKey] = enabled;
      newMetadata['biometric_updated_at'] = DateTime.now().toIso8601String();
      await _supabase.auth.updateUser(UserAttributes(data: newMetadata));
    } finally {
      isBusy.value = false;
    }
  }

  Future<bool> isFaceEnrolled() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      final metadata = user.userMetadata ?? {};
      final faceEmbedding = metadata['face_embedding'];
      return faceEmbedding != null && (faceEmbedding as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getFaceEnrollmentDate() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      final metadata = user.userMetadata ?? {};
      return metadata['face_enrolled_at'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> unenrollFace() async {
    isBusy.value = true;
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Vui lòng đăng nhập lại');
      final currentMetadata = user.userMetadata ?? {};
      final newMetadata = Map<String, dynamic>.from(currentMetadata);
      newMetadata.remove('face_embedding');
      newMetadata.remove('face_enrolled_at');
      newMetadata.remove('face_enrollment_version');
      await _supabase.auth.updateUser(UserAttributes(data: newMetadata));
    } finally {
      isBusy.value = false;
    }
  }

  Future<bool> isFingerprintEnrolled() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      // Check if device has fingerprint capability and it's available
      final types = await _auth.getAvailableBiometrics();
      return types.contains(BiometricType.fingerprint) || types.contains(BiometricType.strong);
    } catch (_) {
      return false;
    }
  }

  // Removed enrollFingerprint() - no longer needed
  // Removed unenrollFingerprint() - no longer needed

  Future<bool> authenticateFingerprint() async {
    try {
      final available = await isFingerprintAvailable();
      if (!available) return false;
      return await _auth.authenticate(
        localizedReason: 'Xác thực vân tay để tiếp tục',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateFace() async {
    try {
      final available = await isFaceAvailable();
      if (!available) return false;
      return await _auth.authenticate(
        localizedReason: 'Xác thực khuôn mặt để tiếp tục',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }

  Future<String> getPreferredMethod() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 'face';
      final metadata = user.userMetadata ?? {};
      final m = metadata[_metaPreferredKey];
      if (m == 'fingerprint' || m == 'face') return m;
      return 'face';
    } catch (_) {
      return 'face';
    }
  }

  Future<void> setPreferredMethod(String method) async {
    if (method != 'fingerprint' && method != 'face') return;
    isBusy.value = true;
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Vui lòng đăng nhập lại');
      final currentMetadata = user.userMetadata ?? {};
      final newMetadata = Map<String, dynamic>.from(currentMetadata);
      newMetadata[_metaPreferredKey] = method;
      newMetadata['biometric_updated_at'] = DateTime.now().toIso8601String();
      await _supabase.auth.updateUser(UserAttributes(data: newMetadata));
    } finally {
      isBusy.value = false;
    }
  }
}
