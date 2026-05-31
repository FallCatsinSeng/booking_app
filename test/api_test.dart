// Live-API integration test. Requires the Docker stack running on localhost:8000.
// Run with: flutter test integration_test/api_test.dart  (or `flutter test`).
// Skips automatically if the API is unreachable so it won't break offline CI.
import 'package:flutter_test/flutter_test.dart';
import 'package:booking_app/models/user.dart';
import 'package:booking_app/services/api_client.dart';
import 'package:booking_app/services/booking_api.dart';

void main() {
  final api = ApiClient();
  final data = BookingApi(api);

  Future<bool> apiUp() async {
    try {
      await data.categories();
      return true;
    } catch (_) {
      return false;
    }
  }

  test('public endpoints parse', () async {
    if (!await apiUp()) {
      markTestSkipped('API not reachable on localhost:8000');
      return;
    }
    expect((await data.categories()).isNotEmpty, true);
    expect((await data.facilities()).isNotEmpty, true);
  });

  test('login + protected endpoints parse', () async {
    if (!await apiUp()) {
      markTestSkipped('API not reachable on localhost:8000');
      return;
    }
    final res = await api.post('/auth/login',
        body: {'email': 'budi@student.kampus.ac.id', 'password': 'password'});
    final user = User.fromJson(res['user'] as Map<String, dynamic>);
    expect(user.email, 'budi@student.kampus.ac.id');

    api.setToken(res['token'] as String);
    final bookings = await data.myBookings();
    for (final b in bookings) {
      expect(b.progressTotal, 3);
      expect(b.progressStep, inInclusiveRange(0, 3));
    }
  });
}
