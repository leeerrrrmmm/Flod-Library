/// Type alias for a path.
typedef Path = List<String>;

/// Extension method to convert a path to a readable string.
extension PathX on Path {
  String toReadable() {
    final buffer = StringBuffer();

    for (final part in this) {
      if (part is int) {
        buffer.write('[$part]');
      } else {
        if (buffer.isNotEmpty) buffer.write('.');
        buffer.write(part);
      }
    }

    return buffer.toString();
  }
}

/// Function to format a path to a readable string.
String formatPath(Path path) {
  final buffer = StringBuffer();

  for (final part in path) {
    if (part is int) {
      buffer.write('[$part]');
    } else {
      if (buffer.isNotEmpty) buffer.write('.');
      buffer.write(part);
    }
  }

  return buffer.toString();
}
