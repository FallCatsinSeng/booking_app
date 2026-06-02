import '../models/booking.dart';
import '../models/category.dart';
import '../models/facility.dart';
import 'api_client.dart';
import 'notification_service.dart';

/// Wraps all data endpoints. Laravel JsonResource wraps payloads in {"data": ...}.
class BookingApi {
  final ApiClient api;
  BookingApi(this.api);

  List<dynamic> _list(dynamic res) => (res is Map && res['data'] is List)
      ? res['data'] as List<dynamic>
      : (res as List<dynamic>);

  Map<String, dynamic> _single(dynamic res) =>
      (res is Map && res['data'] is Map ? res['data'] : res)
          as Map<String, dynamic>;

  // ── Facilities & categories ──────────────────────────────
  Future<List<Category>> categories() async {
    final res = await api.get('/categories');
    return _list(
      res,
    ).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Facility>> facilities({
    String? category,
    String? date,
    String? startTime,
    String? endTime,
  }) async {
    final res = await api.get(
      '/facilities',
      query: {
        'category': ?category,
        'date': ?date,
        'start_time': ?startTime,
        'end_time': ?endTime,
      },
    );
    return _list(
      res,
    ).map((e) => Facility.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Facility> facility(String code) async =>
      Facility.fromJson(_single(await api.get('/facilities/$code')));

  // ── Bookings (user) ──────────────────────────────────────
  Future<List<Booking>> myBookings() async {
    final res = await api.get('/bookings');
    final list = _list(
      res,
    ).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
    for (var b in list) {
      if (b.status == 'approved' || b.status == 'active') {
        NotificationService().scheduleBookingReminders(b);
      }
    }
    return list;
  }

  Future<Booking> booking(String code) async {
    final b = Booking.fromJson(_single(await api.get('/bookings/$code')));
    if (b.status == 'approved' || b.status == 'active') {
      NotificationService().scheduleBookingReminders(b);
    }
    return b;
  }

  Future<Booking> createBooking({
    required int facilityId,
    required String date,
    required String startTime,
    required String endTime,
    required String purpose,
    required int attendees,
  }) async {
    final res = await api.post(
      '/bookings',
      body: {
        'facility_id': facilityId,
        'booking_date': date,
        'start_time': startTime,
        'end_time': endTime,
        'purpose': purpose,
        'attendees_count': attendees,
      },
    );
    return Booking.fromJson(_single(res));
  }

  Future<Booking> cancelBooking(String code, String notes) async =>
      Booking.fromJson(
        _single(
          await api.post('/bookings/$code/cancel', body: {'notes': notes}),
        ),
      );

  Future<Booking> rateBooking(String code, int rating, String review) async =>
      Booking.fromJson(
        _single(
          await api.post(
            '/bookings/$code/rate',
            body: {'rating': rating, 'review': review},
          ),
        ),
      );

  // ── Admin ────────────────────────────────────────────────
  Future<List<Booking>> adminBookings() async {
    final res = await api.get('/admin/bookings');
    return _list(
      res,
    ).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Booking> adminUpdateStatus(
    int id,
    String status, {
    String? notes,
  }) async {
    final res = await api.patch(
      '/admin/bookings/$id/status',
      body: {'status': status, 'notes': ?notes},
    );
    return Booking.fromJson(_single(res));
  }

  // ── Payment (Midtrans) ───────────────────────────────────
  /// Returns the Snap {token, redirect_url, order_id, amount} for a paid booking.
  Future<Map<String, dynamic>> pay(String code) async {
    final res = await api.post('/bookings/$code/pay');
    return res as Map<String, dynamic>;
  }

  // ── Check-in (GPS + face) ────────────────────────────────
  Future<Booking> checkin(
    String code,
    double lat,
    double lng,
    String selfiePath,
  ) async {
    final res = await api.postMultipart(
      '/bookings/$code/checkin',
      fields: {'latitude': '$lat', 'longitude': '$lng'},
      fileField: 'selfie',
      filePath: selfiePath,
    );
    return Booking.fromJson(_single(res));
  }

  // ── AI assistant (OpenRouter) ────────────────────────────
  /// Returns {filters, count, facilities:[Facility]}.
  Future<({List<Facility> facilities, int count})> assistant(
    String message,
  ) async {
    final res =
        await api.post('/assistant', body: {'message': message})
            as Map<String, dynamic>;
    final list = (res['facilities'] is Map && res['facilities']['data'] is List)
        ? res['facilities']['data'] as List
        : (res['facilities'] as List? ?? []);
    return (
      facilities: list
          .map((e) => Facility.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: res['count'] as int? ?? list.length,
    );
  }
}
