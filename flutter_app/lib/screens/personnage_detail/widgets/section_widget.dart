import 'package:flutter/material.dart';

/// Widget réutilisable pour afficher une section avec titre, icône et liste d'items
class CompetenceSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> items;
  final Widget Function(Map<String, dynamic>) builder;
  final VoidCallback onAdd;

  const CompetenceSection({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.builder,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green),
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isNotEmpty) ...items.map(builder),
      ],
    );
  }
}
