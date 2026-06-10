import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Drives which bottom-nav tab is shown. Exposed so any screen can navigate
/// without prop-drilling or importing home_screen.dart.
final selectedTabProvider = StateProvider<int>((ref) => 0);
