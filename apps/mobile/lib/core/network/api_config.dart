import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _configuredBaseUrl =
      String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (kIsWeb && kDebugMode) return 'http://localhost:3000';
    return 'https://subscription-track-dev.malaysiawest.cloudapp.azure.com';
  }

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '599940750728-bh01euq9q5unhnvlnai02sjlj18km8tm.apps.googleusercontent.com',
  );
}
