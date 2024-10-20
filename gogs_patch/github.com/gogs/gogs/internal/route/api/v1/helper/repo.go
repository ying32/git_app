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
	"gogs.io/gogs/internal/context"
	"gogs.io/gogs/internal/database"
)

type Repository struct {
	*api.Repository

	// new+
	OpenPulls int `json:"open_pr_counter"`
	// IsWatching IsStaring 需要登录，下面其它的只在 /repos/:username/:repo的时候填充
	//IsWatching   bool  `json:"is_watching"`
	//IsStaring    bool  `json:"is_staring"`
	//BranchCount  int   `json:"branch_count"`
	//CommitsCount int64 `json:"commits_count"`
	//ReadMe       struct {
	//	Content  string `json:"content"`
	//	FileName string `json:"file_name"`
	//} `json:"read_me"`
	//License string `json:"license"`
}

func FromRepository(c *context.APIContext, repo *database.Repository, apiRepo *api.Repository, useGitInfo bool) (res *Repository) {
	res = &Repository{
		Repository: apiRepo,
		OpenPulls:  repo.NumOpenPulls,
	}
	// 不需要后面的参数的
	//if !useGitInfo {
	//	return
	//}
	//
	//if c.IsLogged {
	//	res.IsWatching = database.IsWatching(c.User.ID, repo.ID)
	//	res.IsStaring = database.IsStaring(c.User.ID, repo.ID)
	//}
	///// 分支数量+提交量
	//
	//if len(c.Repo.TreePath) != 0 {
	//	return
	//}
	//gitRepo, err := git.Open(c.Repo.Repository.RepoPath())
	//if err != nil {
	//	return
	//}
	//// 默认分支名
	//refName := c.Repo.Repository.DefaultBranch
	//if !gitRepo.HasBranch(refName) {
	//	return
	//}
	//// 获取分支
	//branches, _ := gitRepo.Branches()
	//res.BranchCount = len(branches)
	//commit, _ := gitRepo.BranchCommit(refName)
	//if commit == nil {
	//	return
	//}
	//// 提交历史
	//res.CommitsCount, _ = commit.CommitsCount()
	//tree, err := commit.Subtree(c.Repo.TreePath)
	//if err != nil {
	//	return
	//}
	////读readme和那啥授权的
	//entries, err := tree.Entries()
	//if err != nil {
	//	return
	//}
	////entries.Sort()
	//var readmeFile *git.Blob
	//for _, entry := range entries {
	//	if entry.IsTree() || !markup.IsReadmeFile(entry.Name()) {
	//		continue
	//	}
	//	readmeFile = entry.Blob()
	//	break
	//}
	//if readmeFile != nil {
	//	p, err := readmeFile.Bytes()
	//	if err == nil {
	//		res.ReadMe.FileName = readmeFile.Name()
	//		res.ReadMe.Content = string(p)
	//	}
	//}
	//// 找授权协议的
	//var licenseFile *git.Blob
	//// !strings.HasPrefix(strings.ToLower(entry.Name()), "license")
	//for _, entry := range entries {
	//	if entry.IsTree() || entry.Name() != "LICENSE" {
	//		continue
	//	}
	//	licenseFile = entry.Blob()
	//	break
	//}
	//if licenseFile != nil {
	//	p, err := licenseFile.Bytes()
	//	if err == nil {
	//		// 搞个简易的哈
	//		var str = string(p)
	//		var idx = strings.Index(str, "\n")
	//		if idx != -1 {
	//			res.License = strings.TrimSpace(str[:idx])
	//		}
	//	}
	//}
	//
	return
}

// FromRepositories 只解决首层的，至于parent和owner啥的不管了
//func FromRepositories(c *context.APIContext, repos []*database.Repository, apiRepos []*api.Repository) any {
//	res := make([]*Repository, len(repos))
//	for i := 0; i < len(repos); i++ {
//		res[i] = FromRepository(c, repos[i], apiRepos[i], false)
//	}
//	// 看他原来就是这种返回的，所以这里原来处理吧
//	return &res
//}
