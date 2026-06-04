class VersionCompare {
  static List<int> _parts(String v) {
    return v
        .replaceFirst(RegExp(r'^v'), '')
        .split(RegExp(r'[.+]'))
        .map((x) => int.tryParse(x.replaceAll(RegExp(r'\D'), '')) ?? 0)
        .toList();
  }

  static int compare(String a, String b) {
    final pa = _parts(a);
    final pb = _parts(b);
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final da = i < pa.length ? pa[i] : 0;
      final db = i < pb.length ? pb[i] : 0;
      if (da < db) return -1;
      if (da > db) return 1;
    }
    return 0;
  }

  static bool equals(String a, String b) => compare(a, b) == 0;
}
