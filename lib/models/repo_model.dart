import 'package:flutter/cupertino.dart';
import 'package:gogs_app/gogs_client/gogs_client.dart';

/// 仓库模型
class RepositoryModel extends ChangeNotifier {
  RepositoryModel(this._repo);

  /// 当前仓库信息
  Repository _repo;
  Repository get repo => _repo;
  set repo(Repository value) {
    if (value != _repo) {
      _repo = value;
      notifyListeners();
    }
  }

  String? _selectedBranch;
  String get selectedBranch => _selectedBranch ?? _repo.defaultBranch;
  set selectedBranch(String? value) {
    if (_selectedBranch != value) {
      _selectedBranch = value;
      notifyListeners();
    }
  }

  /// readme文件内容
  String? _readMeContent;
  String? get readMeContent => _readMeContent ?? _repo.readMe?.content;
  set readMeContent(String? value) {
    if (_readMeContent != value) {
      _readMeContent = value;
      notifyListeners();
    }
  }
}
