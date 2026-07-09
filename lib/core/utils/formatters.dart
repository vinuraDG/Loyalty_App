// lib/core/utils/formatters.dart

/// Formats an integer point value with thousands separator, no decimals,
/// e.g. 12345 -> '12,345', 1000 -> '1,000'.
String formatPoints(int value) {
  final isNegative = value < 0;
  final str = value.abs().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
    buffer.write(str[i]);
  }
  return isNegative ? '-${buffer.toString()}' : buffer.toString();
}

/// Formats a numeric value as a thousands-separated string with two
/// decimal places, e.g. 1784.8 -> '1,784.80', 13800 -> '13,800.00'.
String formatAmount(num value) {
  final isNegative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final decPart = parts[1];

  final buffer = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    final posFromEnd = intPart.length - i;
    if (i != 0 && posFromEnd % 3 == 0) buffer.write(',');
    buffer.write(intPart[i]);
  }

  return '${isNegative ? '-' : ''}$buffer.$decPart';
}