/// 12.2 Chain Optimization — helpers that reduce allocations in copyWith chains.
abstract final class ChainUtils {
  /// Appends [item] to [list] with minimal allocation.
  static List<T> append<T>(List<T> list, T item) {
    if (list.isEmpty) return [item];
    return [...list, item];
  }

  /// Returns [next] when all fields are unchanged, otherwise [create].
  static R identityCopy<R>({
    required bool unchanged,
    required R current,
    required R Function() create,
  }) {
    return unchanged ? current : create();
  }

  static bool listsEqual<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
