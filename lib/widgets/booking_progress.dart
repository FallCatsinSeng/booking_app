import 'package:flutter/material.dart';
import '../models/booking.dart';

/// Booking lifecycle indicator: Diajukan -> Disetujui -> Selesai,
/// or a banner for terminal states (rejected/cancelled/expired).
class BookingProgress extends StatelessWidget {
  final Booking booking;
  const BookingProgress({super.key, required this.booking});

  static const _steps = ['Diajukan', 'Disetujui', 'Selesai'];

  static const _terminal = {
    'rejected': ('Ditolak', Colors.red),
    'cancelled': ('Dibatalkan', Colors.grey),
    'expired': ('Kedaluwarsa', Colors.orange),
  };

  @override
  Widget build(BuildContext context) {
    final terminal = _terminal[booking.status];
    if (terminal != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: terminal.$2.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(Icons.cancel, color: terminal.$2, size: 18),
          const SizedBox(width: 8),
          Text(terminal.$1,
              style: TextStyle(color: terminal.$2, fontWeight: FontWeight.bold)),
        ]),
      );
    }

    final reached = booking.progressStep; // 1=pending,2=approved,3=completed
    return Row(
      children: List.generate(_steps.length, (i) {
        final stepNo = i + 1;
        final isDone = stepNo < reached || booking.status == 'completed';
        final isCurrent = stepNo == reached && booking.status != 'completed';
        final color = isDone
            ? Colors.green
            : isCurrent
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300;
        return Expanded(
          child: Row(children: [
            Column(children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color,
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text('$stepNo',
                        style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Text(_steps[i], style: const TextStyle(fontSize: 11)),
            ]),
            if (i < _steps.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 18),
                  color: stepNo < reached ? Colors.green : Colors.grey.shade300,
                ),
              ),
          ]),
        );
      }),
    );
  }
}
