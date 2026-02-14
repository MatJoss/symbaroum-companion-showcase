/// Dialogues personnalisés avec style parchemin
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

/// Dialogue stylisé Symbaroum (style parchemin)
class SymbaroumDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final bool showCloseButton;

  const SymbaroumDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.showCloseButton = true,
  });

  /// Affiche le dialogue
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool showCloseButton = true,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: SymbaroumColors.overlayDark,
      builder: (context) => SymbaroumDialog(
        title: title,
        content: content,
        actions: actions,
        showCloseButton: showCloseButton,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          // Fond avec dégradé façon parchemin
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A3C2A), // Brun parchemin foncé
              Color(0xFF3D3228), // Brun moyen
              Color(0xFF4A3C2A), // Retour brun foncé
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: SymbaroumColors.borderGold,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header avec titre
            _buildHeader(context),

            // Séparateur décoratif
            _buildDecorator(),

            // Contenu
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: content,
              ),
            ),

            // Actions
            if (actions != null && actions!.isNotEmpty) ...[
              _buildDecorator(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!
                      .map((action) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: action,
                          ))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.cinzel(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: SymbaroumColors.primary,
              ),
            ),
          ),
          if (showCloseButton)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              color: SymbaroumColors.textSecondary,
              iconSize: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildDecorator() {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            SymbaroumColors.borderGold.withValues(alpha: 0.5),
            SymbaroumColors.borderGold,
            SymbaroumColors.borderGold.withValues(alpha: 0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

/// Dialogue de confirmation
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDangerous;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmer',
    this.cancelLabel = 'Annuler',
    this.isDangerous = false,
  });

  /// Affiche le dialogue de confirmation
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    bool isDangerous = false,
  }) async {
    final result = await SymbaroumDialog.show<bool>(
      context: context,
      title: title,
      content: ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDangerous: isDangerous,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: isDangerous
                  ? ElevatedButton.styleFrom(
                      backgroundColor: SymbaroumColors.error,
                    )
                  : null,
              child: Text(confirmLabel),
            ),
          ],
        ),
      ],
    );
  }
}

/// Dialogue d'information (détails d'un talent, pouvoir, etc.)
class InfoDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String description;
  final Map<String, String>? details;

  const InfoDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.description,
    this.details,
  });

  /// Affiche le dialogue d'information
  static Future<void> show({
    required BuildContext context,
    required String title,
    String? subtitle,
    required String description,
    Map<String, String>? details,
  }) {
    return SymbaroumDialog.show(
      context: context,
      title: title,
      content: InfoDialog(
        title: title,
        subtitle: subtitle,
        description: description,
        details: details,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subtitle != null) ...[
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: SymbaroumColors.primary,
                ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (details != null && details!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          ...details!.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        '${entry.key}:',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: SymbaroumColors.textSecondary,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}

/// Dialogue de saisie numérique (pour modifier PV, corruption, etc.)
class NumberInputDialog extends StatefulWidget {
  final String title;
  final int initialValue;
  final int min;
  final int max;
  final String? label;

  const NumberInputDialog({
    super.key,
    required this.title,
    required this.initialValue,
    this.min = 0,
    required this.max,
    this.label,
  });

  /// Affiche le dialogue de saisie numérique
  static Future<int?> show({
    required BuildContext context,
    required String title,
    required int initialValue,
    int min = 0,
    required int max,
    String? label,
  }) {
    return showDialog<int>(
      context: context,
      barrierColor: SymbaroumColors.overlayDark,
      builder: (context) => NumberInputDialog(
        title: title,
        initialValue: initialValue,
        min: min,
        max: max,
        label: label,
      ),
    );
  }

  @override
  State<NumberInputDialog> createState() => _NumberInputDialogState();
}

class _NumberInputDialogState extends State<NumberInputDialog> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  void _increment() {
    if (_value < widget.max) {
      setState(() => _value++);
    }
  }

  void _decrement() {
    if (_value > widget.min) {
      setState(() => _value--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: SymbaroumColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: SymbaroumColors.borderGold, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.cinzel(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: SymbaroumColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            if (widget.label != null) ...[
              Text(
                widget.label!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: _value > widget.min ? _decrement : null,
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: SymbaroumColors.cardBackground,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '$_value',
                    style: GoogleFonts.cinzel(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: SymbaroumColors.primary,
                    ),
                  ),
                ),
                IconButton.filled(
                  onPressed: _value < widget.max ? _increment : null,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: SymbaroumColors.cardBackground,
                  ),
                ),
              ],
            ),
            Text(
              'Min: ${widget.min} - Max: ${widget.max}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_value),
                  child: const Text('Valider'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== ALIAS POUR COMPATIBILITÉ ====================

/// Alias pour SymbaroumDialog
typedef ParchmentDialog = SymbaroumDialog;

/// Fonction utilitaire pour afficher une confirmation
Future<bool> showSymbaroumConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmer',
  String cancelLabel = 'Annuler',
  bool isDangerous = false,
}) {
  return ConfirmDialog.show(
    context: context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    isDangerous: isDangerous,
  );
}
