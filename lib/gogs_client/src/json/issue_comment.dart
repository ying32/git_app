part of gogs.client;

class IssueComment {
  IssueComment({
    required this.id,
    required this.user,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.type = "",
    this.timeline,
    this.assignee,
  });

  final int id;
  final User user;
  final String body;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String type;

  /// 这是应用的一个补丁
  final IssueCommentTimeline? timeline;
  final User? assignee;

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
        type: json["type"] ?? _tryGetType(json), // 默认个comment吧
        // 时间线的
        timeline: IssueCommentTimeline.fromJson(json),
        assignee:
            json['assignee'] != null ? User.fromJson(json['assignee']) : null,
      );

  static String _tryGetType(Map<String, dynamic> json) {
    final String body = json['body'] ?? '';
    if (body.isNotEmpty) {
      if (body.startsWith("<")) {
        return 'commit_ref';
      } else {
        return 'comment';
      }
    }
    return '';
  }

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
    IssueCommentTimeline? timeline,
  }) =>
      IssueComment(
        id: id ?? this.id,
        user: user ?? this.user,
        body: body ?? this.body,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        type: type ?? this.type,
        timeline: timeline ?? this.timeline,
      );

  bool get bodyIsHtml => body.startsWith('<a');

  static IssueCommentList fromJsonList(dynamic data) =>
      IssueCommentList.from(data.map((x) => IssueComment.fromJson(x)));
}

typedef IssueCommentList = List<IssueComment>;

//todo: 待处理
class IssueCommentTimeline {
  IssueCommentTimeline({
    this.oldTitle = '',
    this.newTitle = '',
    this.oldRef = '',
    this.newRef = '',
    this.label,
  });

  final String oldTitle;
  final String newTitle;
  final String oldRef;
  final String newRef;

  final IssueLabel? label;

  factory IssueCommentTimeline.fromJson(Map<String, dynamic> json) =>
      IssueCommentTimeline(
        oldTitle: json['old_title'] ?? '',
        newTitle: json['new_title'] ?? '',
        oldRef: json['old_ref'] ?? '',
        newRef: json['new_ref'] ?? '',
        label:
            json['label'] != null ? IssueLabel.fromJson(json['label']) : null,
      );
}
