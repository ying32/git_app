import 'package:flutter/cupertino.dart';
import 'package:git_app/gogs_client/gogs_client.dart';

/// 评论数据模型
class IssueCommentModel extends ChangeNotifier {
  IssueCommentModel(this._issue, this.repo);

  /// 当前仓库
  final Repository repo;

  /// 当前issue
  Issue _issue;
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

  /// 添加评论列表
  void addAllComment(IssueCommentList data) {
    _comments.addAll(data);
    notifyListeners();
  }

  /// 完成标识，只一次
  bool _firstDone = false;
  bool get firstDone => _firstDone;
  set firstDone(bool value) {
    if (value != _firstDone) {
      _firstDone = value;
      notifyListeners();
    }
  }

  /// 更新指定评论
  void updateComment(int id, IssueComment newComment) {
    final idx = _comments.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _comments[idx] = _comments[idx]
          .copyWith(body: newComment.body, updatedAt: newComment.updatedAt);
      notifyListeners();
    }
  }

  final ScrollController _controller = ScrollController();

  /// 列表滚动的控制器
  ScrollController get controller => _controller;

  void jumpStart() {
    if (controller.hasClients) {
      controller.jumpTo(0);
    }
  }

  void jumpEnd() {
    if (controller.hasClients) {
      controller.jumpTo(controller.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
