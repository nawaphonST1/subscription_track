class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://subscription-track-dev.malaysiawest.cloudapp.azure.com',
  );

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '599940750728-bh01euq9q5unhnvlnai02sjlj18km8tm.apps.googleusercontent.com',
  );
}
