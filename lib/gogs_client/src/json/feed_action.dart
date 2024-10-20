part of gogs.client;

class FeedAction {
  FeedAction({
    required this.id,
    required this.opType,
    required this.actUser,
    required this.repo,
    required this.refName,
    required this.isPrivate,
    required this.createdAt,
    required this.content,
    required this.issueTitle,
    required this.issueId,
  });

  final int id;
  final String opType;
  final User actUser;
  final Repository repo;
  final String refName;
  final bool isPrivate;
  final DateTime createdAt;
  final String content;
  final String issueTitle;
  final int issueId;

  /// 内容不一定为文本，有markdown, json啥的
  ActionContent? _jsonContent;
  ActionContent? get jsonContent {
    if (_jsonContent == null) {
      if (content.isNotEmpty && content.startsWith("{")) {
        _jsonContent = ActionContent.fromJson(jsonDecode(content));
      }
    }
    return _jsonContent;
  }

  static int _parseIssueId(String? text) {
    if (text != null) {
      final idx = text.indexOf("|");
      if (idx != -1) {
        return int.tryParse(text.substring(0, idx)) ?? 0;
      }
    }
    return 0;
  }

  static String _getContent(String? text) {
    if (text != null) {
      final idx = text.indexOf("|");
      if (idx != -1) {
        return text.substring(idx + 1);
      }
    }
    return text ?? '';
  }

  factory FeedAction.fromJson(Map<String, dynamic> json) => FeedAction(
        id: json["id"] ?? 0,
        opType: json["op_type"] ?? '',
        // gitea: act_user
        actUser: User.fromJson(json['act_user'] ?? {}),
        repo: Repository.fromJson(json["repo"] ?? {}),
        refName: json["ref_name"] ?? '',
        isPrivate: json["is_private"] ?? false,
        // gitea: created
        createdAt: DateTime.parse(json["created_at"] ?? json['created']),
        // gitea: content 1|
        content: _getContent(json["content"]),
        issueTitle: json["issue_title"] ?? '',
        // gitea: content 1|
        issueId: json['issue_id'] ?? _parseIssueId(json["content"]),
      );

  // Map<String, dynamic> toJson() => {
  //       "id": id,
  //       "op_type": opType,
  //       "committer": committer.toJson(),
  //       "repo_owner": repoOwner.toJson(),
  //       "repo": repo.toJson(),
  //       "ref_name": refName,
  //       "is_private": isPrivate,
  //       "created_at": createdAt.toIso8601String(),
  //       "content": content,
  //       "issue_title": issueTitle,
  //       "issue_id": issueId,
  //     };

  static FeedActionList fromJsonList(dynamic data) =>
      FeedActionList.from(data.map((x) => FeedAction.fromJson(x)));
}

typedef FeedActionList = List<FeedAction>;

class ActionContent {
  final int len;
  final List<ContentCommit> commits;
  final String compareUrl;

  ActionContent({
    required this.len,
    required this.commits,
    required this.compareUrl,
  });

  factory ActionContent.fromJson(Map<String, dynamic> json) => ActionContent(
        len: json["Len"],
        commits: List<ContentCommit>.from(
            json["Commits"].map((x) => ContentCommit.fromJson(x))),
        compareUrl: json["CompareURL"],
      );

  // Map<String, dynamic> toJson() => {
  //       "Len": len,
  //       "Commits": List<dynamic>.from(commits.map((x) => x.toJson())),
  //       "CompareURL": compareUrl,
  //     };
}

class ContentCommit {
  ContentCommit({
    required this.sha1,
    required this.message,
    required this.authorEmail,
    required this.authorName,
    required this.committerEmail,
    required this.committerName,
    required this.timestamp,
  });

  final String sha1;
  final String message;
  final String authorEmail;
  final String authorName;
  final String committerEmail;
  final String committerName;
  final DateTime timestamp;

  factory ContentCommit.fromJson(Map<String, dynamic> json) => ContentCommit(
        sha1: json["Sha1"],
        message: json["Message"],
        authorEmail: json["AuthorEmail"],
        authorName: json["AuthorName"],
        committerEmail: json["CommitterEmail"],
        committerName: json["CommitterName"],
        timestamp: DateTime.parse(json["Timestamp"]),
      );

  // Map<String, dynamic> toJson() => {
  //       "Sha1": sha1,
  //       "Message": message,
  //       "AuthorEmail": authorEmail,
  //       "AuthorName": authorName,
  //       "CommitterEmail": committerEmail,
  //       "CommitterName": committerName,
  //       "Timestamp": timestamp.toIso8601String(),
  //     };
}
