part of gogs.client;

class _CacheItem {
  const _CacheItem(this.resp, this.expired);
  final dynamic resp;
  final DateTime expired;
}

class _GogsCache {
  _GogsCache();
  final _cache = <String, dynamic>{};
  _CacheItem? load(String key) => _cache[key];

  /// 缓存缓存，5分钟后过期？？？？好像不太好吧，先这样呗
  void store(String key, dynamic value) {
    _cache[key] =
        _CacheItem(value, DateTime.now().add(const Duration(minutes: 5)));
  }

  void remove(String key) => _cache.remove(key);

  void clear() => _cache.clear();
}
