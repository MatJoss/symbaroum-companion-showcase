import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// Onglet des notes du personnage
class NotesTab extends StatelessWidget {
  final TextEditingController notesController;
  final VoidCallback onModified;

  const NotesTab({
    super.key,
    required this.notesController,
    required this.onModified,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextFormField(
        controller: notesController,
        decoration: InputDecoration(
          labelText: 'Notes',
          labelStyle: TextStyle(color: SymbaroumTheme.gold),
          filled: true,
          fillColor: SymbaroumTheme.darkBrown.withValues(alpha: 0.25),
          alignLabelWithHint: true,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: SymbaroumTheme.gold.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: SymbaroumTheme.gold),
          ),
        ),
        style: TextStyle(color: SymbaroumTheme.parchment),
        maxLines: 20,
        onChanged: (value) => onModified(),
      ),
    );
  }
}
