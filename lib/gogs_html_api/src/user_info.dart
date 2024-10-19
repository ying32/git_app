class UserInfo {
  const UserInfo({
    required this.userName,
    required this.fullName,
    required this.imageURL,
    this.location = "",
    this.eMail = "",
    this.website = "",
    this.joinTime = "",
    this.followers = 0,
    this.following = 0,
    this.repos = const [],
  });
  final String userName;
  final String fullName;
  final String imageURL;
  final String location;
  final String eMail;
  final String website;
  final String joinTime;
  final int followers;
  final int following;
  final List<RepoInfo> repos;

  UserInfo.fromJson(Map<String, dynamic> json)
      : userName = json['user_name'] ?? '',
        fullName = json['full_name'] ?? '',
        imageURL = json['image_url'] ?? '',
        location = json['location'] ?? '',
        eMail = json['email'] ?? '',
        website = json['website'] ?? '',
        joinTime = json['join_time'] ?? '',
        followers = json['followers'] ?? 0,
        following = json['following'] ?? 0,
        repos = json['repos']?.map<RepoInfo>((e) {
              return RepoInfo.fromJson(e);
            }).toList() ??
            const [];
}

class RepoInfo {
  const RepoInfo({
    required this.name,
    this.link = "",
    this.description = "",
    this.private = false,
    this.star = 0,
    this.fork = 0,
  });
  final String name;
  final String link;
  final String description;
  final bool private;
  final int star;
  final int fork;

  RepoInfo.fromJson(Map<String, dynamic> json)
      : name = json['name'] ?? '',
        link = json['link'] ?? '',
        description = json['description'] ?? '',
        private = json['private'] ?? false,
        star = json['star'] ?? 0,
        fork = json['fork'] ?? 0;
}

class RepoDetail {}
