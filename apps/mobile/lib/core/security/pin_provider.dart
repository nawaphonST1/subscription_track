import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/security/pin_repository.dart';
import 'package:subscription_track/core/security/remote_pin_repository.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';

final pinRepositoryProvider = Provider<PinRepository>((ref) {
  return RemotePinRepository(
    client: ref.watch(authenticatedHttpClientProvider),
  );
});

