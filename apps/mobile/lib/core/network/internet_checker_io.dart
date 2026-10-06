import 'dart:io';
import 'package:subscription_track/core/network/internet_checker.dart';

class IoInternetChecker implements InternetChecker {
  const IoInternetChecker();

  @override
  Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

InternetChecker getPlatformInternetChecker() => const IoInternetChecker();
