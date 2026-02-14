/// Widgets réutilisables pour l'interface Symbaroum
library;

import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Indicateur de chargement stylisé
class SymbaroumLoading extends StatelessWidget {
  final String? message;
  final double size;

  const SymbaroumLoading({
    super.key,
    this.message,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              color: SymbaroumColors.primary,
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget d'erreur avec action de retry
class SymbaroumError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;
  final IconData icon;

  const SymbaroumError({
    super.key,
    required this.message,
    this.onRetry,
    this.onBack,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: SymbaroumColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
            if (onBack != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// État vide avec message et action optionnelle
class SymbaroumEmpty extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  const SymbaroumEmpty({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: SymbaroumColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: SymbaroumColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Carte stylisée Symbaroum avec bordure dorée optionnelle
class SymbaroumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool highlighted;
  final VoidCallback? onTap;

  const SymbaroumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: SymbaroumColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlighted ? SymbaroumColors.borderGold : SymbaroumColors.border,
          width: highlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: card,
      );
    }

    return card;
  }
}

/// Bouton primaire stylisé
class SymbaroumButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  const SymbaroumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: fullWidth ? const Size.fromHeight(48) : null,
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: SymbaroumColors.textDark,
              ),
            )
          : Row(
              mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    );

    return button;
  }
}

/// Bouton secondaire (outlined)
class SymbaroumOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;

  const SymbaroumOutlinedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: fullWidth ? const Size.fromHeight(48) : null,
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );
  }
}

/// Barre de progression stylisée (pour PV, endurance, corruption)
class StatBar extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  final Color color;
  final Color? backgroundColor;
  final bool showValues;
  final VoidCallback? onTap;

  const StatBar({
    super.key,
    required this.label,
    required this.current,
    required this.max,
    required this.color,
    this.backgroundColor,
    this.showValues = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              if (showValues)
                Text(
                  '$current / $max',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: backgroundColor ?? SymbaroumColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: SymbaroumColors.border),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicateur de connexion SSE
class ConnectionIndicator extends StatelessWidget {
  final bool isConnected;
  final bool showLabel;

  const ConnectionIndicator({
    super.key,
    required this.isConnected,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isConnected ? SymbaroumColors.success : SymbaroumColors.error,
            shape: BoxShape.circle,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            isConnected ? 'Connecté' : 'Déconnecté',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isConnected
                      ? SymbaroumColors.success
                      : SymbaroumColors.error,
                ),
          ),
        ],
      ],
    );
  }
}

/// Séparateur avec texte
class TextDivider extends StatelessWidget {
  final String text;

  const TextDivider({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: SymbaroumColors.textSecondary,
                ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// Badge de niveau (Novice, Adepte, Maître)
class NiveauBadge extends StatelessWidget {
  final int niveau;
  final bool compact;

  const NiveauBadge({
    super.key,
    required this.niveau,
    this.compact = false,
  });

  String get _label {
    switch (niveau) {
      case 1:
        return compact ? 'N' : 'Novice';
      case 2:
        return compact ? 'A' : 'Adepte';
      case 3:
        return compact ? 'M' : 'Maître';
      default:
        return '';
    }
  }

  Color get _color {
    switch (niveau) {
      case 1:
        return SymbaroumColors.success;
      case 2:
        return SymbaroumColors.warning;
      case 3:
        return SymbaroumColors.primary;
      default:
        return SymbaroumColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ==================== ALIAS POUR COMPATIBILITÉ ====================

/// Alias pour SymbaroumLoading
typedef SymbaroumLoadingIndicator = SymbaroumLoading;

/// Alias pour SymbaroumError
typedef SymbaroumErrorWidget = SymbaroumError;
