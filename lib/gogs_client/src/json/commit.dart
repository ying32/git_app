part of gogs.client;

class Commit {
  Commit({
    this.url,
    required this.sha,
    this.htmlUrl,
    required this.commit,
    required this.author,
    required this.committer,
    this.parents,
  });

  final String? url;
  final String sha;
  final String? htmlUrl;
  final CommitInfo commit;
  final User author;
  final User committer;
  final List<CommitParent>? parents;

  factory Commit.fromJson(Map<String, dynamic> json) => Commit(
        url: json["url"],
        sha: json["sha"] ?? '',
        htmlUrl: json["html_url"],
        commit: CommitInfo.fromJson(json["commit"] ?? {}),
        author: User.fromJson(json["author"] ?? {}),
        committer: User.fromJson(json["committer"] ?? {}),
        parents: json["parents"] == null
            ? []
            : List<CommitParent>.from(
                json["parents"]!.map((x) => CommitParent.fromJson(x))),
      );

  // Map<String, dynamic> toJson() => {
  //       "url": url,
  //       "sha": sha,
  //       "html_url": htmlUrl,
  //       "commit": commit.toJson(),
  //       "author": author.toJson(),
  //       "committer": committer.toJson(),
  //       "parents": parents == null
  //           ? []
  //           : List<dynamic>.from(parents!.map((x) => x.toJson())),
  //     };

  static CommitList fromJsonList(dynamic data) =>
      CommitList.from(data.map((x) => Commit.fromJson(x)));
}

typedef CommitList = List<Commit>;

// class CommitAuthor {
//   CommitAuthor({
//     required this.id,
//     required this.username,
//     this.login,
//     required this.fullName,
//     required this.email,
//     required this.avatarUrl,
//   });
//
//   final int id;
//   final String username;
//   final String? login;
//   final String fullName;
//   final String email;
//   final String avatarUrl;
//
//   factory CommitAuthor.fromJson(Map<String, dynamic> json) => CommitAuthor(
//         id: json["id"] ?? 0,
//         username: json["username"] ?? '',
//         login: json["login"],
//         fullName: json["full_name"] ?? '',
//         email: json["email"] ?? '',
//         avatarUrl: json["avatar_url"] ?? '',
//       );
//
//   // Map<String, dynamic> toJson() => {
//   //       "id": id,
//   //       "username": username,
//   //       "login": login,
//   //       "full_name": fullName,
//   //       "email": email,
//   //       "avatar_url": avatarUrl,
//   //     };
// }

class CommitInfo {
  CommitInfo({
    this.url,
    required this.author,
    required this.committer,
    required this.message,
    this.tree,
  });

  final String? url;
  final RepoCommitAuthor author;
  final RepoCommitAuthor committer;
  final String message;
  final CommitParent? tree;

  factory CommitInfo.fromJson(Map<String, dynamic> json) => CommitInfo(
        url: json["url"],
        author: RepoCommitAuthor.fromJson(json["author"] ?? {}),
        committer: RepoCommitAuthor.fromJson(json["committer"] ?? {}),
        message: json["message"] ?? '',
        tree: json["tree"] == null ? null : CommitParent.fromJson(json["tree"]),
      );

  // Map<String, dynamic> toJson() => {
  //       "url": url,
  //       "author": author.toJson(),
  //       "committer": committer.toJson(),
  //       "message": message,
  //       "tree": tree?.toJson(),
  //     };
}

class RepoCommitAuthor {
  RepoCommitAuthor({
    required this.name,
    required this.email,
    required this.date,
  });

  final String name;
  final String email;
  final DateTime? date;

  factory RepoCommitAuthor.fromJson(Map<String, dynamic> json) =>
      RepoCommitAuthor(
        name: json["name"] ?? '',
        email: json["email"] ?? '',
        date: json["date"] == null ? null : DateTime.parse(json["date"]),
      );

  // Map<String, dynamic> toJson() => {
  //       "name": name,
  //       "email": email,
  //       "date": date?.toIso8601String(),
  //     };
}

class CommitParent {
  CommitParent({
    required this.url,
    required this.sha,
  });

  final String url;
  final String sha;

  factory CommitParent.fromJson(Map<String, dynamic> json) => CommitParent(
        url: json["url"] ?? '',
        sha: json["sha"] ?? '',
      );

  // Map<String, dynamic> toJson() => {
  //       "url": url,
  //       "sha": sha,
  //     };
}
