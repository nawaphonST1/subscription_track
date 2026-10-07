import 'package:subscription_track/features/dashboard/domain/creep_score_report.dart';
import 'package:subscription_track/features/dashboard/domain/creep_score_repository.dart';

/// Repository สำหรับทดสอบ UI แบบออฟไลน์โดยไม่ต้องเชื่อมต่อ API จริง
final class InMemoryCreepScoreRepository implements CreepScoreRepository {
  InMemoryCreepScoreRepository({
    this.ioDelay = Duration.zero,
    this.report,
  });

  final Duration ioDelay;
  final CreepScoreReport? report;

  @override
  Future<CreepScoreReport> getCreepScore() async {
    if (ioDelay > Duration.zero) {
      await Future<void>.delayed(ioDelay);
    }
    if (report != null) {
      return report!;
    }
    // ส่งสัญญาณ fallback ให้ provider คำนวณ client-side metrics จาก subscriptions ในเครื่อง
    throw Exception('Offline in-memory creep score fallback');
  }
}
