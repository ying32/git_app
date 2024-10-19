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

type IssueComment struct {
	*api.Comment
	Type string `json:"type"`
}

func toIssueComment(commentType database.CommentType) string {
	switch commentType {
	case database.COMMENT_TYPE_COMMENT:
		return "comment"
	case database.COMMENT_TYPE_REOPEN:
		return "reopen"
	case database.COMMENT_TYPE_CLOSE:
		return "closed"

	case database.COMMENT_TYPE_ISSUE_REF:
		return "issue_ref"
	case database.COMMENT_TYPE_COMMIT_REF:
		return "commit_ref"
	case database.COMMENT_TYPE_COMMENT_REF:
		return "comment_ref"
	case database.COMMENT_TYPE_PULL_REF:
		return "pull_ref"
	}
	return ""
}

func FromIssueComment(comment *database.Comment) *IssueComment {
	return &IssueComment{
		Comment: comment.APIFormat(),
		Type:    toIssueComment(comment.Type),
	}
}
