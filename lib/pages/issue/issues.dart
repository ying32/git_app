import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:git_app/app_globals.dart';
import 'package:git_app/gogs_client/gogs_client.dart';
import 'package:git_app/pages/issue/create_issue.dart';
import 'package:git_app/utils/build_context_helper.dart';

import 'package:git_app/widgets/adaptive_widgets.dart';
import 'package:git_app/widgets/platform_page_scaffold.dart';
import 'package:git_app/widgets/issue/issues_item.dart';

enum IssuesCategory { issues, pullRequests, repoIssues, repoPullRequests }

enum _SegmentCategory {
  issuesOpen,
  issuesClosed,
}

class IssuesPage extends StatefulWidget {
  const IssuesPage({
    super.key,
    required this.title,
    this.repo,
    required this.category,
  });

  final String title;
  final Repository? repo;
  final IssuesCategory category;

  @override
  State<IssuesPage> createState() => _IssuesPageState();
}

class _IssuesPageState extends State<IssuesPage> {
  IssueList? _issues;

  int _pageNumber = 0;

  _SegmentCategory _selectedSegment = _SegmentCategory.issuesOpen;

  @override
  void dispose() {
    super.dispose();
  }

  int get _issueLength => _issues?.length ?? 0;

  Future _init(_, bool? force) async {
    // 第二开始
    _pageNumber = 1;
    // 如果repo不为null则基本是单个仓库的issues
    if (widget.repo != null) {
      if (widget.category == IssuesCategory.repoIssues) {
        final res = await AppGlobal.cli.issues.getAll(widget.repo!,
            isClosed: _selectedSegment == _SegmentCategory.issuesClosed,
            force: force);
        _issues = res.data;
      } else if (widget.category == IssuesCategory.repoPullRequests) {
        // 没有
      }
    } else {
      if (widget.category == IssuesCategory.issues) {
        // 当前所有仓库的issues
        final res = await AppGlobal.cli.user.issues(
            page: _pageNumber,
            isClosed: _selectedSegment == _SegmentCategory.issuesClosed,
            force: force);
        _issues = res.data;
      } else if (widget.category == IssuesCategory.pullRequests) {
        // 也没有
      }
    }
    if ((_issues?.isNotEmpty ?? false) && mounted) {
      setState(() {});
    }
  }

  Future<void> _loadMoreData() async {
    if (_pageNumber == 0) return;
    _pageNumber++;
    if (widget.repo != null) {
      if (widget.category == IssuesCategory.repoIssues) {
        final res = await AppGlobal.cli.issues.getAll(widget.repo!,
            page: _pageNumber,
            isClosed: _selectedSegment == _SegmentCategory.issuesClosed,
            force: true);
        if (res.data?.isEmpty ?? true) {
          _pageNumber = 0;
        }
        _issues?.addAll(res.data!);
        if (mounted) setState(() {});
      } else if (widget.category == IssuesCategory.repoPullRequests) {
        //
      }
    } else {
      if (widget.category == IssuesCategory.issues) {
        // 当前所有仓库的issues
        final res = await AppGlobal.cli.user.issues(
            page: _pageNumber,
            isClosed: _selectedSegment == _SegmentCategory.issuesClosed,
            force: true);
        if (res.data?.isEmpty ?? true) {
          _pageNumber = 0;
        }
        _issues?.addAll(res.data!);
        if (mounted) setState(() {});
      } else if (widget.category == IssuesCategory.pullRequests) {
        // 也没有
      }
    }
  }

  Widget _buildMid() {
    final width = MediaQuery.of(context).size.width;
    return CupertinoSlidingSegmentedControl<_SegmentCategory>(
      groupValue: _selectedSegment,
      onValueChanged: (_SegmentCategory? value) {
        if (value != null) {
          _issues?.clear();
          setState(() {
            _selectedSegment = value;
            _init(context, false);
          });
        }
      },
      children: <_SegmentCategory, Widget>{
        _SegmentCategory.issuesOpen: Padding(
            padding: EdgeInsets.symmetric(horizontal: width / 6),
            child: const Text('开启中')),
        _SegmentCategory.issuesClosed: Padding(
          padding: EdgeInsets.symmetric(horizontal: width / 6),
          child: const Text('已关闭'),
        ),
      },
    );
  }

  void _doTapCreateIssue() {
    showCreateIssuePage(context, widget.repo!).then((issue) {
      if (issue != null) {
        setState(() {
          _issues?.insert(0, issue);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final createIssueButton = AdaptiveButton.icon(
      onPressed: _doTapCreateIssue,
      child: const Icon(Icons.add_circle_outline),
    );
    final isRepo = widget.category == IssuesCategory.repoIssues ||
        widget.category == IssuesCategory.repoPullRequests;
    return PlatformPageScaffold(
      reqRefreshCallback: _init,
      reqPullUpLoadCallback: _loadMoreData,
      // materialAppBar: () => AppBar(
      //   title: Text(widget.title),
      //   actions: [
      //     createIssueButton,
      //   ],
      // ),
      // cupertinoNavigationBar: widget.category == IssuesCategory.repoIssues ||
      //         widget.category == IssuesCategory.repoPullRequests
      //     ? () => CupertinoNavigationBar(
      //           middle: Text(widget.title),
      //           previousPageTitle: context.previousPageTitle,
      //           border: null,
      //           trailing: createIssueButton,
      //         )
      //     : null,
      // cupertinoSliverNavigationBar: widget.category == IssuesCategory.issues ||
      //         widget.category == IssuesCategory.pullRequests
      //     ? () => CupertinoSliverNavigationBar(
      //           previousPageTitle: context.previousPageTitle,
      //           border: null,
      //           largeTitle: Text(widget.title),
      //         )
      //     : null,
      appBar: PlatformPageAppBar(
        title: isRepo ? Text(widget.title) : null,
        largeTitle: !isRepo ? Text(widget.title) : null,
        actions: isRepo ? [createIssueButton] : null,
        previousPageTitle: context.previousPageTitle,
        border: null,
      ),
      topBar: Column(
        children: [
          //todo: 搜索框，待完成
          // const Padding(
          //   padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          //   child: CupertinoSearchTextField(),
          // ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: _buildMid(),
          ),
          const Divider(height: 1),
        ],
      ),
      emptyItemHint: const Center(child: Text('没有数据哦')),
      itemBuilder: (BuildContext context, int index) {
        // if (index == _issueLength) {
        //   return AdaptiveButton(
        //       onPressed: _loadMoreData, child: const Text('加载更多...'));
        // }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: IssuesItem(repo: widget.repo, item: _issues![index]),
        );
      },
      useSeparator: true,
      itemCount: _issueLength,
    );
  }
}
