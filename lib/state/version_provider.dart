import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return info.version.isNotEmpty ? info.version : '1.0.0';
  } catch (_) {
    return '1.0.0';
  }
});
