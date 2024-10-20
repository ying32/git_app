part of gogs.client;

class User {
  const User({
    required this.id,
    required this.username,
    this.login = "",
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    this.location = "",
    this.website = "",
    this.followersCount = 0,
    this.followingCount = 0,
    this.starCount = 0,
    this.reposCount = 0,
    this.description = "",
  });

  final int id;
  final String username;
  final String login;
  final String fullName;
  final String email;
  final String avatarUrl;
  final String location;
  final String website;
  final int followersCount;
  final int followingCount;
  final int starCount;
  final int reposCount;
  final String description;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"] ?? 0,
        username: json["username"] ?? '',
        login: json["login"] ?? '',
        fullName: json["full_name"] ?? '',
        email: json["email"] ?? '',
        avatarUrl: json["avatar_url"] ?? '',

        // new
        location: json["location"] ?? '',
        website: json["website"] ?? '',
        followersCount: json["followers_count"] ?? 0,
        followingCount: json["following_count"] ?? 0,
        starCount: json['starred_repos_count'] ?? 0,
        reposCount: json["repos_count"] ?? 0,
        description: json["description"] ?? '',
      );

  /// 生成一个只有名称和头像的User信息
  factory User.fromNameAndHeadImage(String userName, String avatarUrl) => User(
        id: 0,
        username: userName,
        fullName: '',
        email: '',
        avatarUrl: avatarUrl,
      );

  // Map<String, dynamic> toJson() => {
  //       "id": id,
  //       "username": username,
  //       "login": login,
  //       "full_name": fullName,
  //       "email": email,
  //       "avatar_url": avatarUrl,
  //
  //       // new
  //       "is_org": isOrg,
  //       "location": location,
  //       "website": website,
  //       "followers_count": followersCount,
  //       "following_count": followingCount,
  //       "star_count": starCount,
  //       "repos_count": reposCount,
  //       "teams_count": teamsCount,
  //       "members_count": membersCount,
  //       "description": description,
  //     };

  static UserList fromJsonList(dynamic data) =>
      UserList.from(data.map((x) => User.fromJson(x)));
}

typedef UserList = List<User>;
