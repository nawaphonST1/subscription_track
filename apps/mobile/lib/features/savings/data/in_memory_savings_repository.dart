import 'package:subscription_track/features/savings/data/remote_savings_repository.dart';
import 'package:subscription_track/features/savings/domain/savings_optimizer_report.dart';
import 'package:subscription_track/features/savings/domain/savings_repository.dart';

/// Repository สำหรับทดสอบ UI แบบออฟไลน์โดยไม่ต้องเชื่อมต่อ API จริง
final class InMemorySavingsRepository implements SavingsRepository {
  InMemorySavingsRepository({
    this.ioDelay = Duration.zero,
    this.report,
    this.shouldFailBatchCancel = false,
    this.batchCancelError,
  });

  final Duration ioDelay;
  final SavingsOptimizerReport? report;
  final bool shouldFailBatchCancel;
  final Exception? batchCancelError;

  @override
  Future<SavingsOptimizerReport> getOptimizerReport() async {
    if (ioDelay > Duration.zero) {
      await Future<void>.delayed(ioDelay);
    }
    if (report != null) {
      return report!;
    }
    return const SavingsOptimizerReport(
      unusedSubscriptionsCount: 0,
      totalMonthlySavings: 0,
      totalYearlySavingsProjection: 0,
      recommendedCancellations: [],
    );
  }

  @override
  Future<BatchCancelResult> batchCancel({
    required List<String> subscriptionIds,
    required String pin,
  }) async {
    if (ioDelay > Duration.zero) {
      await Future<void>.delayed(ioDelay);
    }
    if (batchCancelError != null) {
      throw batchCancelError!;
    }
    if (shouldFailBatchCancel) {
      throw const SavingsException('Failed to cancel subscriptions');
    }
    return BatchCancelResult(
      message: 'Subscriptions successfully cancelled',
      cancelledCount: subscriptionIds.length,
      totalYearlySavingsUnlocked: 0,
    );
  }
}
