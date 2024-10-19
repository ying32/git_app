part of gogs.client;

class _GogsCache {
  _GogsCache();
  final _cache = <String, dynamic>{};
  T? load<T>(String key) => _cache[key];
  void store(String key, dynamic value) => _cache[key] = value;
  void remove(String key) => _cache.remove(key);

  void clear() => _cache.clear();
}
