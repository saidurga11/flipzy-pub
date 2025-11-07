import 'dart:io' show Platform;

class Config {
  // For Android emulator, use 10.0.2.2 to access host machine's localhost
  // For iOS simulator and other platforms, use localhost
  static String get apiEndpoint {
    const envEndpoint = String.fromEnvironment('API_ENDPOINT');
    if (envEndpoint.isNotEmpty) {
      return envEndpoint;
    }

    // Auto-detect platform and use appropriate endpoint
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8080';
      }
    } catch (e) {
      // If Platform is not available (web), fall back to localhost
    }

    return 'http://localhost:8080';
  }
}
