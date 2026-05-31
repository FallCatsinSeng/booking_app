import 'package:flutter/material.dart';

/// Small status badge. [color] is the API's status_color name.
class StatusChip extends StatelessWidget {
  final String label;
  final String color;
  const StatusChip({super.key, required this.label, required this.color});

  static const _map = {
    'yellow': Colors.orange,
    'green': Colors.green,
    'red': Colors.red,
    'gray': Colors.grey,
    'orange': Colors.deepOrange,
    'blue': Colors.blue,
  };

  @override
  Widget build(BuildContext context) {
    final c = _map[color] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
