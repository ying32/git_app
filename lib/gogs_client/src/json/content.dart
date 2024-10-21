part of gogs.client;

/// 文件内容
class Content {
  Content({
    required this.type,
    required this.encoding,
    required this.size,
    required this.name,
    required this.path,
    required this.content,
    required this.sha,
    //required this.url,
    //required this.gitUrl,
    //required this.htmlUrl,
    // required this.downloadUrl,
    // required this.links,
  });

  final String type;
  final String encoding;
  final int size;
  final String name;
  final String path;
  final String content;
  final String sha;
  //final String url;
  //final String gitUrl;
  //final String htmlUrl;
  //final String downloadUrl;
  // final Links links;

  factory Content.fromJson(Map<String, dynamic> json) => Content(
        type: json["type"] ?? '',
        encoding: json["encoding"] ?? '',
        size: json["size"] ?? 0,
        name: json["name"] ?? '',
        path: json["path"] ?? '',
        content: json["content"] ?? '',
        sha: json["sha"] ?? '',
        //url: json["url"] ?? '',
        //gitUrl: json["git_url"] ?? '',
        //htmlUrl: json["html_url"] ?? '',
        //downloadUrl: json["download_url"] ?? '',
        // links: Links.fromJson(json["_links"] ?? {}),
      );

  // Map<String, dynamic> toJson() => {
  //       "type": type,
  //       "encoding": encoding,
  //       "size": size,
  //       "name": name,
  //       "path": path,
  //       "content": content,
  //       "sha": sha,
  //       "url": url,
  //       "git_url": gitUrl,
  //       "html_url": htmlUrl,
  //       "download_url": downloadUrl,
  //       "_links": links.toJson(),
  //     };

  static ContentList fromJsonList(dynamic data) =>
      ContentList.from(data.map((x) => Content.fromJson(x)));
}

typedef ContentList = List<Content>;

// class Links {
//   Links({
//     required this.git,
//     required this.self,
//     required this.html,
//   });
//   final String git;
//   final String self;
//   final String html;
//
//   factory Links.fromJson(Map<String, dynamic> json) => Links(
//         git: json["git"] ?? '',
//         self: json["self"] ?? '',
//         html: json["html"] ?? '',
//       );
//
//   Map<String, dynamic> toJson() => {
//         "git": git,
//         "self": self,
//         "html": html,
//       };
// }
