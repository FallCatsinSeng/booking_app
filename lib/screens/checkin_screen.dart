import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/booking_api.dart';

/// Captures GPS + a selfie and submits them. All validation (geofence radius,
/// face presence) happens on the backend.
class CheckinScreen extends StatefulWidget {
  final String code;
  const CheckinScreen({super.key, required this.code});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  Position? _position;
  XFile? _selfie;
  bool _busy = false;
  String? _error;

  Future<void> _getLocation() async {
    setState(() => _error = null);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Izin lokasi ditolak.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _position = pos);
    } catch (e) {
      setState(() => _error = 'Gagal mendapatkan lokasi: $e');
    }
  }

  Future<void> _takeSelfie() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _selfie = picked);
  }

  Future<void> _submit() async {
    if (_position == null || _selfie == null) {
      setState(() => _error = 'Lokasi dan selfie wajib diisi.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<BookingApi>().checkin(
            widget.code,
            _position!.latitude,
            _position!.longitude,
            _selfie!.path,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Lakukan check-in di lokasi fasilitas. Pastikan GPS aktif '
              'dan ambil foto selfie sebagai bukti kehadiran.'),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.my_location),
            title: Text(_position == null
                ? 'Lokasi belum diambil'
                : '${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}'),
            trailing: TextButton(onPressed: _getLocation, child: const Text('Ambil')),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text(_selfie == null ? 'Selfie belum diambil' : 'Selfie siap'),
            trailing: TextButton(onPressed: _takeSelfie, child: const Text('Foto')),
          ),
          if (_selfie != null && !kIsWeb)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Image.file(File(_selfie!.path), height: 160),
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_circle),
            label: const Text('Check-in Sekarang'),
          ),
        ],
      ),
    );
  }
}
