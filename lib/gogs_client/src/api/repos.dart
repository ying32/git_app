part of gogs.client;

/// 仓库的内容
class GogsRepoContent extends GogsClientBase {
  GogsRepoContent(super.client);

  /// GET /repos/:username/:reponame/contents/:path
  ///
  /// 获取指定[path]的列表
  FutureRESTResult<ContentList?> getAll(Repository repo, String path,
          {String? ref, bool? force}) =>
      client.get<ContentList>(_baseRepoPath(repo, "/contents/$path"),
          queryParameters: ref != null ? {"ref": ref} : null,
          force: force,
          decoder: (data) => Content.fromJsonList(data));

  /// GET /repos/:username/:reponame/raw/:ref/:path
  ///
  /// 原生内容
  FutureRESTResult<List<int>?> raw(Repository repo, String ref, String path,
          {bool? force, bool? nocache}) =>
      client.get<List<int>>(_baseRepoPath(repo, "/raw/$ref/$path"),
          force: force,
          options: Options(
              responseType: ResponseType.bytes, extra: {"nocache": nocache}));

  /// GET /repos/:username/:reponame/raw/:ref/README.md
  ///
  /// 读一个readme文件
  FutureRESTResult<List<int>?> readMeFile(Repository repo, String ref,
          {bool? force}) => // 先固定个README吧
      client.get<List<int>>(_baseRepoPath(repo, "/raw/$ref/README.md"),
          force: force, options: Options(responseType: ResponseType.bytes));
}

/// 仓库分支
class GogsRepoBranch extends GogsClientBase {
  GogsRepoBranch(super.client);

  /// GET /repos/:owner/:repo/branches
  ///
  /// 获取指定仓库的分支列表信息
  FutureRESTResult<BranchList?> getAll(Repository repo, {bool? force}) =>
      client.get<BranchList>(_baseRepoPath(repo, "/branches"),
          force: force, decoder: (data) => Branch.fromJsonList(data));

  /// GET /repos/:owner/:repo/branches/:branch
  ///
  /// 获取指定分支信息
  FutureRESTResult<Branch?> branch(Repository repo, String branchName,
          {bool? force}) =>
      client.get<Branch>(_baseRepoPath(repo, "/branches/$branchName"),
          force: force, decoder: (data) => Branch.fromJson(data));
}

/// 仓库提交记录
class GogsRepoCommit extends GogsClientBase {
  GogsRepoCommit(super.client);

  /// GET /repos/:username/:reponame/commits
  /// [pageSize] 他默认是30
  ///
  /// 获取指定仓库提交记录信息。注：他这个API不完善，不能做分页
  FutureRESTResult<CommitList?> getAll(Repository repo,
          {int? pageSize, bool? force}) =>
      client.get<CommitList>(_baseRepoPath(repo, "/commits"),
          queryParameters: pageSize != null ? {'pagesize': pageSize} : null,
          force: force,
          decoder: (data) => Commit.fromJsonList(data));

  /// GET /repos/:username/:reponame/commits/:sha

  /// GET /repos/:username/:reponame/commits/:ref
  /// Accept: application/vnd.gogs.sha
}

/// 仓库issues里定义的标签信息
class GogsRepoLabel extends GogsClientBase {
  GogsRepoLabel(super.client);

  /// GET /repos/:username/:reponame/labels
  ///
  /// 获取这个仓库的标签信息，这个指的是issues上的标签
  FutureRESTResult<IssueLabelList?> getAll(Repository repo, {bool? force}) =>
      client.get<IssueLabelList>(_baseRepoPath(repo, "/labels"),
          force: force, decoder: (data) => IssueLabel.fromJsonList(data));
}

/// 仓库
class GogsRepos extends GogsClientBase {
  GogsRepos(super.client)
      : content = GogsRepoContent(client),
        branch = GogsRepoBranch(client),
        commit = GogsRepoCommit(client),
        label = GogsRepoLabel(client);

  /// 仓库内容API
  final GogsRepoContent content;

  /// 仓库分支API
  final GogsRepoBranch branch;

  /// 仓库提交记录API
  final GogsRepoCommit commit;

  /// 仓库issues里的标签
  final GogsRepoLabel label;

  /// GET /repos/:owner/:repo
  ///
  /// 获取一个仓库信息
  FutureRESTResult<Repository> repo(Repository repo, {bool? force}) =>
      client.get<Repository>(_baseRepoPath(repo, ""),
          force: force, decoder: (data) => Repository.fromJson(data));

  /// GET /users/:username/repos
  ///
  /// 获取指定用户的仓库列表
  FutureRESTResult<RepositoryList?> userRepos(User user, {bool? force}) =>
      client.get<RepositoryList>("/users/${user.username}/repos",
          force: force, decoder: (data) => Repository.fromJsonList(data));

  /// GET /orgs/:orgname/repos
  ///
  /// 获取指定组织的仓库列表
  FutureRESTResult<RepositoryList?> orgRepos(Organization org, {bool? force}) =>
      client.get<RepositoryList>("/orgs/${org.username}/repos",
          force: force, decoder: (data) => Repository.fromJsonList(data));

  /// GET /repos/:username/:reponame/forks
  ///
  /// 获取fork这个仓库的用户？
  FutureRESTResult<RepositoryList?> forks(Repository repo, {bool? force}) =>
      client.get<RepositoryList>(_baseRepoPath(repo, "/forks"),
          force: force, decoder: (data) => Repository.fromJsonList(data));

  /// GET /repos/search
  ///
  /// 搜索
  ///
  /// [q]：用户名关键字
  ///
  /// [uid]：user的ID，默认为0，表示搜索所有仓库
  ///
  /// [limit]：搜索结果限制，默认为10条
  ///
  /// [page]：分页编号，默认为1
  FutureRESTResult<SearchRepositories?> search(String q,
          {int? uid, int? limit, int? page}) =>
      client.get<SearchRepositories>('/repos/search',
          queryParameters: {
            "q": q,
            if (uid != null) "uid": uid,
            if (limit != null) "limit": limit,
            if (page != null) "page": page,
          },
          options: Options(extra: {"nocache": true}),
          decoder: (data) => SearchRepositories.fromJson(data));
}
