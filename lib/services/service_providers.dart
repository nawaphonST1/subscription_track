import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:subscription_track/features/auth/data/auth_service.dart';
import 'package:subscription_track/services/storage_service.dart';
import 'package:subscription_track/services/subscription_service.dart';

part 'service_providers.g.dart';

@riverpod
StorageService storageService(Ref ref) => StorageService();

@riverpod
AuthService authService(Ref ref) => AuthService();

@riverpod
SubscriptionService subscriptionService(Ref ref) => SubscriptionService();
