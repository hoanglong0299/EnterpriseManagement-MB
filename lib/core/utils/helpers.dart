import 'package:intl/intl.dart';

DateTime? parseDateTime(String? value) {
  if (value == null) return null;
  return DateTime.parse(value);
}

String formatDate(DateTime? value) {
  if (value == null) return '--';
  return DateFormat('dd/MM/yyyy').format(value);
}

String formatTime(DateTime? value) {
  if (value == null) return '--:--';
  return DateFormat('HH:mm').format(value);
}

String formatDateTime(DateTime? value) {
  if (value == null) return '--';
  return DateFormat('dd/MM/yyyy HH:mm').format(value);
}

String isoDate(DateTime value) {
  return DateFormat('yyyy-MM-dd').format(value);
}