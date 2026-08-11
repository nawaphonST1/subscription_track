class RouteConstants {
  RouteConstants._();

  // Auth Flow
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';

  // Main App
  static const String dashboard = '/dashboard';
  static const String subscriptionDetail = 'subscription/:id';
  static const String editSubscription = 'edit';
  static const String profile = 'profile';
  static const String settings = 'settings';
  static const String notifications = 'notifications';
  static const String addSubscription = 'add';
  static const String selectPackage = 'select-package';

  // Helper methods
  static String subscriptionDetailPath(String id) =>
      '/dashboard/subscription/$id';
  static String editSubscriptionPath(String id) =>
      '/dashboard/subscription/$id/edit';
}
