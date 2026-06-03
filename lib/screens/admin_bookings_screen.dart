import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../services/booking_api.dart';
import '../widgets/status_chip.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  late final BookingApi _api = context.read<BookingApi>();
  late Future<List<Booking>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.adminBookings();
  }

  void _reload() => setState(() {
    _future = _api.adminBookings();
  });

  Future<void> _update(Booking b, String status) async {
    String? notes;
    if (status == 'rejected' || status == 'cancelled') {
      notes = await _promptNotes();
      if (notes == null) return;
    }
    try {
      await _api.adminUpdateStatus(b.id, status, notes: notes);
      _reload();
      _snack('Status diperbarui menjadi $status.');
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<String?> _promptNotes() async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alasan (wajib)'),
        content: TextField(controller: c, maxLines: 3),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (c.text.trim().isNotEmpty) Navigator.pop(ctx, c.text.trim());
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: FutureBuilder<List<Booking>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(snap.error.toString(), textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _reload,
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            );
          }
          final bookings = snap.data ?? [];
          if (bookings.isEmpty) {
            return const Center(child: Text('Tidak ada reservasi.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, i) {
              final b = bookings[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              b.facility?.name ?? b.bookingCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          StatusChip(
                            label: b.statusLabel,
                            color: b.statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Oleh: ${b.userName ?? '-'}'),
                      Text(
                        '${b.bookingDate ?? ''} • ${b.startTime}-${b.endTime}',
                      ),
                      Text(
                        b.purpose,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (b.status == 'pending')
                        OverflowBar(
                          children: [
                            TextButton(
                              onPressed: () => _update(b, 'approved'),
                              child: const Text('Setujui'),
                            ),
                            TextButton(
                              onPressed: () => _update(b, 'rejected'),
                              child: const Text(
                                'Tolak',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        )
                      else if (b.status == 'approved')
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _update(b, 'cancelled'),
                            child: const Text(
                              'Batalkan',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        )
                      else if (b.status == 'cancelled' ||
                          b.status == 'rejected')
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.status == 'rejected'
                                    ? 'Ditolak'
                                    : (b.cancelledByLabel ?? 'Dibatalkan'),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              if (b.notes != null && b.notes!.isNotEmpty)
                                Text(
                                  'Alasan: ${b.notes}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
