//----------------------------------------
//
// Copyright © ying32. All Rights Reserved.
//
// Licensed under Apache License 2.0
//
//----------------------------------------

package helper

import (
	"strconv"
	"strings"
	"time"

	api "github.com/gogs/go-gogs-client"

	"gogs.io/gogs/internal/context"
	"gogs.io/gogs/internal/database"
)

type FeedAction struct {
	Id         int64           `json:"id"`
	OpType     string          `json:"op_type"`    // 操作类型
	Committer  *User           `json:"committer"`  // 提交者
	RepoOwner  *User           `json:"repo_owner"` // 仓库所有者
	Repo       *api.Repository `json:"repo"`
	RefName    string          `json:"ref_name"` // 引用的分支
	IsPrivate  bool            `json:"is_private"`
	CreatedAt  time.Time       `json:"created_at"`  // 创建时间
	Content    string          `json:"content"`     // 这里面还得拆出数据
	IssueId    int             `json:"issue_id"`    // issues的id
	IssueTitle string          `json:"issue_title"` // issue标题

}

func actionToString(opType database.ActionType) string {
	switch opType {
	case database.ActionCreateRepo:
		return "create_repo"
	case database.ActionRenameRepo:
		return "rename_repo"
	case database.ActionStarRepo:
		return "star_repo"
	case database.ActionWatchRepo:
		return "watch_repo"
	case database.ActionCommitRepo:
		return "commit_repo"
	case database.ActionCreateIssue:
		return "create_issue"
	case database.ActionCreatePullRequest:
		return "create_pull_request"
	case database.ActionTransferRepo:
		return "transfer_repo"
	case database.ActionPushTag:
		return "push_tag"
	case database.ActionCommentIssue:
		return "comment_issue"
	case database.ActionMergePullRequest:
		return "merge_pull_request"
	case database.ActionCloseIssue:
		return "close_issue"
	case database.ActionReopenIssue:
		return "reopen_issue"
	case database.ActionClosePullRequest:
		return "close_pull_request"
	case database.ActionReopenPullRequest:
		return "reopen_pull_request"
	case database.ActionCreateBranch:
		return "create_branch"
	case database.ActionDeleteBranch:
		return "delete_branch"
	case database.ActionDeleteTag:
		return "delete_tag"
	case database.ActionForkRepo:
		return "fork_repo"
	case database.ActionMirrorSyncPush:
		return "mirror_sync_push"
	case database.ActionMirrorSyncCreate:
		return "mirror_sync_create"
	case database.ActionMirrorSyncDelete:
		return "mirror_sync_delete"
	}
	return ""
}

// GetRetrieveFeeds 修改自 internal/route/user/home.go
func GetRetrieveFeeds(c *context.APIContext) {
	afterID := c.QueryInt64("after_id")

	var err error
	var actions []*database.Action
	if c.User.IsOrganization() {
		actions, err = database.Handle.Actions().ListByOrganization(c.Req.Context(), c.User.ID, c.UserID(), afterID)
	} else {
		actions, err = database.Handle.Actions().ListByUser(c.Req.Context(), c.User.ID, c.UserID(), afterID, false)
	}
	if err != nil {
		c.NotFoundOrError(err, "list actions")
		return
	}

	// Check access of private repositories.
	feeds := make([]*FeedAction, 0, len(actions))
	users := make(map[string]*database.User)
	repos := make(map[int64]*database.Repository)

	findUser := func(userName string) (*database.User, bool) {
		v, ok := users[userName]
		if !ok {
			u, err := database.Handle.Users().GetByUsername(c.Req.Context(), userName)
			if err != nil {
				if database.IsErrUserNotExist(err) {
					return nil, false
				}
				c.NotFoundOrError(err, "get user by name")
				return nil, false
			}
			users[userName] = u

			return u, true
		}

		return v, true
	}

	for _, act := range actions {
		// Cache results to reduce queries.
		actUser, ok := findUser(act.ActUserName)
		if !ok {
			return
		}
		repoUser, ok := findUser(act.RepoUserName)
		if !ok {
			return
		}
		repo, ok := repos[act.RepoID]
		if !ok {
			repo, err = database.Handle.Repositories().GetByID(c.Req.Context(), act.RepoID)
			if err != nil {
				c.NotFoundOrError(err, "get repo by id")
				return
			}
			repos[act.RepoID] = repo
		}

		content := act.Content
		issueId := 0
		if content != "" {
			idx := strings.Index(content, "|")
			if idx != -1 {
				issueId, _ = strconv.Atoi(content[:idx])
				content = content[idx+1:]
			}
		}

		feedAct := &FeedAction{
			Id:     act.ID,
			OpType: actionToString(act.OpType),
			//Committer: actUser.APIFormat(),
			//RepoOwner: repoUser.APIFormat(),
			Committer: fromUser(actUser),
			RepoOwner: fromUser(repoUser),
			Repo:      repo.APIFormat(repoUser),
			RefName:   act.RefName,
			IsPrivate: act.IsPrivate,
			CreatedAt: act.Created,
			IssueId:   issueId,
			Content:   content,
		}
		if issueId > 0 {
			issue, err := database.GetIssueByID(int64(issueId))
			if err == nil {
				feedAct.IssueTitle = issue.Title
			}
		}

		feeds = append(feeds, feedAct)
	}
	//c.Data["Feeds"] = feeds
	//if len(feeds) > 0 {
	//	afterID := feeds[len(feeds)-1].ID
	//	c.Data["AfterID"] = afterID
	//	c.Header().Set("X-AJAX-URL", fmt.Sprintf("%s?after_id=%d", c.Data["Link"], afterID))
	//}
	c.JSONSuccess(&feeds)
}
