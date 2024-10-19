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
	"gogs.io/gogs/internal/conf"
	"gogs.io/gogs/internal/context"
	"gogs.io/gogs/internal/database"
)

func listPullRequests(c *context.APIContext, opts *database.IssuesOptions) {
	issues, err := database.Issues(opts)
	if err != nil {
		c.Error(err, "list issues")
		return
	}

	count, err := database.IssuesCount(opts)
	if err != nil {
		c.Error(err, "count issues")
		return
	}

	// FIXME: use IssueList to improve performance.
	apiIssues := make([]*api.Issue, len(issues))
	for i := range issues {
		if err = issues[i].LoadAttributes(); err != nil {
			c.Error(err, "load attributes")
			return
		}
		apiIssues[i] = issues[i].APIFormat()
	}

	c.SetLinkHeader(int(count), conf.UI.IssuePagingNum)
	c.JSONSuccess(&apiIssues)
}
