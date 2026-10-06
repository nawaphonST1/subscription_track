import 'package:subscription_track/features/subscriptions/domain/preset_package.dart';

abstract interface class PackageRepository {
  Future<List<PresetPackage>> getPackages({String? category, String? search});
}
