class RouteConstants {
  RouteConstants._();

  // Auth Flow
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String setupPin = '/setup-pin';

  // Main App Top-Level Destinations
  static const String dashboard = '/dashboard';
  static const String subscriptions = '/subscriptions';
  static const String savings = '/savings';
  static const String settings = '/settings';
  static const String profile = '/profile';

  // Subroutes
  static const String subscriptionDetail = 'subscription/:id';
  static const String editSubscription = 'edit';
  static const String notifications = 'notifications';
  static const String addSubscription = 'add';
  static const String selectPackage = 'select-package';
  static const String admin = '/admin';

  // Helper methods
  static String subscriptionDetailPath(String id) =>
      '/dashboard/subscription/$id';
  static String editSubscriptionPath(String id) =>
      '/dashboard/subscription/$id/edit';
}
