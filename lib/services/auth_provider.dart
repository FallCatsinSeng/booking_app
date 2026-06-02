import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'notification_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _tokenKey = 'auth_token';

  final ApiClient api;
  User? _user;
  bool _loading = true;

  AuthProvider(this.api) {
    _restore();
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
        if (isAdmin) {
          NotificationService().subscribeToAdminTopic();
        }
      } catch (_) {
        await _clearToken();
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final data = await api.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    await _onAuthenticated(data);
  }

  Future<void> register(String name, String email, String password) async {
    final data = await api.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
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

    if (isAdmin) {
      await NotificationService().unsubscribeFromAdminTopic();
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

    if (isAdmin) {
      NotificationService().subscribeToAdminTopic();
    }

    notifyListeners();
  }

  Future<void> _clearToken() async {
    api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
