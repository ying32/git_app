import 'package:flutter/material.dart';
import 'package:git_app/app_globals.dart';
import 'package:git_app/gogs_client/gogs_client.dart';
import 'package:git_app/utils/collection_mgr.dart';
import 'package:git_app/widgets/platform_page_scaffold.dart';
import 'package:remixicon/remixicon.dart';

import 'adaptive_widgets.dart';
import 'background_container.dart';
import 'cached_image.dart';
import 'list_section.dart';

class _ListItem {
  const _ListItem({
    required this.index,
    required this.item,
    required this.isSelected,
  });
  final int index;
  final CollectionItem item;
  final bool isSelected;
}

class _CollectionListItemWidget extends StatelessWidget {
  const _CollectionListItemWidget(
    this.item, {
    required this.animation,
    this.isRemove = false,
    this.onTap,
    this.showDivider = true,
  });
  final _ListItem item;
  final Animation<double> animation;
  final bool isRemove;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    // 构建一个仓库信息
    final repo = Repository.fromNameAndOwner(
        item.item.repoName, item.item.ownerName, item.item.avatarUrl);

    Widget child = ListTileNav(
      leading: UserHeadImage(
          user: repo.owner,
          radius: 6,
          padding: const EdgeInsets.all(3),
          size: 50),
      title: repo.fullName,
      trailing: Icon(
          isRemove ? Remix.close_circle_fill : Icons.add_circle_outline,
          size: 18,
          color: isRemove ? Colors.grey : null),
      onTap: onTap,
    );
    if (showDivider) {
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const ListTileDivider(),
        ],
      );
    }
    return SizeTransition(
      sizeFactor: animation,
      child: BackgroundContainer(child: child),
    );
  }
}

//todo: 待完善
class CollectionEditor extends StatefulWidget {
  const CollectionEditor({super.key});

  @override
  State<StatefulWidget> createState() => _CollectionEditorState();
}

class _CollectionEditorState extends State<CollectionEditor> {
  final List<CollectionItem> _unSelectedItems = [];
  final List<CollectionItem> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    // 复制一份历史记录的
    _selectedItems.addAll(CollectionMgr.instance.items);
    // 获取自己仓库的
    _init();
  }

  Future<void> _init() async {
    final res = await AppGlobal.cli.user.repos();
    if (res.succeed && res.data != null) {
      // 这里还要处理下已经在历史记录中的了
      final ids = _selectedItems.map((e) => e.id);
      for (final e in res.data!) {
        if (ids.contains(e.id)) continue;
        _unSelectedItems.add(CollectionItem(
            id: e.id,
            repoName: e.name,
            ownerName: e.owner.username,
            avatarUrl: e.owner.avatarUrl));
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _doDone() {
    // 这里要检测是否有修改再返回true来
    CollectionMgr.instance.reAddAll(_selectedItems);
    CollectionMgr.instance.save();
    Navigator.of(context).pop(true);
  }

  void _doCancel() {
    // todo: 这里还待完善有改变弹出是否丢失或者继续啥的
    Navigator.of(context).pop();
  }

  List<dynamic> _getList() {
    final res = ['已选择的', 10.0];

    for (var i = 0; i < _selectedItems.length; i++) {
      res.add(_ListItem(
        index: i,
        item: _selectedItems[i],
        isSelected: true,
      ));
    }

    res.add(20.0);

    for (var i = 0; i < _unSelectedItems.length; i++) {
      res.add(_ListItem(
        index: i,
        item: _unSelectedItems[i],
        isSelected: false,
      ));
    }
    return res;
  }

  Widget _buildBody() {
    final list = _getList();

    return AnimatedList(
      initialItemCount: list.length,
      itemBuilder:
          (BuildContext context, int index, Animation<double> animation) {
        final item = list[index];
        if (item is String) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(item),
          );
        } else if (item is double) {
          return SizedBox(height: item);
        } else {
          if (item is _ListItem) {
            var showDivider = true;
            if (item.isSelected) {
              showDivider = item.index != _selectedItems.length - 1;
            } else {
              showDivider = item.index != _unSelectedItems.length - 1;
            }

            return _CollectionListItemWidget(item,
                animation: animation,
                isRemove: item.isSelected,
                showDivider: showDivider, onTap: () {
              // 移除项目
              AnimatedList.of(context).removeItem(index,
                  (BuildContext context, Animation<double> animation) {
                // 他这里移除还要构建一个哈
                return _CollectionListItemWidget(item,
                    animation: animation,
                    isRemove: item.isSelected,
                    showDivider: showDivider);
              });
              // 重新添加到对应的列表中
              if (item.isSelected) {
                _unSelectedItems.add(_selectedItems.removeAt(item.index));
                AnimatedList.of(context).insertItem(list.length - 1);
              } else {
                _selectedItems.add(_unSelectedItems.removeAt(item.index));
                AnimatedList.of(context).insertItem(_selectedItems.length + 1);
              }

              // 索引更新了，这里重新刷新下
              setState(() {});
            });
          } else {
            // 不会被执行
            return const SizedBox();
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget navLeft = AdaptiveButton(
      onPressed: _doCancel,
      child: const Text('取消'),
    );
    Widget navRight = AdaptiveButton(
      onPressed: _doDone,
      child: const Text('完成'),
    );

    return PlatformPageScaffold(
      // materialAppBar: () => AppBar(
      //   leading: navLeft,
      //   title: const Text('仓库'),
      //   centerTitle: true,
      //   actions: [navRight],
      // ),
      // cupertinoNavigationBar: () => CupertinoNavigationBar(
      //   leading: navLeft,
      //   middle: const Text('仓库'),
      //   trailing: navRight,
      //   previousPageTitle: null,
      //   border: null,
      //   transitionBetweenRoutes: false,
      // ),
      appBar: PlatformPageAppBar(
        leading: navLeft,
        title: const Text('仓库'),
        centerTitle: true,
        actions: [navRight],
        previousPageTitle: null,
        border: null,
        transitionBetweenRoutes: false,
      ),
      child: _unSelectedItems.isEmpty
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _buildBody(),
    );
  }
}
