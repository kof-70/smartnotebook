import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';

class BiometricService {
  final LocalAuthentication _localAuth;
  
  BiometricService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      final isAvailable = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      return isAvailable && canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to access your notes',
    bool biometricOnly = false,
  }) async {
    try {
      final isAvailable = await this.isAvailable();
      if (!isAvailable) {
        return false;
      }

      final authResult = await _localAuth.authenticate(
        localizedReason: localizedReason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Smart Notebook Authentication',
            cancelButton: 'Cancel',
            deviceCredentialsRequiredTitle: 'Device credentials required',
            deviceCredentialsSetupDescription: 'Please set up device credentials',
            goToSettingsButton: 'Go to Settings',
          ),
        ],
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );

      return authResult;
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  Future<bool> authenticateForSensitiveOperation({
    String operation = 'access sensitive data',
  }) async {
    return await authenticate(
      localizedReason: 'Please authenticate to $operation',
      biometricOnly: false,
    );
  }
}