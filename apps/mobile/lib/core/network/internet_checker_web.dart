// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:subscription_track/core/network/internet_checker.dart';

class WebInternetChecker implements InternetChecker {
  const WebInternetChecker();

  @override
  Future<bool> hasInternet() async {
    try {
      return html.window.navigator.onLine ?? true;
    } catch (_) {
      return true;
    }
  }
}

InternetChecker getPlatformInternetChecker() => const WebInternetChecker();
