import 'package:mocktail/mocktail.dart';
import 'package:subscription_track/features/auth/data/auth_service.dart';
import 'package:subscription_track/services/storage_service.dart';
import 'package:subscription_track/services/subscription_service.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription_repository.dart';

class MockAuthService extends Mock implements AuthService {}

class MockStorageService extends Mock implements StorageService {}

class MockSubscriptionService extends Mock implements SubscriptionService {}

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}
