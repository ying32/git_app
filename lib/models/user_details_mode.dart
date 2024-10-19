import 'package:flutter/cupertino.dart';
import 'package:gogs_app/gogs_client/gogs_client.dart';

class UserDetailsModel extends ChangeNotifier {
  UserDetailsModel(this._user);
  User _user;
  User get user => _user;
  set user(User value) {
    if (user != value) {
      _user = value;
      notifyListeners();
    }
  }
}
