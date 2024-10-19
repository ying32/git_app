part of gogs.client;

// mixin TestClientMixin {
//   void test1() {}
//
//   @protected
//   SimpleRESTClient get client;
// }
//
// class TestIssueComment with TestClientMixin {
//   TestIssueComment(this.comment);
//   final IssueComment comment;
//
//   @override
//   // TODO: implement client
//   SimpleRESTClient get client => throw UnimplementedError();
// }
//
// class TestIssue with TestClientMixin {
//   TestIssue(this.issue);
//
//   final Issue issue;
//
//   TestIssueComment newComment(IssueComment comment) =>
//       TestIssueComment(comment);
//
//   @override
//   // TODO: implement client
//   SimpleRESTClient get client => throw UnimplementedError();
// }
//
// class TestRepo with TestClientMixin {
//   TestRepo(this.repo);
//   final Repository repo;
//
//   TestIssue newIssue(Issue issue) => TestIssue(issue);
//
//   @override
//   // TODO: implement client
//   SimpleRESTClient get client => throw UnimplementedError();
// }
//
// class TestClient {
//   TestRepo newRepo(Repository repo) => TestRepo(repo);
// }
//
// // final testClient = TestClient().newRepo(repo).newIssue(issue).newComment(comment);

/// issue的评论
class GogsIssuesComment extends GogsClientBase {
  GogsIssuesComment(super.client);

  /// GET /repos/:username/:reponame/issues/:index/comments
  ///
  /// 获取指定issue下的评论列表
  FutureRESTResult<IssueCommentList?> getAll(Repository repo, Issue issue,
          {bool? force}) =>
      client.get<IssueCommentList>(
          _reposPath(repo, "/issues/${issue.number}/comments"),
          force: force,
          decoder: (data) => IssueComment.fromJsonList(data));

  /// POST /repos/:username/:reponame/issues/:index/comments
  ///
  /// 创建一个新的评论
  FutureRESTResult<IssueComment?> create(
          Repository repo, Issue issue, String body) =>
      client.post<IssueComment>(
          _reposPath(repo, "/issues/${issue.number}/comments"),
          data: {"body": body},
          decoder: (data) => IssueComment.fromJson(data));

  /// PATCH /repos/:username/:reponame/issues/:index/comments/:id
  ///
  /// 编辑指定评论内容
  FutureRESTResult<IssueComment?> edit(
          Repository repo, Issue issue, int id, String body) =>
      client.patch<IssueComment>(
          _reposPath(repo, "/issues/${issue.number}/comments/$id"),
          data: {"body": body},
          decoder: (data) => IssueComment.fromJson(data));
}

/// issues操作
class GogsIssues extends GogsClientBase {
  GogsIssues(super.client) : comment = GogsIssuesComment(client);

  /// issue评论API
  final GogsIssuesComment comment;

  /// GET /repos/:owner/:repo/issues
  ///
  /// 获取指定仓库的issue列表
  FutureRESTResult<IssueList?> getAll(Repository repo,
          {int? page, bool? isClosed, bool? force}) =>
      client.get<IssueList>(_reposPath(repo, "/issues"),
          queryParameters: {
            if (isClosed ?? false) "state": "closed",
            if (page != null) "page": page,
          },
          force: force,
          decoder: (data) => Issue.fromJsonList(data));

  /// GET /repos/:owner/:repo/issues/:index
  ///
  /// 获取指定issue信息
  ///
  /// [index]：这个参数指的不是id而是他的number，也就是显示的 #xxx 这样的，但有的又要传id奇怪的很？
  FutureRESTResult<Issue?> getIssue(Repository repo, int index,
          {bool? force}) =>
      client.get<Issue>(_reposPath(repo, "/issues/$index"),
          force: force, decoder: (data) => Issue.fromJson(data));

  /// PATCH /repos/:owner/:repo/issues/:index

  /// POST /repos/:owner/:repo/issues
  ///
  /// 创建一个新的issue
  FutureRESTResult<Issue?> create(Repository repo, CreateIssue issue) =>
      client.post<Issue>(_reposPath(repo, "/issues"),
          data: issue.toJson(), decoder: (data) => Issue.fromJson(data));

  /// PATCH /repos/:owner/:repo/issues/:index
  ///
  /// 编辑一个现有的issue内容，留空则表示没有改变
  ///
  /// [state]：open 和 closed
  FutureRESTResult<Issue?> edit(
    Repository repo,
    Issue issue, {
    String? title,
    String? body,
    String? assignee,
    int? milestone,
    bool? isOpen,
  }) =>
      client.patch<Issue>(_reposPath(repo, "/issues/${issue.number}"),
          data: {
            if (title != null) "title": title,
            if (body != null) "body": body,
            if (assignee != null) "assignee": assignee,
            if (milestone != null) "milestone": milestone,
            if (isOpen != null) "state": isOpen ? 'open' : 'closed',
          },
          decoder: (data) => Issue.fromJson(data));
}
