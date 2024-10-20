part of gogs.client;

class IssueComment {
  IssueComment({
    required this.id,
    required this.user,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.type = "",
  });

  final int id;
  final User user;
  final String body;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String type;

  factory IssueComment.fromJson(Map<String, dynamic> json) => IssueComment(
        id: json["id"] ?? 0,
        user: User.fromJson(json["user"] ?? {}),
        body: json["body"] ?? '',
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        // 补丁或者gitea
        type: json["type"] ?? '',
      );

  // Map<String, dynamic> toJson() => {
  //       "id": id,
  //       "user": user.toJson(),
  //       "body": body,
  //       "created_at": createdAt?.toIso8601String(),
  //       "updated_at": updatedAt?.toIso8601String(),
  //       "type": type,
  //     };

  IssueComment copyWith({
    int? id,
    User? user,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? type,
  }) =>
      IssueComment(
        id: id ?? this.id,
        user: user ?? this.user,
        body: body ?? this.body,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        type: type ?? this.type,
      );

  bool get bodyIsHtml => body.startsWith('<a');

  static IssueCommentList fromJsonList(dynamic data) =>
      IssueCommentList.from(data.map((x) => IssueComment.fromJson(x)));
}

typedef IssueCommentList = List<IssueComment>;

//todo: 待处理
class IssueCommentTimeline {}
