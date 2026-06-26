import 'package:meta/meta.dart';

@immutable
class FlodPath {
  final List<Object> segments;

  const FlodPath(this.segments);
  const FlodPath.empty() : segments = const [];

  /// Быстрое и безопасное создание дочернего пути (для O(1) переходов по дереву)
  FlodPath append(Object segment) {
    assert(
      segment is String || segment is int,
      'Path segment must be String or int',
    );
    return FlodPath([...segments, segment]);
  }

  /// Метод .toReadable() полностью совместимый со стресс-тестом и JSON-нотацией
  String toReadable() {
    if (segments.isEmpty) return '_root_';
    final buffer = StringBuffer();

    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (seg is int) {
        buffer.write('[$seg]');
      } else {
        // Ставим точку, если это не первый элемент и перед ним не было корня,
        // либо если перед строковым ключом шел индекс массива: users[0].name
        if (i > 0) {
          buffer.write('.');
        }
        buffer.write(seg);
      }
    }
    return buffer.toString();
  }

  // Быстрое покомпонентное сравнение без внешних зависимостей
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FlodPath || segments.length != other.segments.length) {
      return false;
    }

    for (var i = 0; i < segments.length; i++) {
      if (segments[i] != other.segments[i]) return false;
    }
    return true;
  }

  // Быстрый и надежный расчет хэш-кода (алгоритм Джона Блоха)
  @override
  int get hashCode {
    var hash = 17;
    for (final segment in segments) {
      hash = 31 * hash + segment.hashCode;
    }
    return hash;
  }

  @override
  String toString() => toReadable();
}
