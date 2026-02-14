import 'package:flutter/material.dart';
import '../services/background_service.dart';

/// Widget to set the global background asset for the current route.
/// On mount it sets [currentBackgroundAsset.value] to the provided asset and
/// restores it on dispose.
class BackgroundSetter extends StatelessWidget {
  final String asset;
  final Widget child;

  const BackgroundSetter({super.key, required this.asset, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(asset, fit: BoxFit.cover),
        child,
      ],
    );
  }
}
