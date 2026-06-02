import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthProvider extends ChangeNotifier {
  static const _tokenKey = 'auth_token';

  final ApiClient api;
  User? _user;
  bool _loading = true;

  AuthProvider(this.api) {
    _restore();
    _listenPlayerIdChanges();
  }

  User? get user => _user;
  bool get isLoading => _loading;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      api.setToken(token);
      try {
        final data = await api.get('/auth/me');
        _user = User.fromJson(data['user'] as Map<String, dynamic>);
        // Sync player ID in case it changed while logged out
        _syncPlayerId();
      } catch (_) {
        await _clearToken();
      }
    }
    _loading = false;
    notifyListeners();
  }

  /// Listen for OneSignal subscription changes (player ID can change).
  void _listenPlayerIdChanges() {
    OneSignal.User.pushSubscription.addObserver((state) {
      if (isAuthenticated && state.current.id != null) {
        _syncPlayerId();
      }
    });
  }

  Future<void> login(String email, String password) async {
    final playerId = OneSignal.User.pushSubscription.id;
    final data = await api.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
        if (playerId != null) 'player_id': playerId,
      },
    );
    await _onAuthenticated(data);
  }

  Future<void> register(String name, String email, String password) async {
    final playerId = OneSignal.User.pushSubscription.id;
    final data = await api.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        if (playerId != null) 'player_id': playerId,
      },
    );
    await _onAuthenticated(data);
  }

  Future<void> logout() async {
    try {
      await api.post('/auth/logout');
    } catch (_) {
      /* ignore network errors on logout */
    }
    await _clearToken();
    _user = null;
    notifyListeners();
  }

  Future<void> _onAuthenticated(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    api.setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _user = User.fromJson(data['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  /// Kirim player ID terbaru ke backend (fire-and-forget).
  Future<void> _syncPlayerId() async {
    try {
      final playerId = OneSignal.User.pushSubscription.id;
      if (playerId != null) {
        await api.post('/auth/player-id', body: {'player_id': playerId});
      }
    } catch (e) {
      if (kDebugMode) print('OneSignal sync error: $e');
    }
  }

  Future<void> _clearToken() async {
    api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
