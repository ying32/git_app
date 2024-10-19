import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gogs_app/app_globals.dart';
import 'package:gogs_app/gogs_client/gogs_client.dart';
import 'package:gogs_app/widgets/list_section.dart';
import 'package:gogs_app/widgets/platform_page_scaffold.dart';

class BranchesList extends StatefulWidget {
  const BranchesList({
    super.key,
    required this.repo,
    required this.selectedBranch,
  });

  final Repository repo;
  final String selectedBranch;

  @override
  State<BranchesList> createState() => _BranchesListState();
}

class _BranchesListState extends State<BranchesList> {
  List<Branch>? _branches;

  Future _init(_, bool? force) async {
    final res =
        await AppGlobal.cli.repos.branch.getAll(widget.repo, force: force);
    _branches = res.data;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PlatformPageScaffold(
      reqRefreshCallback: _init,
      materialAppBar: () => AppBar(
        title: const Text('选择分支'),
      ),
      cupertinoNavigationBar: () => const CupertinoNavigationBar(
        middle: Text('选择分支'),
        previousPageTitle: '取消',
        transitionBetweenRoutes: false,
      ),
      itemCount: _branches?.length ?? 0,
      itemBuilder: (BuildContext context, int index) {
        final item = _branches![index];
        Widget child = Text(item.name);
        if (widget.repo.defaultBranch == item.name) {
          child = Row(
            children: [
              child,
              const SizedBox(width: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(3),
                ),
                padding: const EdgeInsets.all(5),
                child: const Text('默认',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
              ),
            ],
          );
        }
        return ListTileNav(
            onTap: () => Navigator.of(context).pop(item.name),
            trailing: widget.selectedBranch == item.name
                ? const Icon(Icons.check_circle, size: 18)
                : const SizedBox(),
            titleWidget: child);
      },
      useSeparator: true,
    );
  }
}
