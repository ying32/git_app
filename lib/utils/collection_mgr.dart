import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 添加到收藏中的项目信息
class CollectionItem {
  const CollectionItem({
    required this.id,
    required this.repoName,
    required this.ownerName,
    required this.avatarUrl,
  });

  /// 仓库id
  final int id;

  /// 仓库名
  final String repoName;

  /// 仓库所有者
  final String ownerName;

  /// 所有者头像url
  final String avatarUrl;

  CollectionItem copyWith(
          int? id, String? repoName, String? ownerName, String? avatarUrl) =>
      CollectionItem(
        id: id ?? this.id,
        repoName: repoName ?? this.repoName,
        ownerName: ownerName ?? this.ownerName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "repo_name": repoName,
        "owner_name": ownerName,
        "avatar_url": avatarUrl,
      };

  CollectionItem.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        repoName = json['repo_name'],
        ownerName = json['owner_name'],
        avatarUrl = json['avatar_url'];
}

/// 主页收藏管理
class CollectionMgr {
  CollectionMgr._();

  static const _keyPrefix = 'my_collection';

  static final CollectionMgr _instance = CollectionMgr._();
  static CollectionMgr get instance => _instance;

  final List<CollectionItem> items = [];

  String _key = '';

  /// 重新添加
  void reAddAll(Iterable<CollectionItem> iterable) {
    items.clear();
    items.addAll(iterable);
  }

  /// 重新加载
  Future<bool> reLoad(String key) async {
    items.clear();
    return load(key);
  }

  /// 加载对应用户的
  Future<bool> load(String key) async {
    if (key.isEmpty) return false;
    _key = "${_keyPrefix}_$key";
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(_key);
    if (text == null) return false;
    reAddAll(jsonDecode(text)
        .map<CollectionItem>((x) => CollectionItem.fromJson(x)));
    return true;
  }

  /// 保存当前用户的
  Future<bool> save() async {
    if (_key.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_key, jsonEncode(items));
    return true;
  }
}
