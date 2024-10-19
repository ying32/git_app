part of gogs.client;

class Branch {
  Branch({
    required this.name,
    this.commit,
  });

  final String name;
  final BranchCommit? commit;

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        name: json["name"] ?? '',
        commit: json["commit"] == null
            ? null
            : BranchCommit.fromJson(json["commit"]),
      );

  // Map<String, dynamic> toJson() => {
  //       "name": name,
  //       "commit": commit?.toJson(),
  //     };

  static BranchList fromJsonList(dynamic data) =>
      BranchList.from(data.map((x) => Branch.fromJson(x)));
}

typedef BranchList = List<Branch>;

class BranchCommit {
  BranchCommit({
    required this.id,
    required this.message,
    required this.url,
    this.author,
  });

  final String id;
  final String message;
  final String url;
  final BranchCommitAuthor? author;

  factory BranchCommit.fromJson(Map<String, dynamic> json) => BranchCommit(
        id: json["id"] ?? 0,
        message: json["message"] ?? '',
        url: json["url"] ?? '',
        author: json["author"] == null
            ? null
            : BranchCommitAuthor.fromJson(json["author"]),
      );

  // Map<String, dynamic> toJson() => {
  //       "id": id,
  //       "message": message,
  //       "url": url,
  //       "author": author?.toJson(),
  //     };
}

class BranchCommitAuthor {
  BranchCommitAuthor({
    this.name,
    this.email,
    this.username,
  });

  final String? name;
  final String? email;
  final String? username;

  factory BranchCommitAuthor.fromJson(Map<String, dynamic> json) =>
      BranchCommitAuthor(
        name: json["name"],
        email: json["email"],
        username: json["username"],
      );

  // Map<String, dynamic> toJson() => {
  //       "name": name,
  //       "email": email,
  //       "username": username,
  //     };
}
