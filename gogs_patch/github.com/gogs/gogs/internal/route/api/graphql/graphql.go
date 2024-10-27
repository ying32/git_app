//----------------------------------------
//
// Copyright © ying32. All Rights Reserved.
//
// Licensed under Apache License 2.0
//
//----------------------------------------

package graphql

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"reflect"
	"strconv"
	"strings"
	"time"

	"gogs.io/gogs/internal/database"

	ctx "context"

	ql "github.com/graphql-go/graphql"
	"gogs.io/gogs/internal/context"
)

// 注：这东西是用来做测试和学习GraphQL的
// api.go中RegisterRoutes函数中添加一句
// m.Post("/graphql", context.APIContexter(), reqToken(), graphql.GraphQL)
//
// 关于循环引用问题
// https://github.com/graphql-go/graphql/issues/164
// repoType.AddFieldConfig("parent", &ql.Field{Type: repoType})
// 这个方法行不通： https://github.com/graphql-go/graphql/issues/258

// resolveParams 重新装的，用来扩展字段用
type resolveParams struct {
	*context.APIContext
	p ql.ResolveParams
}

// GetString 获取指定字段参数
func (r resolveParams) GetString(name string) string {
	if val, ok := r.p.Args[name]; ok {
		switch val.(type) {
		case string:
			return val.(string)
		default:
			return fmt.Sprint(val)
		}
	}
	return ""
}

func (r resolveParams) GetInt(name string) int {
	if val, ok := r.p.Args[name]; ok {
		return val.(int)
	}
	return 0
}

func (r resolveParams) GetInt64(name string) int64 {
	return int64(r.GetInt(name))
}

func (r resolveParams) GetBool(name string) bool {
	if val, ok := r.p.Args[name]; ok {
		switch val.(type) {
		case bool:
			return val.(bool)
		}
	}
	return false
}

func (r resolveParams) GetFloat32(name string) float32 {
	return float32(r.GetFloat64(name))
}

func (r resolveParams) GetFloat64(name string) float64 {
	if val, ok := r.p.Args[name]; ok {
		switch val.(type) {
		case float64:
			return val.(float64)
		case float32:
			return float64(val.(float32))
		}
	}
	return 0.0
}

func (r resolveParams) GetTime(name string) time.Time {
	if val, ok := r.p.Args[name]; ok {
		switch val.(type) {
		case time.Time:
			return val.(time.Time)
		}
	}
	return time.Time{}
}

// graphQLMgr graphgl管理
type graphQLMgr struct {
	schema ql.Schema
	// 用于查找的类型
	types     map[reflect.Type]*ql.Object
	userType  *ql.Object
	repoType  *ql.Object
	feedType  *ql.Object
	issueType *ql.Object
	labelType *ql.Object
	// query
	queryType *ql.Object
}

func newGraphQLMgr() *graphQLMgr {
	r := &graphQLMgr{types: map[reflect.Type]*ql.Object{}}
	r.init()
	return r
}

// 一个实例
var qlMgr = newGraphQLMgr()

// 注册query类型
func (r *graphQLMgr) regQueryFunc(name string, returnType ql.Output, resolve func(*resolveParams) (interface{}, error), args ql.FieldConfigArgument) {
	r.queryType.AddFieldConfig(name, &ql.Field{
		Type: returnType,
		Args: args,
		Resolve: func(p ql.ResolveParams) (interface{}, error) {
			apiContext := p.Context.Value("context")
			if apiContext == nil {
				return nil, errors.New("not Found apiContext")
			}
			return resolve(&resolveParams{APIContext: apiContext.(*context.APIContext), p: p})
		},
	})
}

// 注册类型
func (r *graphQLMgr) regType(a any) *ql.Object {
	typ := reflect.TypeOf(a)
	if typ.Kind() == reflect.Pointer {
		typ = typ.Elem()
	}
	if val, ok := r.types[typ]; ok {
		return val
	}

	type cycleItem struct {
		name    string
		isSlice bool
	}
	// 收集循环引用字段
	cycles := make([]cycleItem, 0)

	fields := ql.Fields{}
	for i := 0; i < typ.NumField(); i++ {
		typeField := typ.Field(i)
		// 查看有没有配置json字段，如果没有配置就直接使用字段名，
		name, ok := typeField.Tag.Lookup("json")
		if !ok {
			name = strings.ToLower(typeField.Name)
		}
		field := &ql.Field{}
		switch typeField.Type.Kind() {
		case reflect.Int,
			reflect.Int8,
			reflect.Int16,
			reflect.Int32,
			reflect.Int64,
			reflect.Uint,
			reflect.Uint8,
			reflect.Uint16,
			reflect.Uint32,
			reflect.Uint64,
			reflect.Uintptr:
			field.Type = ql.Int
		case reflect.Bool:
			field.Type = ql.Boolean
		case reflect.Float32,
			reflect.Float64:
			field.Type = ql.Float
		case reflect.String:
			field.Type = ql.String
		case reflect.Pointer:
			realType := typeField.Type.Elem()
			if val, ok := r.types[realType]; ok {
				field.Type = val
			} else if realType == typ {
				cycles = append(cycles, cycleItem{name: name})
				continue
			} else {
				panic("不支持的指针类型：" + typeField.Type.Name())
			}
		case reflect.Struct:
			switch typeField.Type.Name() {
			case "Time":
				field.Type = ql.DateTime
			default:
				panic("不支持的结构类型：" + typeField.Type.Name())
			}
		case reflect.Slice:
			realType := typeField.Type.Elem()
			if realType.Kind() == reflect.Pointer {
				realType = realType.Elem()
			}
			if val, ok := r.types[realType]; ok {
				field.Type = ql.NewList(val)
			} else if realType == typ {
				cycles = append(cycles, cycleItem{name: name, isSlice: true})
				continue
			} else {
				panic("不支持的切片（数组）类型：" + typeField.Type.Name())
			}
		default:
			panic("不支持的类型，分类：" + typeField.Type.Kind().String() + "，名称：" + typeField.Type.Name())
		}
		fields[name] = field
	}

	res := ql.NewObject(ql.ObjectConfig{
		Name:   typ.Name(),
		Fields: fields,
	})
	// 处理循环引用字段
	for _, item := range cycles {
		if item.isSlice {
			res.AddFieldConfig(item.name, &ql.Field{Type: ql.NewList(res)})
		} else {
			res.AddFieldConfig(item.name, &ql.Field{Type: res})
		}
	}
	r.types[typ] = res

	return res
}

// 初始化
func (r *graphQLMgr) init() {
	// 注册类型，有顺序的，某个包含了的就得上一级
	r.userType = r.regType(User{})
	r.repoType = r.regType(Repository{})
	r.feedType = r.regType(FeedAction{})
	r.labelType = r.regType(Label{})
	r.issueType = r.regType(Issue{})
	// 初始query类型
	r.queryType = ql.NewObject(ql.ObjectConfig{Name: "Query", Fields: ql.Fields{}})

	// 注册函数类型，似乎可以通过某种rtti方式来做这个？
	r.regQueryFunc("user",
		r.userType,
		r.funcUser,
		map[string]*ql.ArgumentConfig{"username": {
			Type: ql.String,
		}})
	r.regQueryFunc("repos",
		ql.NewList(r.repoType),
		r.funcRepos, map[string]*ql.ArgumentConfig{
			"username": {Type: ql.String},
			"page":     {Type: ql.Int},
		})
	r.regQueryFunc("repo",
		r.repoType,
		r.funcRepo, map[string]*ql.ArgumentConfig{
			"owner":    {Type: ql.String},
			"reponame": {Type: ql.String},
		})
	r.regQueryFunc("feeds",
		ql.NewList(r.feedType),
		r.funcFeeds, map[string]*ql.ArgumentConfig{
			"after_id": {Type: ql.Int},
		})
	r.regQueryFunc("issue",
		r.issueType,
		r.funcIssue, map[string]*ql.ArgumentConfig{
			"index":    {Type: ql.Int},
			"username": {Type: ql.String},
			"reponame": {Type: ql.String},
		})
	r.regQueryFunc("issues",
		ql.NewList(r.issueType),
		r.funcIssues, map[string]*ql.ArgumentConfig{
			"username": {Type: ql.String},
			"reponame": {Type: ql.String},
			"state":    {Type: ql.String},
			"page":     {Type: ql.Int},
		})
	// 初始schema
	var err error
	r.schema, err = ql.NewSchema(ql.SchemaConfig{Query: r.queryType})
	if err != nil {
		log.Fatalf("failed to create schema, error: %v", err)
	}
}

// 这个名称是区分大小写的
/*
	query{
	  repo(owner:"ying32",reponame:"client_test"){
	    id
	  }
	}

	query {
	   user(username:"ying32"){
	     id
	     username
	     avatar_url
	   }

	   repo(owner:"ying32",reponame:"client_test"){
	     id
	     owner{
	       username
	     }
	   }
	}
*/
func (r *graphQLMgr) funcUser(p *resolveParams) (interface{}, error) {
	// 如果id为nil查询当前用户
	if username := p.GetString("username"); username == "" {
		u := p.User
		if !p.IsLogged {
			u.Email = ""
		}
		return copyUser(u), nil
	} else {
		if u, err := database.Handle.Users().GetByUsername(p.Req.Context(), username); err != nil {
			return nil, err
		} else {
			return copyUser(u), nil
		}
	}
}

/*
	repo(owner:"ying32",reponame:"client_test"){
	  id
	}
*/
func (r *graphQLMgr) funcRepo(p *resolveParams) (interface{}, error) {

	owner := p.GetString("owner")
	repoName := p.GetString("reponame")
	if owner != "" && repoName != "" {
		u, err := database.Handle.Users().GetByUsername(p.Req.Context(), owner)
		if err != nil {
			if database.IsErrUserNotExist(err) {
				return nil, err
			} else {
				return nil, errors.New("get user by name")
			}
		}
		repo, err := database.GetRepositoryByName(u.ID, repoName)
		if err != nil {
			return nil, err
		}
		//return struct {
		//	Id    int64
		//	Owner struct {
		//		Name string
		//	}
		//}{Id: 1}, nil
		// 从分析得到结果，他通过反射查询名称，不区分大小写吧，先通过字段名，如果没有，他貌似会解析json中的

		return copyRepository(repo), nil
	}
	return nil, nil
}

/*
	query {
	   repos {
	     id
	     owner {
	         username
	      }
	   }
	}
*/
func (r *graphQLMgr) funcRepos(p *resolveParams) (interface{}, error) {
	if username := p.GetString("username"); username == "" {
		return listUserRepositories(p.APIContext, p.User.Name)
	} else {
		return listUserRepositories(p.APIContext, username)
	}
}

/*
	    // after_id 可为空
		query {
		    feeds(after_id:12){
		      id
		      op_type
		      act_user{
		         username
		      }
		      repo {
		         name
		         owner {
		            username
		         }
		      }
		     ref_name
		     is_private
		     created_at
		     content
		     issue_id
		     issue_title
		   }
		}
*/
func (r *graphQLMgr) funcFeeds(p *resolveParams) (interface{}, error) {
	return listRetrieveFeeds(p.APIContext, p.GetInt64("after_id"))
}

/*
	query {
	    issue(index:1, username:"ying32", reponame:"client_test"){
	      id
	      index
	      title
	      content
	      poster {
	         username
	      }
	      labels {
	        name
	        color
	      }
	      assignee {
	         username
	      }
	      repo {
	         name
	         owner {
	            username
	         }
	      }
	     state
	     comments
	     created_at
	     updated_at
	   }
	}
*/
func (r *graphQLMgr) funcIssue(p *resolveParams) (interface{}, error) {
	if err := repoAssignment(p); err != nil {
		return nil, err
	}
	issue, err := database.GetIssueByIndex(p.Repo.Repository.ID, p.GetInt64("index"))
	if err != nil {
		return nil, err
	}
	return copyIssue(issue), nil
}

/*
	    issues(username:"ying32", reponame:"client_test", state:"closed", page:1){

		query {
		    issues(username:"ying32", reponame:"client_test"){
		      id
		      index
		      title
		      content
		      poster {
		         username
		      }
		      labels {
		        name
		        color
		      }
		      assignee {
		         username
		      }
		      repo {
		         name
		         owner {
		            username
		         }
		      }
		     state
		     comments
		     created_at
		     updated_at
		   }
		}
*/
func (r *graphQLMgr) funcIssues(p *resolveParams) (interface{}, error) {
	if err := repoAssignment(p); err != nil {
		return nil, err
	}
	var opts database.IssuesOptions
	isClosed := p.GetString("state") == "closed"
	page := p.GetInt("page")
	if p.GetString("username") == "" {
		opts = database.IssuesOptions{
			RepoID:   p.Repo.Repository.ID,
			Page:     page,
			IsClosed: isClosed,
		}
	} else {
		opts = database.IssuesOptions{
			AssigneeID: p.User.ID,
			Page:       page,
			IsClosed:   isClosed,
		}
	}
	return listIssues(&opts)
}

// User 重新定义的user
type User struct {
	Id                int64  `json:"id"`
	UserName          string `json:"username"`
	Login             string `json:"login"`
	FullName          string `json:"full_name"`
	Email             string `json:"email"`
	AvatarUrl         string `json:"avatar_url"`
	Location          string `json:"location"`
	Website           string `json:"website"`
	FollowersCount    int    `json:"followers_count"`
	FollowingCount    int    `json:"following_Count"`
	StarredReposCount int    `json:"starred_repos_count"`
	ReposCount        int    `json:"repos_count"`
	Description       string `json:"description"`
}

// 复制user信息
func copyUser(user *database.User) *User {
	if user == nil {
		return nil
	}
	return &User{
		Id:                user.ID,
		UserName:          user.Name,
		Login:             user.Name,
		FullName:          user.FullName,
		Email:             user.Email,
		AvatarUrl:         user.AvatarURL(),
		Location:          user.Location,
		Website:           user.Website,
		FollowersCount:    user.NumFollowers,
		FollowingCount:    user.NumFollowing,
		StarredReposCount: user.NumStars,
		ReposCount:        user.NumRepos,
		Description:       user.Description,
	}
}

// Repository 重新定义的仓库类型
type Repository struct {
	Id              int64       `json:"id"`
	Owner           *User       `json:"owner"`
	Name            string      `json:"name"`
	FullName        string      `json:"full_name"`
	Description     string      `json:"description"`
	Private         bool        `json:"private"`
	Fork            bool        `json:"fork"`
	Parent          *Repository `json:"parent"`
	Empty           bool        `json:"empty"`
	Mirror          bool        `json:"mirror"`
	Size            int64       `json:"size"`
	Website         string      `json:"website"`
	StarsCount      int         `json:"stars_count"`
	ForksCount      int         `json:"forks_count"`
	WatchersCount   int         `json:"watchers_count"`
	OpenIssuesCount int         `json:"open_issues_count"`
	OpenPrCounter   int         `json:"open_pr_counter"`
	TagsCount       int         `json:"tags_count"`
	DefaultBranch   string      `json:"default_branch"`
	CreatedAt       time.Time   `json:"created_at"`
	UpdatedAt       time.Time   `json:"updated_at"`
}

// 复制仓库信息
func copyRepository(repo *database.Repository, user ...*database.User) *Repository {
	if repo == nil {
		return nil
	}
	res := &Repository{
		Id:              repo.ID,
		Owner:           copyUser(repo.Owner),
		Name:            repo.Name,
		FullName:        repo.FullName(),
		Description:     repo.Description,
		Private:         repo.IsPrivate,
		Fork:            repo.IsFork,
		Empty:           repo.IsBare,
		Mirror:          repo.IsMirror,
		Size:            repo.Size,
		Website:         repo.Website,
		StarsCount:      repo.NumStars,
		ForksCount:      repo.NumForks,
		WatchersCount:   repo.NumWatches,
		OpenIssuesCount: repo.NumOpenIssues,
		OpenPrCounter:   repo.NumOpenPulls,
		DefaultBranch:   repo.DefaultBranch,
		TagsCount:       repo.NumTags,
		CreatedAt:       repo.Created,
		UpdatedAt:       repo.Updated,
	}
	if len(user) != 0 {
		res.Owner = copyUser(user[0])
	}
	if repo.IsFork {
		res.Parent = copyRepository(repo.BaseRepo)
	}
	return res
}

// FeedAction 最近活动,gitea中他在时timeline这个API里面
type FeedAction struct {
	Id         int64       `json:"id"`
	OpType     string      `json:"op_type"`  // 操作类型
	ActUser    *User       `json:"act_user"` // 提交者
	Repo       *Repository `json:"repo"`
	RefName    string      `json:"ref_name"` // 引用的分支
	IsPrivate  bool        `json:"is_private"`
	CreatedAt  time.Time   `json:"created_at"`  // 创建时间
	Content    string      `json:"content"`     // 这里面还得拆出数据
	IssueId    int         `json:"issue_id"`    // issues的id
	IssueTitle string      `json:"issue_title"` // issue标题

}

// Label issue标题
type Label struct {
	Id    int64  `json:"id"`
	Name  string `json:"name"`
	Color string `json:"color"`
}

// 复制标签
func copyLabel(label *database.Label) *Label {
	if label == nil {
		return nil
	}
	return &Label{
		Id:    label.ID,
		Name:  label.Name,
		Color: label.Color,
	}
}

// 复制issue的标签列表
func copyLabels(labels []*database.Label) []*Label {
	if len(labels) > 0 {
		res := make([]*Label, len(labels))
		for i := 0; i < len(res); i++ {
			res[i] = copyLabel(labels[i])
		}
		return res
	}
	return nil
}

// Issue 单个问题
type Issue struct {
	Id       int64       `json:"id"`
	Repo     *Repository `json:"repo"`
	Index    int64       `json:"index"`
	Poster   *User       `json:"poster"`
	Title    string      `json:"title"`
	Content  string      `json:"content"`
	Labels   []*Label    `json:"labels"`
	Assignee *User       `json:"assignee"`
	State    string      `json:"state"`
	Comments int         `json:"comments"`
	Created  time.Time   `json:"created_at"`
	Updated  time.Time   `json:"updated_at"`
}

// 复制issue
func copyIssue(issue *database.Issue) *Issue {
	if issue == nil {
		return nil
	}
	state := "open"
	if issue.IsClosed {
		state = "closed"
	}
	return &Issue{
		Id:       issue.ID,
		Repo:     copyRepository(issue.Repo),
		Index:    issue.Index,
		Poster:   copyUser(issue.Poster),
		Title:    issue.Title,
		Content:  issue.Content,
		Labels:   copyLabels(issue.Labels),
		Assignee: copyUser(issue.Assignee),
		State:    state,
		Comments: issue.NumComments,
		Created:  issue.Created,
		Updated:  issue.Updated,
	}
}

type postData struct {
	Query     string                 `json:"query"`
	Operation string                 `json:"operationName"`
	Variables map[string]interface{} `json:"variables"`
}

// GraphQL
//
// POST /api/graphql
func GraphQL(c *context.APIContext) {
	body, err := c.Req.Body().String()
	if err != nil {
		c.NotFound()
		return
	}
	// 这里改下，如果json解析失败。默认为一个query，也方便我测试
	var p postData
	if err := json.NewDecoder(bytes.NewBufferString(body)).Decode(&p); err != nil {
		p.Query = body
	}

	result := ql.Do(ql.Params{
		Context:        ctx.WithValue(ctx.Background(), "context", c),
		Schema:         qlMgr.schema,
		RequestString:  p.Query,
		VariableValues: p.Variables,
		OperationName:  p.Operation,
	})

	/*
			{
			    user(username:"ying32"){
			      id
			      username
			      full_name
			      avatar_url
			    }
			    repo(owner:"ying32", reponame:"client_test") {
			      id
			      name
			      full_name
			      description
			      parent {
			        id
		          }
			      owner{
			        id
			        full_name
			        username
			        avatar_url

			      }
			    }
			}
	*/

	if len(result.Errors) > 0 {
		log.Printf("wrong result, unexpected errors: %v", result.Errors)
		c.NotFound()
		return
	}
	c.JSONSuccess(result)
}

// file: api/v1/repo/repo.go
func listUserRepositories(c *context.APIContext, username string) ([]*Repository, error) {
	user, err := database.Handle.Users().GetByUsername(c.Req.Context(), username)
	if err != nil {
		return nil, err
	}

	// Only list public repositories if user requests someone else's repository list,
	// or an organization isn't a member of.
	var ownRepos []*database.Repository
	if user.IsOrganization() {
		ownRepos, _, err = user.GetUserRepositories(c.User.ID, 1, user.NumRepos)
	} else {
		ownRepos, err = database.GetUserRepositories(&database.UserRepoOptions{
			UserID:   user.ID,
			Private:  c.User.ID == user.ID,
			Page:     1,
			PageSize: user.NumRepos,
		})
	}
	if err != nil {
		return nil, err
	}

	if err = database.RepositoryList(ownRepos).LoadAttributes(); err != nil {
		return nil, err
	}

	// Early return for querying other user's repositories
	if c.User.ID != user.ID {
		repos := make([]*Repository, len(ownRepos))
		for i := range ownRepos {
			repos[i] = copyRepository(ownRepos[i])
		}
		return repos, nil
	}
	accessibleRepos, err := database.Handle.Repositories().GetByCollaboratorIDWithAccessMode(c.Req.Context(), user.ID)
	if err != nil {
		return nil, err
	}

	numOwnRepos := len(ownRepos)
	repos := make([]*Repository, 0, numOwnRepos+len(accessibleRepos))

	for _, r := range ownRepos {
		repos = append(repos, copyRepository(r))

	}
	for repo, _ := range accessibleRepos {
		repos = append(repos, copyRepository(repo))
	}
	return repos, nil
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
func listRetrieveFeeds(c *context.APIContext, afterID int64) ([]*FeedAction, error) {

	var err error
	var actions []*database.Action
	if c.User.IsOrganization() {
		actions, err = database.Handle.Actions().ListByOrganization(c.Req.Context(), c.User.ID, c.UserID(), afterID)
	} else {
		actions, err = database.Handle.Actions().ListByUser(c.Req.Context(), c.User.ID, c.UserID(), afterID, false)
	}
	if err != nil {
		//c.NotFoundOrError(err, "list actions")
		return nil, err
	}

	// Check access of private repositories.
	feeds := make([]*FeedAction, 0, len(actions))
	users := make(map[string]*database.User)
	repos := make(map[int64]*database.Repository)

	findUser := func(userName string) (*database.User, error) {
		v, ok := users[userName]
		if !ok {
			u, err := database.Handle.Users().GetByUsername(c.Req.Context(), userName)
			if err != nil {
				return nil, err
			}
			users[userName] = u
			return u, nil
		}
		return v, nil
	}

	for _, act := range actions {
		// Cache results to reduce queries.
		actUser, err := findUser(act.ActUserName)
		if err != nil {
			return nil, err
		}
		repoUser, err := findUser(act.RepoUserName)
		if err != nil {
			return nil, err
		}
		repo, ok := repos[act.RepoID]
		if !ok {
			repo, err = database.Handle.Repositories().GetByID(c.Req.Context(), act.RepoID)
			if err != nil {
				return nil, err
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
			Id:        act.ID,
			OpType:    actionToString(act.OpType),
			ActUser:   copyUser(actUser),
			Repo:      copyRepository(repo, repoUser), //repo.APIFormat(repoUser),
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
	//c.JSONSuccess(&feeds)
	return feeds, nil
}

// file: api/v1/repo/repo.go
func repoAssignment(p *resolveParams) error {
	username := p.GetString("username")
	reponame := p.GetString("reponame")

	var err error
	var owner *database.User

	// Check if the context user is the repository owner.
	if p.IsLogged && p.User.LowerName == strings.ToLower(username) {
		owner = p.User
	} else {
		owner, err = database.Handle.Users().GetByUsername(p.Req.Context(), username)
		if err != nil {
			//p.NotFoundOrError(err, "get user by name")
			return err
		}
	}
	p.Repo.Owner = owner

	repo, err := database.Handle.Repositories().GetByName(p.Req.Context(), owner.ID, reponame)
	if err != nil {
		//p.NotFoundOrError(err, "get repository by name")
		return err
	} else if err = repo.GetOwner(); err != nil {
		//c.Error(err, "get owner")
		return err
	}

	if p.IsTokenAuth && p.User.IsAdmin {
		p.Repo.AccessMode = database.AccessModeOwner
	} else {
		p.Repo.AccessMode = database.Handle.Permissions().AccessMode(p.Req.Context(), p.UserID(), repo.ID,
			database.AccessModeOptions{
				OwnerID: repo.OwnerID,
				Private: repo.IsPrivate,
			},
		)
	}

	if !p.Repo.HasAccess() {
		//p.NotFound()
		//return
		return errors.New("not found")
	}

	p.Repo.Repository = repo
	return nil
}

// file: internal/route/api/v1/repo/issue.go
func listIssues(opts *database.IssuesOptions) ([]*Issue, error) {
	issues, err := database.Issues(opts)
	if err != nil {
		//c.Error(err, "list issues")
		return nil, err
	}

	_, err = database.IssuesCount(opts)
	if err != nil {
		//c.Error(err, "count issues")
		return nil, err
	}

	// FIXME: use IssueList to improve performance.
	apiIssues := make([]*Issue, len(issues))
	for i := range issues {
		if err = issues[i].LoadAttributes(); err != nil {
			//c.Error(err, "load attributes")
			return nil, err
		}
		apiIssues[i] = copyIssue(issues[i])
	}

	//c.SetLinkHeader(int(count), conf.UI.IssuePagingNum)
	//c.JSONSuccess(&apiIssues)
	return apiIssues, nil
}
