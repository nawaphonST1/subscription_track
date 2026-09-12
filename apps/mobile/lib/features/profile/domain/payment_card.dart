final class PaymentCard {
  const PaymentCard({
    required this.id,
    required this.bankName,
    required this.last4Digits,
    required this.creditLimit,
    required this.currentBalance,
    required this.colorHex,
    required this.detectedSubscriptions,
  });

  final String id;
  final String bankName;
  final String last4Digits;
  final double creditLimit;
  final double currentBalance;
  final String colorHex;
  final List<DetectedSubscription> detectedSubscriptions;
}

/// รายการเรียกเก็บซ้ำที่ระบบจำลองว่าตรวจพบจากประวัติของบัตร
final class DetectedSubscription {
  const DetectedSubscription({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.usageStatus,
    required this.confidence,
    required this.daysUntilNextBilling,
  });

  final String id;
  final String name;
  final double price;
  final String category;
  final String usageStatus;
  final int confidence;
  final int daysUntilNextBilling;
}
