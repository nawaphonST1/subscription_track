class AppConstants {
  AppConstants._();

  static const String appName = 'Subscription Track';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyLanguage = 'language';
  
  // Defaults
  static const int defaultNotificationDays = 3;
  static const String defaultCurrency = 'THB';
  static const String defaultLanguage = 'th';
  
  // Validation
  static const int minPinLength = 6;
  static const double maxSubscriptionPrice = 5000;
  static const int minServiceNameLength = 3;
}
