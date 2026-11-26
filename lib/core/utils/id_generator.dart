import 'dart:math';

/// Lightweight collision-resistant ID generator for local-first entities.
abstract final class IdGenerator {
  static final Random _random = Random();
  static int _counter = 0;

  static String next([String prefix = 'fx']) {
    _counter = (_counter + 1) % 1000000;
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rand = _random.nextInt(0xFFFFFF).toRadixString(36).padLeft(5, '0');
    return '${prefix}_${micros}_${_counter.toRadixString(36)}_$rand';
  }
}
