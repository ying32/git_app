import 'package:flutter/cupertino.dart';
import 'package:git_app/gogs_client/gogs_client.dart';

// class CommentItemData {
//   CommentItemData(this.comment, [this.isIssue = false]);
//   final IssueComment comment;
//   final IssueCommentList subStatus = [];
//   final bool isIssue;
//
//   CommentItemData copyWith(
//       {IssueComment? comment, IssueCommentList? subStatus, bool? isIssue}) {
//     final res = CommentItemData(
//       comment ?? this.comment,
//       isIssue ?? this.isIssue,
//     );
//     if (subStatus != null) res.subStatus.addAll(subStatus);
//     return res;
//   }
// }

/// 评论数据模型
class IssueCommentModel extends ChangeNotifier {
  /// 当前issue
  late Issue _issue;
  Issue get issue => _issue;
  set issue(Issue value) {
    _issue = value;
    notifyListeners();
  }

  /// 评论列表
  final List<IssueComment> _comments = [];
  List<IssueComment> get comments => _comments;
  void addComment(IssueComment data) {
    _comments.add(data);
    notifyListeners();
  }

  void addAllComment(IssueCommentList data) {
    _comments.addAll(data);
    notifyListeners();
  }

  void updateComment(int id, IssueComment newComment) {
    final idx = _comments.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _comments[idx] = _comments[idx]
          .copyWith(body: newComment.body, updatedAt: newComment.updatedAt);
      notifyListeners();
    }
  }

  /// 当前仓库
  late Repository repo;
}
