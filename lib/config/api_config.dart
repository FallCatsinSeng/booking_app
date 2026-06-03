/// Base URL for the Laravel API.
/// Override at build time with: --dart-define=API_BASE_URL=https://your-domain.com/api
class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;

    // Semua platform (Android HP, emulator, web, desktop) pakai server hosting
    return 'https://bkf.yusufsoftware.my.id/api';
  }
}
