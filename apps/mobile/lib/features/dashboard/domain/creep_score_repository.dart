import 'package:subscription_track/features/dashboard/domain/creep_score_report.dart';

abstract interface class CreepScoreRepository {
  Future<CreepScoreReport> getCreepScore();
}
