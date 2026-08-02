import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  String toFormattedString() {
    return DateFormat('dd MMM yyyy').format(this);
  }

  String toRelativeString() {
    final now = DateTime.now();
    final diff = difference(now);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays == -1) return 'Yesterday';
    if (diff.inDays > 0) return 'In ${diff.inDays} days';
    return '${diff.inDays.abs()} days ago';
  }
}

extension DoubleExtension on double {
  String toCurrency({String symbol = '฿'}) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 0,
    );
    return formatter.format(this);
  }
}
