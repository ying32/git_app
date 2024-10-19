part of gogs.client;

/// 看了下后面输出的，他实际也是user，只是稍微变了，相关字段都有的
typedef Organization = User;
typedef OrganizationList = UserList;

// List<OrgInfo> userOrgFromJson(dynamic data) =>
//     List<OrgInfo>.from(data.map((x) => OrgInfo.fromJson(x)));
//
// String userOrgToJson(List<OrgInfo> data) =>
//     json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
//
// class OrgInfo {
//   final int? id;
//   final String? username;
//   final String? fullName;
//   final String? avatarUrl;
//   final String? description;
//   final String? website;
//   final String? location;
//
//   OrgInfo({
//     this.id,
//     this.username,
//     this.fullName,
//     this.avatarUrl,
//     this.description,
//     this.website,
//     this.location,
//   });
//
//   OrgInfo copyWith({
//     int? id,
//     String? username,
//     String? fullName,
//     String? avatarUrl,
//     String? description,
//     String? website,
//     String? location,
//   }) =>
//       OrgInfo(
//         id: id ?? this.id,
//         username: username ?? this.username,
//         fullName: fullName ?? this.fullName,
//         avatarUrl: avatarUrl ?? this.avatarUrl,
//         description: description ?? this.description,
//         website: website ?? this.website,
//         location: location ?? this.location,
//       );
//
//   factory OrgInfo.fromJson(Map<String, dynamic> json) => OrgInfo(
//     id: json["id"],
//     username: json["username"],
//     fullName: json["full_name"],
//     avatarUrl: json["avatar_url"],
//     description: json["description"],
//     website: json["website"],
//     location: json["location"],
//   );
//
//   Map<String, dynamic> toJson() => {
//     "id": id,
//     "username": username,
//     "full_name": fullName,
//     "avatar_url": avatarUrl,
//     "description": description,
//     "website": website,
//     "location": location,
//   };
// }
