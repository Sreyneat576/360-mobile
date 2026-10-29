import 'package:shared_preferences/shared_preferences.dart';

/// Runtime configuration for the API base URL.
///
/// Resolution order:
/// 1. A URL saved by the user from the sign-in screen ("Server" setting).
/// 2. `--dart-define=API_BASE_URL=...` passed at build time.
/// 3. The default below, which matches the web client's fallback.
///
/// Note: iOS and Android block plain HTTP by default. This project enables
/// cleartext traffic for development; a production build should point to an
/// HTTPS domain (see docs/MOBILE_APP_ANALYSIS.md, "Points to settle").
class AppConfig {
  AppConfig._();

  static const String _definedBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Same fallback as frontend/src/services/lib/axios.ts.
  static const String defaultBaseUrl = 'http://169.58.63.127/api/v1';

  static const String _prefsKey = 'api_base_url';

  static String _baseUrl =
      _definedBaseUrl.isNotEmpty ? _definedBaseUrl : defaultBaseUrl;

  static String get baseUrl => _baseUrl;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved.trim().isNotEmpty) {
      _baseUrl = normalize(saved);
    }
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final value = normalize(url);
    _baseUrl = value;
    await prefs.setString(_prefsKey, value);
  }

  /// Ensures the URL has a scheme and ends with `/api/v1` without a trailing slash.
  static String normalize(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return defaultBaseUrl;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.endsWith('/api/v1')) {
      url = '$url/api/v1';
    }
    return url;
  }

  /// Origin part of the base URL (scheme + host + port), used to resolve
  /// relative image paths returned by the backend.
  static String get origin {
    final uri = Uri.parse(_baseUrl);
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }
}
