import 'package:subscription_track/core/network/internet_checker.dart';

class StubInternetChecker implements InternetChecker {
  const StubInternetChecker();

  @override
  Future<bool> hasInternet() async => true;
}

InternetChecker getPlatformInternetChecker() => const StubInternetChecker();
