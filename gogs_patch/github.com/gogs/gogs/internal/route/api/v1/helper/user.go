//----------------------------------------
//
// Copyright © ying32. All Rights Reserved.
//
// Licensed under Apache License 2.0
//
//----------------------------------------

package helper

import (
	api "github.com/gogs/go-gogs-client"
	database "gogs.io/gogs/internal/database"
)

type User struct {
	*api.User

	/// 新加的字段，
	Location    string `json:"location"`
	Website     string `json:"website"`
	Followers   int    `json:"followers_count"`
	Following   int    `json:"following_count"`
	Stars       int    `json:"starred_repos_count"`
	Repos       int    `json:"repos_count"`
	Description string `json:"description"`
	// 这个可以未登录里干掉？
	//Created time.Time `json:"created"`
}

// FromUser 返回一个新的格式。
func FromUser(user *database.User, apiUser *api.User) *User {
	return &User{
		User:        apiUser,
		Location:    user.Location,
		Website:     user.Website,
		Followers:   user.NumFollowers,
		Following:   user.NumFollowing,
		Stars:       user.NumStars,
		Repos:       user.NumRepos,
		Description: user.Description,
	}
}

func fromUser(user *database.User) *User {
	return FromUser(user, user.APIFormat())
}

func FromUsers(users []*database.User, apiUsers []*api.User) []*User {
	var result = make([]*User, len(users))
	for i := 0; i < len(users); i++ {
		result[i] = FromUser(users[i], apiUsers[i])
	}
	return result
}
