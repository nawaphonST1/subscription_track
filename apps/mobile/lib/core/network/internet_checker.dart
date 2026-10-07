import 'package:subscription_track/core/network/internet_checker_stub.dart'
    if (dart.library.io) 'package:subscription_track/core/network/internet_checker_io.dart'
    if (dart.library.html) 'package:subscription_track/core/network/internet_checker_web.dart';

abstract class InternetChecker {
  Future<bool> hasInternet();
}

InternetChecker createInternetChecker() => getPlatformInternetChecker();
