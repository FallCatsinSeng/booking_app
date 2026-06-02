import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Base URL for the Laravel API.
///
/// - Android emulator reaches the host machine via 10.0.2.2.
/// - Web/desktop/iOS simulator use localhost.
/// Override at build time with: --dart-define=API_BASE_URL=http://HOST:8000/api
class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;

    // Untuk Android Emulator, gunakan 10.0.2.2 agar lebih stabil
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }

    // IP Address komputer Anda untuk akses dari luar emulator/web
    return 'http://192.168.49.222:8000/api';
  }
}
