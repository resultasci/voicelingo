// Harness that drives the icon generator. Not a real test — it just gives us a
// headless dart:ui to rasterize the brand mark to PNG, since no Windows desktop
// project is configured. Run:
//   flutter test tool/gen_icon_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'gen_icon.dart';

void main() {
  test('generate launcher icon PNGs', () async {
    await generateIcons();
    expect(File('assets/icon/app_icon.png').existsSync(), isTrue);
    expect(File('assets/icon/app_icon_foreground.png').existsSync(), isTrue);
  });
}
