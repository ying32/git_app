import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:git_app/utils/callbacks.dart';

// copy from: lib\src\cupertino\nav_bar.dart
const Color _kDefaultNavBarBorderColor = Color(0x4D000000);

const Border _kDefaultNavBarBorder =
    Border(bottom: BorderSide(color: _kDefaultNavBarBorderColor, width: 0.0));

/// 异步数据改变
typedef PlatformPageScaffoldRefreshCallback = Future<void> Function(
    BuildContext context, bool? value);

class PlatformPageAppBar {
  const PlatformPageAppBar({
    this.leading,
    this.automaticallyImplyLeading = true,
    this.title,
    this.actions,
    this.centerTitle,
    // only iOS style
    this.previousPageTitle,
    this.border = _kDefaultNavBarBorder,
    this.largeTitle,
    this.transitionBetweenRoutes = true,
    this.stretch = false,
  });

  /// 标题左边
  final Widget? leading;

  final bool automaticallyImplyLeading;

  /// [AppBar]中对应[AppBar.title]字段，[CupertinoNavigationBar]中对应[CupertinoNavigationBar.middle]
  /// 当定义了[largeTitle]如果[title]为null，则title为[largeTitle]
  final Widget? title;

  /// [AppBar]中对应[AppBar.actions]，[CupertinoNavigationBar]中对应[CupertinoNavigationBar.trailing]
  final List<Widget>? actions;

  /// 仅[AppBar]有效
  final bool? centerTitle;

  /// 上一页的标题，仅[CupertinoNavigationBar]有效
  final String? previousPageTitle;

  /// 仅CupertinoNavigationBar有效
  final Border? border;

  /// 当此值不为null则使用[CupertinoSliverNavigationBar]类型的导航，同时忽略[title]字段。
  final Widget? largeTitle;

  /// 仅[CupertinoNavigationBar]或[CupertinoSliverNavigationBar]有效
  final bool transitionBetweenRoutes;

  /// 当[largeTitle]不为null时有效，对应[CupertinoSliverNavigationBar.stretch]
  final bool stretch;
}

/// 一个公共的页面基础类，这个T参数还得想想怎么弄好
class PlatformPageScaffold<T> extends StatefulWidget {
  const PlatformPageScaffold({
    super.key,
    this.appBar,
    this.controller,
    this.physics = const AlwaysScrollableScrollPhysics(),
    this.reqRefreshCallback,
    this.child,
    // this.materialAppBar,
    // this.cupertinoNavigationBar,
    // this.cupertinoSliverNavigationBar,
    this.children,
    this.itemCount,
    this.useSeparator,
    this.itemBuilder,
    this.padding,
    this.separatorPadding,
    this.emptyItemHint,
    this.topBar,
    this.backgroundColor,
    this.bottomBar,
    this.reqPullUpLoadCallback,
    this.initInFirstFrame = false,
    this.canPullDownRefresh = true,
  })  : assert(!(itemBuilder != null && children != null),
            'itemBuilder和children同时只能存在一个'),
        assert(!(itemBuilder != null && itemCount == null),
            '当itemBuilder存在时，itemCount不能为null');

  // final ValueGetter<PreferredSizeWidget?>? materialAppBar;
  // final ValueGetter<ObstructingPreferredSizeWidget?>? cupertinoNavigationBar;
  // final ValueGetter<CupertinoSliverNavigationBar>? cupertinoSliverNavigationBar;

  /// 标题bar
  final PlatformPageAppBar? appBar;

  /// ListView或者CustomScrollView的滚动控制器
  final ScrollController? controller;

  final ScrollPhysics? physics;

  /// 请求刷新数据的，可以为空，这个事件会在widget的initState和OnRefresh事件里调用，
  /// 值为force，意为强制操作请求的标识
  final PlatformPageScaffoldRefreshCallback? reqRefreshCallback;

  /// 当[child]不为null时，[children]和[itemBuilder]同时失效。
  final Widget? child;

  /// 固定列表数据，与[itemBuilder]互斥，且[child]为null时有效
  final List<Widget>? children;

  /// 当[itemBuilder]不为null时，项目的总数
  final int? itemCount;

  /// 当[itemBuilder]不为null时，否使用分割线
  final bool? useSeparator;

  /// 动态项目的构建，与[children]互斥，且[child]为null时有效
  final NullableIndexedWidgetBuilder? itemBuilder;

  /// 列表的padding值
  final EdgeInsetsGeometry? padding;

  /// 当[itemBuilder]不为null时，且useSeparator为true使用分割线的padding值，
  final EdgeInsetsGeometry? separatorPadding;

  /// 当[children]或者[itemBuilder]有效时，空数据的提示。
  final Widget? emptyItemHint;

  /// 导航栏下面的
  final Widget? topBar;

  /// 底部的
  final Widget? bottomBar;

  /// 背景色
  final Color? backgroundColor;

  /// 请求上拉加载数据
  final AsyncVoidCallback? reqPullUpLoadCallback;

  /// 如果[reqRefreshCallback]不为null，
  /// [initInFirstFrame]为true时会在[WidgetsBinding.instance.addPostFrameCallback]中初始
  final bool initInFirstFrame;

  /// 能否下拉刷新，如果[reqRefreshCallback]不为null也会被影响，默认为true
  /// 但不影响在init事件中的调用
  final bool canPullDownRefresh;

  @override
  State<StatefulWidget> createState() => _PlatformPageScaffoldState<T>();
}

class _PlatformPageScaffoldState<T> extends State<PlatformPageScaffold<T>> {
  var _loading = false;
  var _showingMore = false;

  /// 滚动控制器
  ScrollController? _controller;

  @override
  void initState() {
    super.initState();

    _controller ??= widget.controller;
    if (widget.reqPullUpLoadCallback != null && _controller == null) {
      _controller = ScrollController();
    }
    if (widget.reqRefreshCallback != null) {
      _loading = true;

      if (widget.initInFirstFrame) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _doRefreshCallback());
      } else {
        _doRefreshCallback();
      }
    }
    if (widget.reqPullUpLoadCallback != null) {
      _controller?.addListener(_onScrollListener);
    }
  }

  void _doRefreshCallback() {
    widget.reqRefreshCallback!.call(context, null).whenComplete(() {
      _loading = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_onScrollListener);
    // 如果widget没有传入，而widget创建了这个，则释放
    if (_controller != null && widget.controller == null) {
      _controller?.dispose();
    }
    super.dispose();
  }

  bool get _canShowMore => widget.reqPullUpLoadCallback != null && _showingMore;

  void _onScrollListener() {
    if (_showingMore) return;
    if (!_controller!.hasClients) return;
    if (_controller!.offset > _controller!.position.maxScrollExtent + 80) {
      if (!_showingMore) {
        setState(() {
          _showingMore = true;
        });

        // 此方法还有待修改，这不太行的
        widget.reqPullUpLoadCallback?.call().whenComplete(() {
          setState(() {
            _showingMore = false;
          });
        });
      }
    }
  }

  NullableIndexedWidgetBuilder get _builder {
    final builder = widget.itemBuilder ?? _doItemBuilder;
    if (_canShowMore) {
      return (BuildContext context, int index) {
        if (_canShowMore && index == _count - 1) {
          return _buildLoadMore();
        }
        return builder(context, index);
      };
    }
    return builder;
  }

  int get _count {
    final value = widget.itemCount ?? widget.children?.length ?? 0;
    if (value > 0 && _canShowMore) {
      return value + 1;
    }
    return value;
  }

  Widget? _doItemBuilder(BuildContext context, int index) =>
      widget.children![index];

  /// 分割符
  Widget _buildSeparator(BuildContext context, int index) =>
      widget.separatorPadding != null
          ? Padding(
              padding: widget.separatorPadding!,
              child: const Divider(height: 1))
          : const Divider(height: 1);

  /// 构建SliverList
  Widget _buildSliverList() {
    late Widget child;
    if (widget.child != null) {
      child = SliverFillRemaining(child: widget.child);
    } else {
      if (_count <= 0 && widget.emptyItemHint != null) {
        child = SliverFillRemaining(child: widget.emptyItemHint!);
      } else {
        if (widget.useSeparator ?? false) {
          child = SliverList.separated(
              itemCount: _count,
              itemBuilder: _builder,
              separatorBuilder: _buildSeparator);
        } else {
          child = SliverList.builder(itemCount: _count, itemBuilder: _builder);
        }
      }
    }
    return child;
  }

  /// 构建常规则ListView
  Widget _buildListView() {
    late Widget child;
    if (widget.child != null) {
      child = widget.child!;
    } else {
      if (_count <= 0 && widget.emptyItemHint != null) {
        // 当没有数据时，使用LayoutBuilder构建一个剩余空间位置大小的box，以便空白时widget布局
        child = LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return ListView(physics: widget.physics, children: [
              SizedBox(
                  width: math.max(constraints.minWidth, constraints.maxWidth),
                  height:
                      math.max(constraints.minHeight, constraints.maxHeight),
                  child: widget.emptyItemHint!)
            ]);
          },
        );
      } else {
        if (widget.useSeparator ?? false) {
          child = ListView.separated(
              physics: widget.physics,
              controller: _controller,
              itemCount: _count,
              itemBuilder: _builder,
              separatorBuilder: _buildSeparator);
        } else {
          child = ListView.builder(
            physics: widget.physics,
            controller: _controller,
            itemBuilder: _builder,
            itemCount: _count,
          );
        }
      }
    }
    // 有刷新方法
    if (widget.reqRefreshCallback != null && widget.canPullDownRefresh) {
      child = RefreshIndicator.adaptive(
        onRefresh: _doRefresh,
        displacement: 80,
        child: child,
      );
    }
    return child;
  }

  Future<void> _doRefresh() async =>
      await widget.reqRefreshCallback?.call(context, true);

  Widget? _buildIOSActions() {
    if (widget.appBar?.actions == null) return null;
    if (widget.appBar!.actions!.isEmpty) return null;
    if (widget.appBar!.actions!.length == 1) {
      return widget.appBar!.actions!.first;
    }
    return Row(
        mainAxisSize: MainAxisSize.min, children: widget.appBar!.actions!);
  }

  /// ios下sliver模式的刷主体
  Widget _buildCupertinoSliverBody(Widget sliver) {
    return CustomScrollView(
        physics: widget.physics,
        controller: _controller,
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            leading: widget.appBar?.leading,
            automaticallyImplyLeading:
                widget.appBar?.automaticallyImplyLeading ?? true,
            largeTitle: widget.appBar?.largeTitle,
            trailing: _buildIOSActions(),
            border: widget.appBar?.border,
            transitionBetweenRoutes:
                widget.appBar?.transitionBetweenRoutes ?? true,
            stretch: widget.appBar?.stretch ?? false,
            previousPageTitle: widget.appBar?.previousPageTitle,
          ),
          // widget.cupertinoSliverNavigationBar!.call(),
          // 有刷新事件的

          if (widget.reqRefreshCallback != null && widget.canPullDownRefresh)
            CupertinoSliverRefreshControl(onRefresh: _doRefresh),
          // 导航栏底下的
          if (widget.topBar != null) SliverToBoxAdapter(child: widget.topBar),
          // 是否有裁剪
          if (widget.padding != null)
            SliverPadding(padding: widget.padding!, sliver: sliver)
          else
            sliver,
          if (widget.bottomBar != null)
            SliverToBoxAdapter(child: widget.bottomBar!),
        ]);
  }

  Widget _buildLoadMore() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 5),
        child: CircularProgressIndicator.adaptive(),
      ),
    );
  }

  Widget _buildNavBottomAndPadding(Widget child) {
    if (widget.topBar != null || widget.bottomBar != null) {
      child = Column(children: [
        if (widget.topBar != null) widget.topBar!,
        Expanded(child: child),
        if (widget.bottomBar != null) widget.bottomBar!,
      ]);
    }
    if (widget.padding != null) {
      child = Padding(padding: widget.padding!, child: child);
    }

    return child;
  }

  Widget _buildIndicator(bool isSliver) {
    Widget child = const Center(child: CircularProgressIndicator.adaptive());
    if (isSliver) {
      child = SliverFillRemaining(child: child);
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    late Widget child;

    final isIOS = context.platformIsIOS;
    //final isSliver = isIOS && widget.cupertinoSliverNavigationBar != null;
    final isSliver = isIOS && widget.appBar?.largeTitle != null;

    if (!_loading) {
      // 当为ios平台，并且使用sliver方式时，需要构建SliverList
      child = isSliver ? _buildSliverList() : _buildListView();
    } else {
      child = _buildIndicator(isSliver);
    }

    if (isIOS) {
      if (!isSliver) {
        child = _buildNavBottomAndPadding(child);
      } else {
        child = _buildCupertinoSliverBody(child);
      }
      child = CupertinoPageScaffold(
          backgroundColor: widget.backgroundColor ??
              context.cupertinoTheme.barBackgroundColor,
          navigationBar: isSliver
              ? null
              : CupertinoNavigationBar(
                  leading: widget.appBar?.leading,
                  automaticallyImplyLeading:
                      widget.appBar?.automaticallyImplyLeading ?? true,
                  middle: widget.appBar?.title,
                  previousPageTitle: widget.appBar?.previousPageTitle,
                  border: widget.appBar?.border,
                  trailing: _buildIOSActions(),
                  transitionBetweenRoutes:
                      widget.appBar?.transitionBetweenRoutes ?? true,
                ),
          //navigationBar:
          //    isSliver ? null : widget.cupertinoNavigationBar?.call(),
          child: SafeArea(child: child));
    } else {
      child = Scaffold(
          //appBar: widget.materialAppBar?.call(),
          appBar: AppBar(
            leading: widget.appBar?.leading,
            automaticallyImplyLeading:
                widget.appBar?.automaticallyImplyLeading ?? true,
            centerTitle: widget.appBar?.centerTitle,
            title: widget.appBar?.title ?? widget.appBar?.largeTitle,
            actions: widget.appBar?.actions,
          ),
          backgroundColor: widget.backgroundColor,
          body: _buildNavBottomAndPadding(child));
    }
    return child;
  }
}
