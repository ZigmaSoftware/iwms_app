import 'dart:math';

/// Generates short-lived unique ids to correlate operator submissions.
class OperatorUniqueIdService {
  static const _chars = 'abcdefghijklmnopqrstuvwxyz0123456789';

  static String generateScreenId() {
    final rand = Random.secure();
    final now = DateTime.now();
    final year = now.year.toString();
    final secondPart = now.second.toString().padLeft(2, '0');
    final milliPart = now.millisecond.toString().padLeft(3, '0');
    final randomStr =
        List.generate(10, (_) => _chars[rand.nextInt(_chars.length)]).join();

    return 'scr$year'
        's$secondPart'
        'm$milliPart'
        '$randomStr';
  }
}
