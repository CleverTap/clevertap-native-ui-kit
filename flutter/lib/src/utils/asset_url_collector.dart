/// Pure utility that walks a raw CleverTap Native Display (ND) display-unit
/// JSON payload (or a decoded config map) and returns every http(s) asset URL
/// it references.
///
/// Asset URLs in an ND config live in a handful of well-known places:
///   * element `bindings.url`           — IMAGE and VIDEO element sources
///   * style `background` → `url`        — `{"type":"image", "url": ...}`
///     (including nested `layered` → `layers[].url`)
///   * theme / styleClass styles         — same `background.url` shape
///
/// Rather than depend on the typed model (which only exposes a subset of
/// these and would miss payloads parsed via different strategies), this walks
/// the raw JSON tree. It collects:
///   * any `"url"` string value that is an http(s) URL, and
///   * any `"background"` object (recursively) whose `type == "image"` url.
///
/// Template URLs (containing `{{ ... }}`) and non-http values are skipped —
/// they are not downloadable assets. The result preserves first-seen order
/// and is de-duplicated.
///
/// This is deliberately dependency-free (no Flutter imports) so it can run in
/// a parse isolate and be unit-tested in plain Dart.
class AssetUrlCollector {
  const AssetUrlCollector._();

  /// Keys whose string value, when an http(s) URL, is treated as an asset.
  /// `url` covers IMAGE/VIDEO bindings and `background` image urls.
  static const _assetUrlKeys = {'url'};

  /// Walks [raw] (a decoded JSON map or list, e.g. a single display unit or a
  /// full config) and returns every distinct http(s) asset URL, in first-seen
  /// order.
  static List<String> collect(Object? raw) {
    final seen = <String>{};
    final result = <String>[];
    _walk(raw, seen, result);
    return result;
  }

  /// Convenience: union the URLs from a list of raw units into one ordered,
  /// de-duplicated list.
  static List<String> collectAll(Iterable<Object?> rawUnits) {
    final seen = <String>{};
    final result = <String>[];
    for (final unit in rawUnits) {
      _walk(unit, seen, result);
    }
    return result;
  }

  static void _walk(Object? node, Set<String> seen, List<String> out) {
    if (node is Map) {
      node.forEach((key, value) {
        if (value is String && _assetUrlKeys.contains(key.toString())) {
          _maybeAdd(value, seen, out);
        } else {
          _walk(value, seen, out);
        }
      });
    } else if (node is List) {
      for (final item in node) {
        _walk(item, seen, out);
      }
    }
  }

  static void _maybeAdd(String value, Set<String> seen, List<String> out) {
    final v = value.trim();
    if (v.isEmpty) return;
    // Skip unresolved template bindings — not downloadable.
    if (v.contains('{{')) return;
    if (!(v.startsWith('http://') || v.startsWith('https://'))) return;
    if (seen.add(v)) out.add(v);
  }
}
