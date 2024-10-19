part of gogs.client;

class GogsUser extends GogsClientBase {
  const GogsUser(super.client);

  /// GET /user
  ///
  /// 获取当前登录的用户信息
  FutureRESTResult<User?> user([bool? force]) => client.get<User>("/user",
      force: force, decoder: (data) => User.fromJson(data));

  /// GET /user/orgs
  ///
  /// 获取当前登录用户的组织列表
  FutureRESTResult<OrganizationList?> orgs([bool? force]) =>
      client.get<OrganizationList>("/user/orgs",
          force: force, decoder: (data) => Organization.fromJsonList(data));

  /// GET /user/repos
  ///
  /// 获取当前登录用户的仓库列表
  FutureRESTResult<RepositoryList?> repos([bool? force]) =>
      client.get<RepositoryList>("/user/repos",
          force: force, decoder: (data) => Repository.fromJsonList(data));

  /// GET /users/feeds
  ///
  /// 获取当前登录用户的“最近活动”信息列表，这个需要打补丁的，gogs不支持
  FutureRESTResult<FeedActionList> feeds({int? afterId, bool? force}) =>
      client.get<FeedActionList>("/user/feeds",
          queryParameters: afterId != null ? {"after_id": afterId} : null,
          force: force,
          decoder: (data) => FeedAction.fromJsonList(data));

  /// GET /users/{username}/activities/feeds
  ///
  /// gitea的API，跟我自己打的补丁功能差不多
  FutureRESTResult<FeedActionList> activitiesFeeds(User user,
          {bool? onlyPerformedBy,
          int? page,
          int? limit /*String? date */,
          bool? force}) =>
      client.get<FeedActionList>("/users/${user.username}/activities/feeds",
          queryParameters: {
            if (onlyPerformedBy != null) "only-performed-by": onlyPerformedBy,
            if (page != null) "page": page,
            if (limit != null) "limit": limit,
          },
          force: force,
          decoder: (data) => FeedAction.fromJsonList(data));

  /// GET /users/issues
  ///
  /// 获取当前登录用户的“issues”信息列表
  ///
  /// todo: 这个API返回的数据信息不够，而且数量也不对
  FutureRESTResult<IssueList> issues(
          {int? page, bool? isClosed, bool? force}) =>
      client.get<IssueList>("/user/issues",
          queryParameters: {
            if (page != null) "page": page,
            if (isClosed != null && isClosed == true) "state": 'closed',
          },
          force: force,
          decoder: (data) => Issue.fromJsonList(data));

  /// GET /users/:username/tokens
  ///
  /// 获取当前登录用户的token列表，这玩意有些奇怪，有的客户端创建和获取到的sha1值不对，但名字是对的，有的全是对的
  FutureRESTResult<UserTokenList?> tokens(String userName, String password,
          {bool? force}) =>
      client.get<UserTokenList>("/users/$userName/tokens",
          options: Options(headers: {
            HttpHeaders.authorizationHeader:
                "Basic ${base64.encode(utf8.encode("$userName:$password"))}"
          }),
          force: force,
          decoder: (data) => UserToken.fromJsonList(data));

  /// GET /users/:username/orgs
  ///
  /// 获取指定用户的组织列表
  FutureRESTResult<OrganizationList?> usersOrgs(User user, [bool? force]) =>
      client.get<OrganizationList>(" /users/${user.username}/orgs",
          force: force, decoder: (data) => Organization.fromJsonList(data));
}
