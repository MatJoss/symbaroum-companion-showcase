import 'package:flutter/foundation.dart';

/// Global notifier for the current page background asset (nullable).
/// Pages set their desired background by using [BackgroundSetter].
final ValueNotifier<String?> currentBackgroundAsset = ValueNotifier<String?>(null);
