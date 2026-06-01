import 'package:intl/intl.dart';

/// Centralized formatting so currency/date styling stays consistent.
class Fmt {
  Fmt._();

  static final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final _time = DateFormat('h:mm a');
  static final _dayTime = DateFormat('EEE, MMM d • h:mm a');
  static final _day = DateFormat('EEE, MMM d');

  static String money(num value) => _currency.format(value);
  static String time(DateTime dt) => _time.format(dt);
  static String dayTime(DateTime dt) => _dayTime.format(dt);
  static String day(DateTime dt) => _day.format(dt);

  static String km(double v) => '${v.toStringAsFixed(1)} km';
  static String minutes(double v) => '${v.round()} min';

  /// "Now", "in 12 min", "in 3 h", "Tomorrow 9:00 AM", or an absolute date.
  static String whenLabel(DateTime when) {
    final now = DateTime.now();
    final diff = when.difference(now);
    if (diff.inMinutes.abs() < 1) return 'Now';
    if (diff.isNegative) {
      final ago = now.difference(when);
      if (ago.inHours < 1) return '${ago.inMinutes} min ago';
      if (ago.inDays < 1) return '${ago.inHours} h ago';
      return _day.format(when);
    }
    if (diff.inMinutes < 60) return 'in ${diff.inMinutes} min';
    if (diff.inHours < 12) return 'in ${diff.inHours} h';
    final isTomorrow = when.day == now.add(const Duration(days: 1)).day &&
        when.month == now.month;
    if (isTomorrow) return 'Tomorrow ${_time.format(when)}';
    return _dayTime.format(when);
  }
}
