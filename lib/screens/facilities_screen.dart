import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/facility.dart';
import '../services/booking_api.dart';
import 'facility_detail_screen.dart';

class FacilitiesScreen extends StatefulWidget {
  const FacilitiesScreen({super.key});

  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  late final BookingApi _api = context.read<BookingApi>();
  List<Category> _categories = [];
  String? _selected;
  late Future<List<Facility>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.facilities();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _api.categories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {/* non-fatal */}
  }

  void _filter(String? slug) {
    setState(() {
      _selected = slug;
      _future = _api.facilities(category: slug);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_categories.isNotEmpty)
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _chip('Semua', null),
                ..._categories.map((c) => _chip(c.name, c.slug)),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _filter(_selected),
            child: FutureBuilder<List<Facility>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return _ErrorView(message: snap.error.toString(), onRetry: () => _filter(_selected));
                }
                final facilities = snap.data ?? [];
                if (facilities.isEmpty) {
                  return const Center(child: Text('Tidak ada fasilitas.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: facilities.length,
                  itemBuilder: (context, i) => _FacilityCard(facility: facilities[i]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, String? slug) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _selected == slug,
          onSelected: (_) => _filter(slug),
        ),
      );
}

class _FacilityCard extends StatelessWidget {
  final Facility facility;
  const _FacilityCard({required this.facility});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.meeting_room)),
        title: Text(facility.name),
        subtitle: Text('${facility.location ?? '-'} • Kapasitas ${facility.capacity}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FacilityDetailScreen(code: facility.code)),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message, textAlign: TextAlign.center),
        TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
      ]),
    );
  }
}
