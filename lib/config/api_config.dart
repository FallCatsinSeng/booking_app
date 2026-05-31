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
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    return 'http://localhost:8000/api';
  }
}
