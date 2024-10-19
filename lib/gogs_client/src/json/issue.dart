part of gogs.client;

class Issue {
  Issue({
    required this.id,
    required this.number,
    required this.state,
    required this.title,
    required this.body,
    required this.user,
    this.labels,
    this.assignee,
    this.milestone,
    this.comments = 0,
    this.pullRequest,
    this.createdAt,
    this.updatedAt,
  });
  final int id;
  final int number;
  final String state;
  final String title;
  final String body;
  final User user;
  final List<IssueLabel>? labels;
  final User? assignee;
  final IssueMilestone? milestone;
  final int comments;
  final dynamic pullRequest;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Issue.fromJson(Map<String, dynamic> json) => Issue(
        id: json["id"] ?? 0,
        number: json["number"] ?? 0,
        state: json["state"] ?? '',
        title: json["title"] ?? '',
        body: json["body"] ?? '',
        user: User.fromJson(json["user"] ?? {}),
        labels: json["labels"] == null
            ? []
            : List<IssueLabel>.from(
                json["labels"]!.map((x) => IssueLabel.fromJson(x))),
        assignee:
            json["assignee"] == null ? null : User.fromJson(json["assignee"]),
        milestone: json["milestone"] == null
            ? null
            : IssueMilestone.fromJson(json["milestone"]),
        comments: json["comments"] ?? 0,
        pullRequest: json["pull_request"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
      );

  // Map<String, dynamic> toJson() => {
  //       "id": id,
  //       "number": number,
  //       "state": state,
  //       "title": title,
  //       "body": body,
  //       "user": user.toJson(),
  //       "labels": labels == null
  //           ? []
  //           : List<dynamic>.from(labels!.map((x) => x.toJson())),
  //       "assignee": assignee?.toJson(),
  //       "milestone": milestone?.toJson(),
  //       "comments": comments,
  //       "pull_request": pullRequest,
  //       "created_at": createdAt?.toIso8601String(),
  //       "updated_at": updatedAt?.toIso8601String(),
  //     };

  bool get isOpen => state == "open";

  factory Issue.newEmptyFromId(int id) => Issue(
      id: id,
      number: 0,
      state: '',
      title: '',
      body: '',
      user: User.fromJson({}));

  Issue copyWith({
    int? id,
    int? number,
    String? state,
    String? title,
    String? body,
    User? user,
    List<IssueLabel>? labels,
    User? assignee,
    IssueMilestone? milestone,
    int? comments,
    dynamic pullRequest,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Issue(
        id: id ?? this.id,
        number: number ?? this.number,
        state: state ?? this.state,
        title: title ?? this.title,
        body: body ?? this.body,
        user: user ?? this.user,
        labels: labels ?? this.labels,
        assignee: assignee ?? this.assignee,
        milestone: milestone ?? this.milestone,
        comments: comments ?? this.comments,
        pullRequest: pullRequest ?? this.pullRequest,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static IssueList fromJsonList(dynamic data) =>
      IssueList.from(data.map((x) => Issue.fromJson(x)));
}

typedef IssueList = List<Issue>;

// class IssueAssignee {
//   IssueAssignee({
//     required this.id,
//     required this.username,
//     required this.fullName,
//     required this.email,
//     required this.avatarUrl,
//   });
//   final int id;
//   final String username;
//   final String fullName;
//   final String email;
//   final String avatarUrl;
//
//   factory IssueAssignee.fromJson(Map<String, dynamic> json) => IssueAssignee(
//         id: json["id"] ?? 0,
//         username: json["username"] ?? '',
//         fullName: json["full_name"] ?? '',
//         email: json["email"] ?? '',
//         avatarUrl: json["avatar_url"] ?? '',
//       );
//
//   Map<String, dynamic> toJson() => {
//         "id": id,
//         "username": username,
//         "full_name": fullName,
//         "email": email,
//         "avatar_url": avatarUrl,
//       };
// }

class IssueLabel {
  IssueLabel({
    required this.id,
    required this.name,
    required this.color,
  });
  final int id;
  final String name;
  final String color;

  factory IssueLabel.fromJson(Map<String, dynamic> json) => IssueLabel(
        id: json["id"] ?? 0,
        name: json["name"] ?? '',
        color: json["color"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "color": color,
      };

  static IssueLabelList fromJsonList(dynamic data) =>
      IssueLabelList.from(data.map((x) => IssueLabel.fromJson(x)));
}

typedef IssueLabelList = List<IssueLabel>;

class IssueMilestone {
  IssueMilestone({
    required this.id,
    required this.state,
    required this.title,
    required this.description,
    required this.openIssues,
    required this.closedIssues,
    this.closedAt,
    this.dueOn,
  });
  final int id;
  final String state;
  final String title;
  final String description;
  final int openIssues;
  final int closedIssues;
  final dynamic closedAt;
  final dynamic dueOn;

  factory IssueMilestone.fromJson(Map<String, dynamic> json) => IssueMilestone(
        id: json["id"] ?? 0,
        state: json["state"] ?? '',
        title: json["title"] ?? '',
        description: json["description"] ?? '',
        openIssues: json["open_issues"] ?? 0,
        closedIssues: json["closed_issues"] ?? 0,
        closedAt: json["closed_at"],
        dueOn: json["due_on"],
      );

  // Map<String, dynamic> toJson() => {
  //       "id": id,
  //       "state": state,
  //       "title": title,
  //       "description": description,
  //       "open_issues": openIssues,
  //       "closed_issues": closedIssues,
  //       "closed_at": closedAt,
  //       "due_on": dueOn,
  //     };
}

class CreateIssue {
  CreateIssue({
    required this.title,
    required this.body,
    required this.assignee,
    this.milestone,
    this.labels,
  });

  final String title;
  final String body;
  final String assignee;
  final int? milestone;
  final List<String>? labels;

  factory CreateIssue.fromJson(Map<String, dynamic> json) => CreateIssue(
        title: json["title"],
        body: json["body"],
        assignee: json["assignee"],
        milestone: json["milestone"],
        labels: json["labels"] != null
            ? List<String>.from(json["labels"].map((x) => x))
            : null,
      );

  Map<String, dynamic> toJson() => {
        "title": title,
        "body": body,
        "assignee": assignee,
        "milestone": milestone,
        "labels":
            labels != null ? List<dynamic>.from(labels!.map((x) => x)) : null,
      };
}
