part of gogs.client;

class Repository {
  final int id;
  final User owner;
  final String name;
  final String fullName;
  final String description;
  final bool private;
  final bool fork;
  final dynamic parent;
  final bool empty;
  final bool mirror;
  final int? size;
  final String? htmlUrl;
  final String? sshUrl;
  final String? cloneUrl;
  final String website;
  final int starsCount;
  final int forksCount;
  final int watchersCount;
  final int openIssuesCount;
  final String defaultBranch;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final RepositoryPermissions? permissions;

  final int openPullsCount;
  final bool isWatching;
  final bool isStaring;
  final int branchCount;
  final int commitsCount;
  final RepositoryReadMe? readMe;
  final String? license;

  Repository({
    required this.id,
    required this.owner,
    required this.name,
    required this.fullName,
    required this.description,
    this.private = false,
    this.fork = false,
    this.parent,
    this.empty = false,
    this.mirror = false,
    this.size,
    this.htmlUrl,
    this.sshUrl,
    this.cloneUrl,
    this.website = '',
    this.starsCount = 0,
    this.forksCount = 0,
    this.watchersCount = 0,
    this.openIssuesCount = 0,
    required this.defaultBranch,
    this.createdAt,
    this.updatedAt,
    this.permissions,
    //new
    this.openPullsCount = 0,
    this.isWatching = false,
    this.isStaring = false,
    this.branchCount = 0,
    this.commitsCount = 0,
    this.readMe,
    this.license,
  });

  factory Repository.fromJson(Map<String, dynamic> json) => Repository(
        id: json["id"] ?? 0,
        owner: User.fromJson(json["owner"] ?? {}),
        name: json["name"] ?? '',
        fullName: json["full_name"] ?? '',
        description: json["description"] ?? '',
        private: json["private"] ?? false,
        fork: json["fork"] ?? false,
        parent: json["parent"],
        empty: json["empty"] ?? false,
        mirror: json["mirror"] ?? false,
        size: json["size"],
        htmlUrl: json["html_url"],
        sshUrl: json["ssh_url"],
        cloneUrl: json["clone_url"],
        website: json["website"] ?? '',
        starsCount: json["stars_count"] ?? 0,
        forksCount: json["forks_count"] ?? 0,
        watchersCount: json["watchers_count"] ?? 0,
        openIssuesCount: json["open_issues_count"] ?? 0,
        defaultBranch: json["default_branch"] ?? '',
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        permissions: json["permissions"] == null
            ? null
            : RepositoryPermissions.fromJson(json["permissions"]),
        // new
        openPullsCount: json["open_pulls_count"] ?? 0,
        isWatching: json["is_watching"] ?? false,
        isStaring: json["is_staring"] ?? false,
        branchCount: json["branch_count"] ?? 0,
        commitsCount: json["commits_count"] ?? 0,
        readMe: json["read_me"] == null
            ? null
            : RepositoryReadMe.fromJson(json["read_me"]),
        license: json['license'],
      );

  /// 生成一个只有仓库名和所有者名+头像信息的
  factory Repository.fromNameAndOwner(
          String repoName, String userName, String avatarUrl) =>
      Repository(
          id: 0,
          owner: User.fromNameAndHeadImage(userName, avatarUrl),
          name: repoName,
          fullName: "$userName/$repoName",
          description: '',
          defaultBranch: '');
  // Map<String, dynamic> toJson() => {
  //       "id": id,
  //       "owner": owner.toJson(),
  //       "name": name,
  //       "full_name": fullName,
  //       "description": description,
  //       "private": private,
  //       "fork": fork,
  //       "parent": parent,
  //       "empty": empty,
  //       "mirror": mirror,
  //       "size": size,
  //       "html_url": htmlUrl,
  //       "ssh_url": sshUrl,
  //       "clone_url": cloneUrl,
  //       "website": website,
  //       "stars_count": starsCount,
  //       "forks_count": forksCount,
  //       "watchers_count": watchersCount,
  //       "open_issues_count": openIssuesCount,
  //       "default_branch": defaultBranch,
  //       "created_at": createdAt?.toIso8601String(),
  //       "updated_at": updatedAt?.toIso8601String(),
  //       "permissions": permissions?.toJson(),
  //       // new
  //       "open_pulls_count": openPullsCount,
  //       "is_watching": isWatching,
  //       "is_staring": isStaring,
  //       "branch_count": branchCount,
  //       "commits_count": commitsCount,
  //       "read_me": readMe?.toJson(),
  //       "license": license,
  //     };

  String get parentName => parentRepo?.fullName ?? '';

  Repository? get parentRepo {
    if (parent == null) return null;
    if (parent is! Map) return null;
    return Repository.fromJson(parent);
  }

  static RepositoryList fromJsonList(dynamic data) =>
      RepositoryList.from(data.map((x) => Repository.fromJson(x)));
}

typedef RepositoryList = List<Repository>;

class RepositoryPermissions {
  final bool? admin;
  final bool? push;
  final bool? pull;

  RepositoryPermissions({
    this.admin,
    this.push,
    this.pull,
  });

  RepositoryPermissions copyWith({
    bool? admin,
    bool? push,
    bool? pull,
  }) =>
      RepositoryPermissions(
        admin: admin ?? this.admin,
        push: push ?? this.push,
        pull: pull ?? this.pull,
      );

  factory RepositoryPermissions.fromJson(Map<String, dynamic> json) =>
      RepositoryPermissions(
        admin: json["admin"],
        push: json["push"],
        pull: json["pull"],
      );

  // Map<String, dynamic> toJson() => {
  //       "admin": admin,
  //       "push": push,
  //       "pull": pull,
  //     };
}

class RepositoryReadMe {
  const RepositoryReadMe({
    this.content = "",
    this.fileName = "",
  });

  final String content;
  final String fileName;

  factory RepositoryReadMe.fromJson(Map<String, dynamic> json) =>
      RepositoryReadMe(
        content: json["content"] ?? '',
        fileName: json["file_name"] ?? '',
      );

  // Map<String, dynamic> toJson() => {
  //       "content": content,
  //       "file_name": fileName,
  //     };
}

class SearchRepositories {
  SearchRepositories({required this.ok, required this.data});
  final bool ok;
  final RepositoryList? data;

  factory SearchRepositories.fromJson(Map<String, dynamic> json) =>
      SearchRepositories(
        ok: json["ok"] ?? false,
        data: json["data"] != null
            ? Repository.fromJsonList(json["data"]!)
            : null,
      );
}
