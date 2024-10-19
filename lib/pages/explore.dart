import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gogs_app/app_globals.dart';

import 'package:gogs_app/widgets/platform_page_scaffold.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  //late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    //_controller = TextEditingController();
  }

  @override
  void dispose() {
    //_controller.dispose();
    super.dispose();
  }

  Future<void> _onSubmitted(String? value) async {
    if (value != null && value.isNotEmpty) {
      final res = await AppGlobal.cli.repos.search(value);
      if (res.succeed && res.data != null && res.data!.ok) {
        if (mounted) setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformPageScaffold(
      materialAppBar: () => AppBar(
        title: const Text('发现'),
      ),
      cupertinoSliverNavigationBar: () => const CupertinoSliverNavigationBar(
        largeTitle: Text('发现'),
        // previousPageTitle: context.previousPageTitle,
        border: null,
      ),
      topBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: CupertinoSearchTextField(
          //controller: _controller,
          onSubmitted: _onSubmitted,
        ),
      ),
      children: [],
    );
  }
}
