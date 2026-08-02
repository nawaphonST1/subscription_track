import 'package:mocktail/mocktail.dart';
import 'package:subscription_track/services/auth_service.dart';
import 'package:subscription_track/services/storage_service.dart';
import 'package:subscription_track/services/subscription_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockStorageService extends Mock implements StorageService {}

class MockSubscriptionService extends Mock implements SubscriptionService {}
