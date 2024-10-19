import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gogs_app/pages/explore.dart';
import 'package:gogs_app/pages/login.dart';

import 'package:gogs_app/pages/home.dart';
import 'package:gogs_app/pages/activity.dart';
import 'package:gogs_app/pages/settinngs.dart';
import 'package:gogs_app/utils/build_context_helper.dart';

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
  _NavPage(
      title: '主页',
      icon: Icons.home,
      page: const HomePage(
        title: '主页',
      )),
  _NavPage(
      title: '最近活动',
      icon: Icons.notifications_none,
      page: const ActivityPage(
        title: '最近活动',
      )),
  _NavPage(
      title: '发现',
      icon: Icons.search,
      // icon: Icons.search,
      page: const ExplorePage()),
];

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _pageNumber = 0;

  // 组件初始
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // free
  @override
  void dispose() {
    _pageController.dispose();
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

  // 每次状态改变，都会重新执行
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LoginState>(
      valueListenable: AppGlobal.instance.loginState,
      builder: (BuildContext context, LoginState value, Widget? child) {
        return value == LoginState.logged
            ? (context.platformIsIOS
                ? _buildCupertinoBody()
                : _buildMaterialBody())
            : const LoginPage();
      },
    );
  }
}
