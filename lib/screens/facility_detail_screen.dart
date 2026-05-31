import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/facility.dart';
import '../services/booking_api.dart';
import 'booking_detail_screen.dart';

class FacilityDetailScreen extends StatefulWidget {
  final String code;
  const FacilityDetailScreen({super.key, required this.code});

  @override
  State<FacilityDetailScreen> createState() => _FacilityDetailScreenState();
}

class _FacilityDetailScreenState extends State<FacilityDetailScreen> {
  late final BookingApi _api = context.read<BookingApi>();
  late Future<Facility> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.facility(widget.code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Fasilitas')),
      body: FutureBuilder<Facility>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(snap.error.toString()));
          }
          final f = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(f.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('${f.category?.name ?? '-'} • ${f.location ?? '-'} ${f.floor ?? ''}'),
              const SizedBox(height: 8),
              Chip(label: Text('Kapasitas ${f.capacity} orang')),
              if (f.description != null) ...[
                const SizedBox(height: 12),
                Text(f.description!),
              ],
              const Divider(height: 32),
              Text('Buat Reservasi', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _BookingForm(facility: f),
            ],
          );
        },
      ),
    );
  }
}

class _BookingForm extends StatefulWidget {
  final Facility facility;
  const _BookingForm({required this.facility});

  @override
  State<_BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<_BookingForm> {
  final _formKey = GlobalKey<FormState>();
  final _purpose = TextEditingController();
  final _attendees = TextEditingController(text: '1');
  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _purpose.dispose();
    _attendees.dispose();
    super.dispose();
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
    if (picked != null) setState(() => isStart ? _start = picked : _end = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _start == null || _end == null) {
      setState(() => _error = 'Tanggal dan waktu wajib diisi.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final booking = await context.read<BookingApi>().createBooking(
            facilityId: widget.facility.id,
            date: DateFormat('yyyy-MM-dd').format(_date!),
            startTime: _fmtTime(_start!),
            endTime: _fmtTime(_end!),
            purpose: _purpose.text.trim(),
            attendees: int.tryParse(_attendees.text) ?? 1,
          );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BookingDetailScreen(code: booking.bookingCode)),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(_date == null ? 'Pilih Tanggal' : DateFormat('EEE, d MMM yyyy').format(_date!)),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pickTime(true),
                child: Text(_start == null ? 'Jam Mulai' : _fmtTime(_start!)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pickTime(false),
                child: Text(_end == null ? 'Jam Selesai' : _fmtTime(_end!)),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          TextFormField(
            controller: _purpose,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Keperluan', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().length < 10) ? 'Minimal 10 karakter' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _attendees,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'Jumlah Peserta', border: OutlineInputBorder()),
            validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? 'Minimal 1 peserta' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Ajukan Reservasi'),
          ),
        ],
      ),
    );
  }
}
