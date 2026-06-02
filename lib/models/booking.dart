import 'facility.dart';

class Booking {
  final int id;
  final String bookingCode;
  final String? bookingDate;
  final String startTime;
  final String endTime;
  final String? duration;
  final String purpose;
  final int attendeesCount;
  final String status;
  final String statusLabel;
  final String statusColor;
  final int progressStep;
  final int progressTotal;
  final String? paymentStatus;
  final bool isCheckedIn;
  final bool isCancellable;
  final String? notes;
  final String? cancelledBy;
  final int? rating;
  final String? review;
  final Facility? facility;
  final String? userName;

  String? get cancelledByLabel {
    if (status != 'cancelled') return null;
    if (cancelledBy == 'admin') return 'Dibatalkan oleh Admin';
    if (cancelledBy == 'user') return 'Dibatalkan oleh Pengguna';
    return 'Dibatalkan';
  }

  Booking({
    required this.id,
    required this.bookingCode,
    this.bookingDate,
    required this.startTime,
    required this.endTime,
    this.duration,
    required this.purpose,
    required this.attendeesCount,
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    required this.progressStep,
    required this.progressTotal,
    this.paymentStatus,
    this.isCheckedIn = false,
    required this.isCancellable,
    this.notes,
    this.cancelledBy,
    this.rating,
    this.review,
    this.facility,
    this.userName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: json['id'] as int,
    bookingCode: json['booking_code'] as String,
    bookingDate: json['booking_date'] as String?,
    startTime: json['start_time'] as String? ?? '',
    endTime: json['end_time'] as String? ?? '',
    duration: json['duration'] as String?,
    purpose: json['purpose'] as String? ?? '',
    attendeesCount: json['attendees_count'] as int? ?? 0,
    status: json['status'] as String,
    statusLabel: json['status_label'] as String? ?? json['status'] as String,
    statusColor: json['status_color'] as String? ?? 'gray',
    progressStep: json['progress_step'] as int? ?? 0,
    progressTotal: json['progress_total'] as int? ?? 3,
    paymentStatus: json['payment_status'] as String?,
    isCheckedIn: json['is_checked_in'] as bool? ?? false,
    isCancellable: json['is_cancellable'] as bool? ?? false,
    notes: json['notes'] as String?,
    cancelledBy: json['cancelled_by'] as String?,
    rating: json['rating'] as int?,
    review: json['review'] as String?,
    facility: json['facility'] is Map<String, dynamic>
        ? Facility.fromJson(json['facility'] as Map<String, dynamic>)
        : null,
    userName: json['user'] is Map<String, dynamic>
        ? json['user']['name'] as String?
        : null,
  );
}
