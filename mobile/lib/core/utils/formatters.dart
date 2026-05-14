import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final NumberFormat kCurrency =
    NumberFormat.currency(locale: 'pt_BR', symbol: 'UP\$', decimalDigits: 2);

String formatCnpj(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  final buf = StringBuffer();
  for (var i = 0; i < digits.length && i < 14; i++) {
    if (i == 2 || i == 5) buf.write('.');
    if (i == 8) buf.write('/');
    if (i == 12) buf.write('-');
    buf.write(digits[i]);
  }
  return buf.toString();
}

String formatPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  if (digits.length <= 2) return '($digits';
  if (digits.length <= 6) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2)}';
  }
  if (digits.length <= 10) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
  }
  return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7, 11)}';
}

class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatCnpj(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatPhone(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final value = int.parse(digits) / 100.0;
    final formatted =
        NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2)
            .format(value)
            .trim();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

int parseMoneyCents(String text) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 0;
  return int.parse(digits);
}

String formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final local = date.toLocal();
  final diff =
      DateTime(now.year, now.month, now.day).difference(DateTime(local.year, local.month, local.day)).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Ontem';
  if (diff < 7) return DateFormat('EEEE', 'pt_BR').format(local);
  return DateFormat("d 'de' MMM", 'pt_BR').format(local);
}
