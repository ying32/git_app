// Copyright 2014 The Gogs Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

package user

import (
	"net/http"

	"gogs.io/gogs/internal/route/api/v1/helper"

	api "github.com/gogs/go-gogs-client"

	"gogs.io/gogs/internal/context"
	"gogs.io/gogs/internal/database"
	"gogs.io/gogs/internal/markup"
)

func Search(c *context.APIContext) {
	pageSize := c.QueryInt("limit")
	if pageSize <= 0 {
		pageSize = 10
	}
	users, _, err := database.Handle.Users().SearchByName(c.Req.Context(), c.Query("q"), 1, pageSize, "")
	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]any{
			"ok":    false,
			"error": err.Error(),
		})
		return
	}

	results := make([]*api.User, len(users))
	for i := range users {
		results[i] = &api.User{
			ID:        users[i].ID,
			UserName:  users[i].Name,
			AvatarUrl: users[i].AvatarURL(),
			FullName:  markup.Sanitize(users[i].FullName),
		}
		if c.IsLogged {
			results[i].Email = users[i].Email
		}
	}

	c.JSONSuccess(map[string]any{
		"ok":   true,
		"data": helper.FromUsers(users, results),
	})
}

func GetInfo(c *context.APIContext) {
	u, err := database.Handle.Users().GetByUsername(c.Req.Context(), c.Params(":username"))
	if err != nil {
		c.NotFoundOrError(err, "get user by name")
		return
	}

	// Hide user e-mail when API caller isn't signed in.
	if !c.IsLogged {
		u.Email = ""
	}
	c.JSONSuccess(helper.FromUser(u, u.APIFormat()))
}

func GetAuthenticatedUser(c *context.APIContext) {
	c.JSONSuccess(helper.FromUser(c.User, c.User.APIFormat()))
}
