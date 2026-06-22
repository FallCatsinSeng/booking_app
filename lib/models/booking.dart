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

  factory Booking.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String;
    final paymentStatus = json['payment_status'] as String?;
    
    String statusLabel = json['status_label'] as String? ?? status;
    String statusColor = json['status_color'] as String? ?? 'gray';

    // Jika pembayaran sudah lunas namun admin belum menyetujui, ubah labelnya.
    if (paymentStatus == 'paid' && status == 'pending') {
      statusLabel = 'Menunggu Persetujuan Admin';
      statusColor = 'orange';
    }

    return Booking(
      id: json['id'] as int,
      bookingCode: json['booking_code'] as String,
      bookingDate: json['booking_date'] as String?,
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      duration: json['duration'] as String?,
      purpose: json['purpose'] as String? ?? '',
      attendeesCount: json['attendees_count'] as int? ?? 0,
      status: status,
      statusLabel: statusLabel,
      statusColor: statusColor,
      progressStep: json['progress_step'] as int? ?? 0,
      progressTotal: json['progress_total'] as int? ?? 3,
      paymentStatus: paymentStatus,
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

  Booking copyWith({
    int? id,
    String? bookingCode,
    String? bookingDate,
    String? startTime,
    String? endTime,
    String? duration,
    String? purpose,
    int? attendeesCount,
    String? status,
    String? statusLabel,
    String? statusColor,
    int? progressStep,
    int? progressTotal,
    String? paymentStatus,
    bool? isCheckedIn,
    bool? isCancellable,
    String? notes,
    String? cancelledBy,
    int? rating,
    String? review,
    Facility? facility,
    String? userName,
  }) {
    return Booking(
      id: id ?? this.id,
      bookingCode: bookingCode ?? this.bookingCode,
      bookingDate: bookingDate ?? this.bookingDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      purpose: purpose ?? this.purpose,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      statusColor: statusColor ?? this.statusColor,
      progressStep: progressStep ?? this.progressStep,
      progressTotal: progressTotal ?? this.progressTotal,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      isCancellable: isCancellable ?? this.isCancellable,
      notes: notes ?? this.notes,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      facility: facility ?? this.facility,
      userName: userName ?? this.userName,
    );
  }
}
