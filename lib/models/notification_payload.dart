enum NotificationType {
  bookingApproved,
  bookingRejected,
  bookingReminder,
  bookingEnded,
  newBookingRequest,
  bookingCancelled,
  unknown
}

class NotificationPayload {
  final NotificationType type;
  final int? bookingId;
  final String? title;
  final String? body;

  NotificationPayload({
    required this.type,
    this.bookingId,
    this.title,
    this.body,
  });

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      type: _typeFromString(json['type'] as String?),
      bookingId: int.tryParse(json['booking_id']?.toString() ?? ''),
      title: json['title'] as String?,
      body: json['body'] as String?,
    );
  }

  static NotificationType _typeFromString(String? type) {
    switch (type) {
      case 'booking_approved':
        return NotificationType.bookingApproved;
      case 'booking_rejected':
        return NotificationType.bookingRejected;
      case 'booking_reminder':
        return NotificationType.bookingReminder;
      case 'booking_ended':
        return NotificationType.bookingEnded;
      case 'new_booking_request':
        return NotificationType.newBookingRequest;
      case 'booking_cancelled':
        return NotificationType.bookingCancelled;
      default:
        return NotificationType.unknown;
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'booking_id': bookingId,
        'title': title,
        'body': body,
      };
}
