import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as dom;
import 'user_info.dart';

class HTTP {
  static final _dio = Dio(BaseOptions(responseType: ResponseType.plain));
  // cookies 管理： https://github.com/cfug/dio/tree/main/plugins/cookie_manager
  static CookieJar? _cookieJar; // = CookieJar();

  /// 默认的头
  static final _headers = {
    HttpHeaders.acceptLanguageHeader: "zh-CN,zh;q=0.9,en;q=0.8",
    HttpHeaders.userAgentHeader:
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
  };

  static const usedPersistCookieJar = true;
  static void _initCookies() {
    if (_cookieJar == null) {
      if (usedPersistCookieJar) {
        // final path = cfg.getSettingName('cookies');
        // if (path.isEmpty) return null;
        // 持久化的，会保存到文件中，似乎命名为uri的host
        _cookieJar = PersistCookieJar(
          ignoreExpires: true,
          // storage:
          // FileStorage(KsPath.combine(KsPath.extractFilePath(path), '.cookies')),
        );
      } else {
        _cookieJar = DefaultCookieJar();
      }
      if (_cookieJar != null) {
        // 添加cookies管理
        _dio.interceptors.add(CookieManager(_cookieJar!));
      }
    }
  }

  static init() {
    _initCookies();
  }

  /// 登出
  static Future<void> logout() async => await _cookieJar?.deleteAll();

  /// 登录
  static Future<String?> login(String userName, String password,
      [bool remember = true]) async {
    var res = await _dio.post("http://localhost:3000/user/login",
        data: {
          "user_name": userName,
          "password": password,
          if (remember) "remember": "on",
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          followRedirects: true,
          maxRedirects: 1,
          validateStatus: (status) {
            return (status ?? 200) < 500; // 如果缓存的，他会返回302，这里控制不让他报错
          },
          headers: _headers,
        ));

    // 如果结果为ok则表示有问题，如果为302则表示登录成功
    if (res.statusCode == HttpStatus.ok) {
      final doc = html.parse(res.data);
      final errMsg = getErrorMessage(doc);
      return errMsg;
    }
    return null;
  }

  /// 从doc中查找错误信息
  static String? getErrorMessage(dom.Document doc) =>
      doc.querySelector("div.ui.negative.message > p")?.text.trim();

  /// 获取用户信息
  static Future<UserInfo?> getUserInfo(String user) async {
    /// 用户信息
    final res = await _dio.get('http://localhost:3000/$user');
    if (res.statusCode == HttpStatus.ok) {
      final doc = html.parse(res.data);
      final el = doc.querySelector("div.ui.card");
      if (el != null) {
        final json = <String, dynamic>{};

        json["image_url"] =
            el.querySelector("a#profile-avatar img")?.attributes['src'];
        json["full_name"] =
            el.querySelector("div.content span.header")?.text.trim();
        json["user_name"] =
            el.querySelector("div.content span.username")?.text.trim();

        final els = el.querySelectorAll("div.extra.content ul.text li");
        for (var element in els) {
          final first = element.children.firstOrNull?.attributes['class'];
          if (first != null) {
            if (first.contains("location")) {
              json["location"] = element.text.trim();
            } else if (first.contains('mail')) {
              json["email"] = element.text.trim();
            } else if (first.contains('link')) {
              json["website"] = element.text.trim();
            } else if (first.contains('clock')) {
              json["join_time"] = element.text.trim();
            } else if (first.contains('person')) {
              final els2 = element.querySelectorAll("a");
              json["followers"] = int.tryParse(
                  els2.firstOrNull?.text.split(" ").first.trim() ?? '');
              json["following"] = int.tryParse(
                  els2.lastOrNull?.text.split(" ").first.trim() ?? '');
            }
          }
        }

        final gridItemEls =
            doc.querySelectorAll("div.ui.repository.list div.item div.ui.grid");
        final repos = <Map<String, dynamic>>[];
        for (var element in gridItemEls) {
          final el = element.children[1];
          final repo = <String, dynamic>{};

          final headerEl = el.querySelector("div.ui .header");
          final name = headerEl?.querySelector("a.name");
          repo["name"] = name?.text;
          repo["link"] = name?.attributes['href'];
          repo["description"] = el.querySelector(".has-emoji")?.text.trim();
          repo["private"] = headerEl?.querySelector('.octicon-lock') != null;
          final spanEls = headerEl?.querySelectorAll("div.ui.right.metas span");
          repo["star"] = int.tryParse(spanEls?.firstOrNull?.text.trim() ?? '');
          repo["fork"] = int.tryParse(spanEls?.lastOrNull?.text.trim() ?? '');
          repos.add(repo);
        }
        json["repos"] = repos;
        return UserInfo.fromJson(json);
      }
    }
    return null;
  }

  /// 获取仓库信息
  static Future getRepo(String ownerName, String repoName) async {
    final resp = await _dio.get('http://localhost:3000/$ownerName/$repoName');
    if (kDebugMode) {
      print("resp.statusCode=${resp.statusCode}");
    }
    if (resp.statusCode == HttpStatus.ok) {
      final doc = html.parse(resp.data);
      final rights = doc.querySelector("div.ui.header div.ui.right");

      final json = <String, dynamic>{};

      if (rights?.children.length == 3) {
        int? getLabelInt(int index) => int.tryParse(rights!.children[index]
                .querySelector(".ui.basic.label")
                ?.text
                .trim() ??
            '');
        json["watchers"] = getLabelInt(0);
        json["stars"] = getLabelInt(1);
        json["forks"] = getLabelInt(2);
      }
      final items = doc.querySelectorAll("#git-stats div.ui .item");
      if (items.length == 3) {
        int? getSpanBInt(int index) => int.tryParse(
            items[index].querySelector("a span b")?.text.trim() ?? '');
        json["commits"] = getSpanBInt(0);
        json["branches"] = getSpanBInt(1);
        json["releases"] = getSpanBInt(2);
      }
      final tabs = doc.querySelectorAll("div.ui.tabs.container > div > a.item");
      if (tabs.length >= 2) {
        json["issues"] = int.tryParse(
            tabs[1].querySelector("span.label")?.text.trim() ?? '');
      }

      final repoTab = doc.querySelector("#repo-files-table");
      if (repoTab?.children.length == 2) {
        // 最新的提交
        final tHeadTrs = repoTab!.children[0].querySelectorAll("thead tr th");
        if (tHeadTrs.length == 3) {
          final head = <String, dynamic>{};
          final first = tHeadTrs[0];
          head["image_url"] = first.querySelector("img")?.attributes['src'];
          head["user_name"] = first.querySelector("strong")?.text.trim();
          head["commit_id"] =
              first.querySelector("a.ui.sha.label")?.text.trim();
          head["message"] = first.querySelector("span")?.text.trim();

          final time = tHeadTrs[2].querySelector("span");
          //head["time"] = HttpDate.parse(
          //    (time?.attributes['title'] ?? '').replaceFirst("CST", "GMT"));
          head["time"] = time?.attributes['title']?.replaceFirst("CST", "GMT");
          head["time_label"] = time?.text.trim();

          json["last_commit"] = head;
        }

        // 下面的列表
        final tBodyTrs = repoTab.children[1].querySelectorAll("tbody tr");
        final files = <Map<String, dynamic>>[];
        for (var element in tBodyTrs) {
          final file = <String, dynamic>{};

          final first = element.children[0];

          file["name"] = first.text.trim();
          file["is_folder"] = first
              .querySelector("span.octicon ")
              ?.className
              .contains("file-directory");
          file['link'] = first.querySelector("a")?.attributes['href'];
          file["message"] = element.children[1].text
              .trim()
              .split("\n")
              .map((e) => e.trim())
              .toList();

          final time = element.children[2].querySelector("span");
          file["time"] = time?.attributes['title']?.replaceFirst("CST", "GMT");
          // file["time"] = HttpDate.parse(
          //     (time?.attributes['title'] ?? '').replaceFirst("CST", "GMT"));
          file["time_label"] = time?.text.trim();

          files.add(file);
        }
        json["files"] = files;
      }
    }
    return null;
  }

  static Future getHome() async {
    // final reg = RegExp(
    //     r'\t<div class="ui negative message">\n\t\t<p>(.+?)</p>\n\t</div>');
    // final m = reg.firstMatch(res.data ?? '');
    // print('msg: ${m?.group(1)}');
    /// 登录成功，拉取数据
    final res = await _dio.get('http://localhost:3000/');
    if (res.statusCode == HttpStatus.ok) {
      final doc = html.parse(res.data);

      final json = <String, dynamic>{};

      /// 头像
      json['image_url'] =
          doc.querySelector("span.text.avatar img")?.attributes['src'];

      // print("=================================================");
      // var repoEls = doc.querySelectorAll(".active ul.repo-owner-name-list li");
      // repoEls.forEach((element) {
      //   final isPrivate = element.attributes['class'] == 'private';
      //   print("isPrivate=$isPrivate");
      //   final href = element.querySelector("a")?.attributes['href'];
      //   print("href=$href");
      //   var itemName = element.querySelector("a strong.item-name")?.text;
      //   print("name=$itemName");
      //   var star =
      //       element.querySelector("span.ui.right.text.light.grey")?.text.trim();
      //   print("star=$star");
      // });
      // print("=================================================");
      // repoEls = doc.querySelectorAll("#collaborative-repo-list li");
      // print("repoEls.len=${repoEls.length}");
      // repoEls.forEach((element) {
      //   final isPrivate = element.attributes['class'] == 'private';
      //   print("isPrivate=$isPrivate");
      //   final href = element.querySelector("a")?.attributes['href'];
      //   print("href=$href");
      //   var itemName = element.querySelector("a strong.item-name")?.text;
      //   print("name=$itemName");
      //   var star =
      //       element.querySelector("span.ui.right.text.light.grey")?.text.trim();
      //   print("star=$star");
      // });
      // print("=================================================");
      //

      final repoEls = doc.querySelectorAll("div.ten.wide.column div.news");
      final news = <Map<String, dynamic>>[];
      for (var element in repoEls) {
        final message = <String, dynamic>{};

        message["image_url"] =
            element.querySelector("img.ui.avatar.image")?.attributes['src'];

        message["content"] = element
            .querySelector("div.ui.grid div.ui.fifteen.wide.column div p")
            ?.text
            .split("\n")
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        final time = element.querySelector(
            "div.ui.grid div.ui.fifteen.wide.column p.text.italic.light.grey span");
        message["time"] = time?.attributes['title']?.replaceFirst("CST", "GMT");
        // message["time"] = HttpDate.parse(
        //     ();
        message["time_label"] = time?.text.trim();

        news.add(message);
      }

      json["news"] = news;
    }
  }

  static Future getRepoIssues(
      String userName, String repoName, bool isClosed) async {
    // http://localhost:3000/$userName/$repoName/issues isClosed ? '?type=all&sort=&state=closed&labels=0&milestone=0&assignee=0' : '';
    // http://localhost:3000/$userName/$repoName/issues isClosed ? '?state=closed' : '';
  }

  static Future getRepoPulls(
      String userName, String repoName, bool isClosed) async {
    // http://localhost:3000/$userName/$repoName/pulls isClosed ? ?type=all&sort=&state=closed&labels=0&milestone=0&assignee=0 : '';
    // http://localhost:3000/$userName/$repoName/pulls
  }

  static Future getIssues() async {
    // http://localhost:3000/issues
    // css: div.issue.list > li.item

    //div.ui.label
    // div.title
    // span.comment.ui.right
    // .desc
    //
    //
    // span.ui.right a.ui.label
    // http://localhost:3000/issues?type=your_repositories&repo=0&sort=&state=closed
  }

  static Future getPulls() async {
    // http://localhost:3000/pulls
    // http://localhost:3000/pulls?type=your_repositories&repo=0&sort=&state=closed
  }
}
