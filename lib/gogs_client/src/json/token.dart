part of gogs.client;

/// User的token列表
class UserToken {
  UserToken({
    required this.name,
    required this.sha1,
  });

  /// 别名
  final String name;

  /// token值
  final String sha1;

  factory UserToken.fromJson(Map<String, dynamic> json) => UserToken(
        name: json["name"] ?? '',
        sha1: json["sha1"] ?? '',
      );

  // Map<String, dynamic> toJson() => {
  //       "name": name,
  //       "sha1": sha1,
  //     };

  /// 解析一个list
  static UserTokenList fromJsonList(dynamic data) =>
      UserTokenList.from(data.map((x) => UserToken.fromJson(x)));
}

typedef UserTokenList = List<UserToken>;
