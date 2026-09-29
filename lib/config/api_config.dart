import 'package:flutter/foundation.dart';

class ApiConfig {
  static const _configuredUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    final configured = _configuredUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    if (configured.isNotEmpty) return configured;
    if (kReleaseMode) {
      throw StateError('Build with --dart-define=API_BASE_URL=https://your-api-host');
    }
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }
}
