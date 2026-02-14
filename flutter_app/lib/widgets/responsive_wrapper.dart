import 'package:flutter/material.dart';
import '../services/background_service.dart';

/// Simple responsive wrapper that centers the app at a fixed max width on
/// larger screens while keeping full-width on mobile.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 600.0, // reverted to 600px per request (better readability)
  });

  @override
  Widget build(BuildContext context) {
    // Le fond doit TOUJOURS couvrir tout l'écran, la colonne centrale est centrée et contrainte.
    return ValueListenableBuilder<String?>(
      valueListenable: currentBackgroundAsset,
      builder: (context, asset, _) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              minWidth: 0,
              minHeight: 0,
            ),
            child: asset != null
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(asset, fit: BoxFit.cover),
                      ),
                      child,
                    ],
                  )
                : child,
          ),
        );
      },
    );
  }
}
