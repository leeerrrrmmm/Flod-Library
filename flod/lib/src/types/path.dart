/// Type alias for a path.
typedef Path = List<dynamic>;

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
