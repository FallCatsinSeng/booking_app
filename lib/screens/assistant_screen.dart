import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/facility.dart';
import '../services/booking_api.dart';
import 'facility_detail_screen.dart';

/// Natural-language facility finder. The query is sent to the backend, which
/// uses OpenRouter to extract filters and returns matching facilities.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _input = TextEditingController();
  bool _busy = false;
  String? _error;
  List<Facility>? _results;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final msg = _input.text.trim();
    if (msg.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await context.read<BookingApi>().assistant(msg);
      setState(() => _results = res.facilities);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _input,
                decoration: const InputDecoration(
                  hintText: 'cth: ruang untuk 30 orang Senin siang',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _ask(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _busy ? null : _ask,
              child: _busy
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
            ),
          ]),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        Expanded(
          child: _results == null
              ? const Center(child: Text('Tanyakan kebutuhan ruangan Anda.'))
              : _results!.isEmpty
                  ? const Center(child: Text('Tidak ada fasilitas yang cocok.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _results!.length,
                      itemBuilder: (context, i) {
                        final f = _results![i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.meeting_room)),
                            title: Text(f.name),
                            subtitle: Text('${f.location ?? '-'} • Kapasitas ${f.capacity}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FacilityDetailScreen(code: f.code),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
