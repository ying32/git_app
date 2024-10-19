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
	"gogs.io/gogs/internal/database"
)

type Organization struct {
	*api.Organization
	IsOrg bool `json:"is_org"`
	Repos int  `json:"repos_count"`
}

func FromOrganization(user *database.User, apiOrganization *api.Organization) *Organization {
	return &Organization{
		Organization: apiOrganization,
		IsOrg:        true,          // 这里强制？
		Repos:        user.NumRepos, // 这个不对？
	}
}

func FromOrganizations(user *database.User, apiOrganizations []*api.Organization) any {
	var result = make([]*Organization, len(apiOrganizations))
	for i := 0; i < len(apiOrganizations); i++ {
		result[i] = FromOrganization(user, apiOrganizations[i])
	}
	// 按他的返回一个指针
	return &result
}
