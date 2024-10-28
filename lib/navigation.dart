import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:git_app/pages/explore.dart';
import 'package:git_app/pages/issue/issues.dart';
import 'package:git_app/pages/login.dart';

import 'package:git_app/pages/home.dart';
import 'package:git_app/pages/activity.dart';
import 'package:git_app/pages/organizations.dart';
import 'package:git_app/pages/repo/repositories.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:git_app/widgets/cached_image.dart';
import 'package:git_app/widgets/platform_page_scaffold.dart';
import 'package:remixicon/remixicon.dart';

import 'app_globals.dart';

class _NavPage {
  _NavPage({
    required this.title,
    required this.icon,
    required this.page,
  });
  final String title;
  final IconData icon;
  final Widget page;
}

final _pages = <_NavPage>[
  _NavPage(title: '主页', icon: Icons.home, page: const HomePage()),
  _NavPage(
      title: '最近活动',
      icon: Icons.notifications_none,
      page: const ActivityPage()),
  _NavPage(title: '发现', icon: Icons.search, page: const ExplorePage()),
];

class _PhoneNavigationPage extends StatefulWidget {
  const _PhoneNavigationPage();
  @override
  State<StatefulWidget> createState() => _PhoneNavigationPageState();
}

/// 移动端布局，不知道是不这样操作哈，先这样玩了再说
class _PhoneNavigationPageState extends State<_PhoneNavigationPage> {
  final PageController _pageController = PageController();
  int _pageNumber = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 页面改变事件
  void _onPageChanged(int page) {
    setState(() {
      _pageNumber = page;
    });
  }

  void _doJumpPage(int page) {
    // 不要动画了
    _pageController.jumpToPage(page);
    // _pageController.animateToPage(page,
    //     duration: const Duration(milliseconds: 500), curve: Curves.ease);
  }

  final bottomNavBarItems = _pages.map((e) {
    return BottomNavigationBarItem(icon: Icon(e.icon), label: e.title);
  }).toList();

  Widget _buildMaterialBody() => Scaffold(
        // backgroundColor: Theme.of(context).colorScheme.primary,

        // 主体部分
        body: PageView(
          physics:
              const NeverScrollableScrollPhysics(), //BouncingScrollPhysics(),
          controller: _pageController,
          onPageChanged: _onPageChanged,
          // 这里定义使用的多少个页面，页面由自己定义
          children: _pages.map((e) => e.page).toList(),
        ),
        // 底层导航栏
        bottomNavigationBar: BottomNavigationBar(
          elevation: 0,
          items: bottomNavBarItems,
          onTap: (value) => setState(() {
            _pageNumber = value;
            _doJumpPage(_pageNumber);
          }),
          currentIndex: _pageNumber,
          type: BottomNavigationBarType.fixed,
        ),
      );

  Widget _buildCupertinoBody() => CupertinoTabScaffold(
        tabBar: CupertinoTabBar(items: bottomNavBarItems),
        tabBuilder: (BuildContext context, int index) => CupertinoTabView(
          builder: (BuildContext context) => _pages[index].page,
        ),
      );

  @override
  Widget build(BuildContext context) =>
      context.platformIsIOS ? _buildCupertinoBody() : _buildMaterialBody();
}

/// 平板电脑样式
class _TabletNavigationPage extends StatefulWidget {
  const _TabletNavigationPage();
  @override
  State<StatefulWidget> createState() => _TabletNavigationPageState();
}

class _TabletNavigationPageState extends State<_TabletNavigationPage>
    with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PlatformPageScaffold(
      //appBar: PlatformPageAppBar(title: Text('标题')),
      child: Row(
        children: <Widget>[
          NavigationRail(
            leading: const UserHeadImage(size: 44, previousPageTitle: '主页'),
            // trailing: Icon(Icons.settings),
            selectedIndex: _selectedIndex, // 默认选中第二个标签
            groupAlignment: -1.0,
            labelType: NavigationRailLabelType.selected,
            // labelType: NavigationRailLabelType.all,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home, color: Colors.blue),
                label: Text('主页'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.info_outline, color: Colors.green),
                label: Text('问题'),
              ),
              NavigationRailDestination(
                icon: Icon(Remix.git_pull_request_line, color: Colors.blue),
                label: Text('合并请求'),
              ),
              NavigationRailDestination(
                icon: Icon(Remix.git_repository_line,
                    color: Colors.deepPurpleAccent),
                label: Text('仓库'),
              ),
              NavigationRailDestination(
                icon: Icon(Remix.organization_chart, color: Colors.orange),
                label: Text('组织'),
              ),
              // NavigationRailDestination(
              //   icon: Icon(Remix.heart_fill, color: Colors.red),
              //   label: Text('收藏'),
              // ),
            ],
          ),
          // Expanded(
          //     child: IndexedStack(
          //   index: _selectedIndex,
          //   children: [
          //     const ActivityPage(),
          //     const IssuesPage(category: IssuesCategory.issues, title: '问题'),
          //     const Center(child: Text('没有API')),
          //     RepositoriesPage(
          //       user: AppGlobal.instance.userInfo!,
          //       title: '我的仓库',
          //     ),
          //     OrganizationsPage(
          //       title: '我的组织',
          //       user: AppGlobal.instance.userInfo!,
          //     ),
          //     Center(
          //       child: Text('没有呢=$_selectedIndex'),
          //     ),
          //   ],
          // )),

          Expanded(
            child: Scaffold(
              body: switch (_selectedIndex) {
                0 => const ActivityPage(),
                1 => const IssuesPage(
                    category: IssuesCategory.issues, title: '问题'),
                2 => const Center(child: Text('没有API')),
                3 => RepositoriesPage(
                    user: AppGlobal.instance.userInfo!,
                    title: '我的仓库',
                  ),
                4 => OrganizationsPage(
                    title: '我的组织',
                    user: AppGlobal.instance.userInfo!,
                  ),
                _ => Center(
                    child: Text('没有呢=$_selectedIndex'),
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// 导航页
class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage>
    with WidgetsBindingObserver {
  // 组件初始
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // free
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// didChangeAppLifecycleState
  ///
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (kDebugMode) {
      print("didChangeAppLifecycleState=$state");
    }
    if (state == AppLifecycleState.resumed) {
      if (kDebugMode) {
        print("切换到了前台");
      }
    } else if (state == AppLifecycleState.paused) {
      if (kDebugMode) {
        print("切换到了后台");
      }
    } else if (state == AppLifecycleState.detached) {
      if (kDebugMode) {
        print("结束了？");
      }
    }
  }

  Widget _layoutBuilder(BuildContext context) {
    //if (context.isTablet) {
    //  return const _TabletNavigationPage();
    //}
    return const _PhoneNavigationPage();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LoginState>(
      valueListenable: AppGlobal.instance.loginState,
      builder: (BuildContext context, LoginState value, Widget? child) {
        if (value != LoginState.logged) {
          return const LoginPage();
        }
        return Builder(builder: _layoutBuilder);
      },
    );
  }
}
