part of gogs.client;

class GogsClientBase {
  const GogsClientBase(this.client);

  final GogsRESTClient client;

  /// 当前issues的基本路径
  String _reposPath(Repository repo, String path) =>
      "/repos/${repo.owner.username}/${repo.name}$path";
}

/// 先定认哈
List<T> decodeResponseToList<T>(
        Response data, T Function(Map<String, dynamic>) decoder) =>
    List<T>.from(data.data.map<T>((e) => decoder(e)));
