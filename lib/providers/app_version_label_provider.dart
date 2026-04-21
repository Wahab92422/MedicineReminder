import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_version.dart';

/// Resolved label for the about/footer line, e.g. `Version 1.0.0 (1)`.
final appVersionLabelProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    final v = info.version.trim();
    final b = info.buildNumber.trim();
    if (v.isEmpty && b.isEmpty) {
      return _fallbackLabel();
    }
    if (b.isEmpty) {
      return 'Version $v';
    }
    return 'Version $v ($b)';
  } catch (_) {
    return _fallbackLabel();
  }
});

String _fallbackLabel() => 'Version $kAppVersionFallback ($kAppBuildFallback)';
