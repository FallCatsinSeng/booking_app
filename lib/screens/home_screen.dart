import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import 'admin_bookings_screen.dart';
import 'assistant_screen.dart';
import 'facilities_screen.dart';
import 'my_bookings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    final tabs = <({String label, IconData icon, Widget body})>[
      (label: 'Fasilitas', icon: Icons.meeting_room, body: const FacilitiesScreen()),
      (label: 'Asisten', icon: Icons.smart_toy_outlined, body: const AssistantScreen()),
      (label: 'Reservasi', icon: Icons.event_note, body: const MyBookingsScreen()),
      if (isAdmin)
        (label: 'Admin', icon: Icons.admin_panel_settings, body: const AdminBookingsScreen()),
    ];

    final current = _index.clamp(0, tabs.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[current].label),
        actions: [
          IconButton(
            tooltip: 'Keluar (${auth.user?.name ?? ''})',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: IndexedStack(
        index: current,
        children: tabs.map((t) => t.body).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}
