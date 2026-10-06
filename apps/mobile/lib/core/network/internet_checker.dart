import 'internet_checker_stub.dart'
    if (dart.library.io) 'internet_checker_io.dart'
    if (dart.library.html) 'internet_checker_web.dart';

abstract class InternetChecker {
  Future<bool> hasInternet();
}

InternetChecker createInternetChecker() => getPlatformInternetChecker();
