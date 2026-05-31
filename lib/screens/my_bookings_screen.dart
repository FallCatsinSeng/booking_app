import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../services/booking_api.dart';
import '../widgets/status_chip.dart';
import 'booking_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late Future<List<Booking>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<BookingApi>().myBookings();
  }

  void _reload() => setState(() => _future = context.read<BookingApi>().myBookings());

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
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(snap.error.toString(), textAlign: TextAlign.center),
                TextButton(onPressed: _reload, child: const Text('Coba lagi')),
              ]),
            );
          }
          final bookings = snap.data ?? [];
          if (bookings.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 120),
              Center(child: Text('Belum ada reservasi.')),
            ]);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, i) {
              final b = bookings[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(b.facility?.name ?? b.bookingCode),
                  subtitle: Text('${b.bookingDate ?? ''} • ${b.startTime}-${b.endTime}'),
                  trailing: StatusChip(label: b.statusLabel, color: b.statusColor),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BookingDetailScreen(code: b.bookingCode)),
                    );
                    _reload();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
