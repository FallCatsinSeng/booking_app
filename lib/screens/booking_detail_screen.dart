import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../services/booking_api.dart';
import '../widgets/booking_progress.dart';
import '../widgets/status_chip.dart';
import 'checkin_screen.dart';
import 'payment_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final String code;
  const BookingDetailScreen({super.key, required this.code});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late final BookingApi _api = context.read<BookingApi>();
  late Future<Booking> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.booking(widget.code);
  }

  void _reload() => setState(() => _future = _api.booking(widget.code));

  Future<void> _cancel() async {
    final notes = await _promptText('Alasan Pembatalan', 'Minimal 5 karakter');
    if (notes == null) return;
    try {
      await _api.cancelBooking(widget.code, notes);
      _reload();
      _snack('Reservasi dibatalkan.');
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _rate() async {
    final result = await showDialog<({int rating, String review})>(
      context: context,
      builder: (_) => const _RatingDialog(),
    );
    if (result == null) return;
    try {
      await _api.rateBooking(widget.code, result.rating, result.review);
      _reload();
      _snack('Terima kasih atas penilaian Anda!');
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _pay() async {
    try {
      final snap = await _api.pay(widget.code);
      final redirectUrl = snap['redirect_url'] as String?;
      if (redirectUrl == null || redirectUrl.isEmpty) {
        _snack('URL pembayaran tidak tersedia.');
        return;
      }
      if (!mounted) return;
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => PaymentScreen(redirectUrl: redirectUrl)),
      );
      // Status is confirmed server-side via the Midtrans webhook; refresh.
      _reload();
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _checkin() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CheckinScreen(code: widget.code)),
    );
    if (ok == true) {
      _reload();
      _snack('Check-in berhasil!');
    }
  }

  Future<String?> _promptText(String title, String hint) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().length >= 5) Navigator.pop(ctx, controller.text.trim());
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _paymentLabel(String? status) => switch (status) {
        'paid' => 'Lunas',
        'pending' => 'Menunggu pembayaran',
        'failed' => 'Gagal',
        'expired' => 'Kedaluwarsa',
        _ => 'Belum dibayar',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Reservasi')),
      body: FutureBuilder<Booking>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(snap.error.toString()));
          }
          final b = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#${b.bookingCode}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                  StatusChip(label: b.statusLabel, color: b.statusColor),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Status Reservasi', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              BookingProgress(booking: b),
              const Divider(height: 32),
              _row('Fasilitas', b.facility?.name ?? '-'),
              _row('Lokasi', b.facility?.location ?? '-'),
              _row('Tanggal', b.bookingDate ?? '-'),
              _row('Waktu', '${b.startTime} - ${b.endTime}  (${b.duration ?? ''})'),
              _row('Peserta', '${b.attendeesCount} orang'),
              _row('Keperluan', b.purpose),
              if (b.facility?.isPaid ?? false)
                _row('Pembayaran', _paymentLabel(b.paymentStatus)),
              if (b.notes != null && b.notes!.isNotEmpty) _row('Catatan', b.notes!),
              if (b.rating != null) _row('Penilaian', '${b.rating} / 5 — ${b.review ?? ''}'),
              const SizedBox(height: 20),
              // Pay: paid facility, approved/pending, not yet settled.
              if ((b.facility?.isPaid ?? false) &&
                  b.paymentStatus != 'paid' &&
                  b.status != 'cancelled' &&
                  b.status != 'rejected')
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FilledButton.icon(
                    onPressed: _pay,
                    icon: const Icon(Icons.payment),
                    label: const Text('Bayar Sekarang'),
                  ),
                ),
              // Check-in: approved bookings that haven't checked in yet.
              if (b.status == 'approved' && !b.isCheckedIn)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FilledButton.icon(
                    onPressed: _checkin,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Check-in (GPS + Selfie)'),
                  ),
                ),
              if (b.isCheckedIn)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('Sudah check-in', style: TextStyle(color: Colors.green)),
                  ]),
                ),
              if (b.isCancellable)
                OutlinedButton.icon(
                  onPressed: _cancel,
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text('Batalkan Reservasi', style: TextStyle(color: Colors.red)),
                ),
              if (b.status == 'completed' && b.rating == null)
                FilledButton.icon(
                  onPressed: _rate,
                  icon: const Icon(Icons.star),
                  label: const Text('Beri Penilaian'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      );
}

class _RatingDialog extends StatefulWidget {
  const _RatingDialog();

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _rating = 5;
  final _review = TextEditingController();

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Beri Penilaian'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = star),
                icon: Icon(star <= _rating ? Icons.star : Icons.star_border, color: Colors.amber),
              );
            }),
          ),
          TextField(
            controller: _review,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Ulasan (min. 5 karakter)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            if (_review.text.trim().length >= 5) {
              Navigator.pop(context, (rating: _rating, review: _review.text.trim()));
            }
          },
          child: const Text('Kirim'),
        ),
      ],
    );
  }
}
