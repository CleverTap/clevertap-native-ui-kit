/// Order-independent hash for a nullable map — pairs with `mapEquals`.
/// Shared by the model classes' `hashCode` implementations.
int ndMapHash(Map<Object?, Object?>? map) {
  if (map == null) return null.hashCode;
  var h = 0;
  for (final e in map.entries) {
    h ^= Object.hash(e.key, e.value);
  }
  return Object.hash(map.length, h);
}
