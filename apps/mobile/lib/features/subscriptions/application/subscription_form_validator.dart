abstract final class SubscriptionFormValidator {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกชื่อบริการ';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกราคา';
    }
    final price = double.tryParse(value.trim());
    if (price == null || price <= 0) {
      return 'กรุณากรอกราคาที่มากกว่า 0';
    }
    return null;
  }
}
