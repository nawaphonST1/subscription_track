import 'package:subscription_track/features/savings/domain/savings_optimizer_report.dart';

abstract interface class SavingsRepository {
  Future<SavingsOptimizerReport> getOptimizerReport();

  Future<BatchCancelResult> batchCancel({
    required List<String> subscriptionIds,
    required String pin,
  });
}
