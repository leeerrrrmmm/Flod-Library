import 'package:meta/meta.dart';

@immutable
class FlodPath {
  final List<Object> segments;

  const FlodPath(this.segments);
  const FlodPath.empty() : segments = const [];

  /// Fast, safe child path creation (for O(1) tree traversal)
  FlodPath append(Object segment) {
    assert(
      segment is String || segment is int,
      'Path segment must be String or int',
    );
    return FlodPath([...segments, segment]);
  }

  /// .toReadable() compatible with stress tests and JSON notation
  String toReadable() {
    if (segments.isEmpty) return '_root_';
    final buffer = StringBuffer();

    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (seg is int) {
        buffer.write('[$seg]');
      } else {
        // Add a dot if this is not the first segment and there was no root before,
        // or if a string key follows an array index: users[0].name
        if (i > 0) {
          buffer.write('.');
        }
        buffer.write(seg);
      }
    }
    return buffer.toString();
  }

  // Fast component-wise comparison without external dependencies
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

  // Fast, reliable hash code (John Bloch's algorithm)
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
