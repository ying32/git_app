part of gogs.client;

/// 根据repose的header中contentType解码文本
String? decodeResponseText(List<int> data, String? contentType) {
  if (contentType != null) {
    String charset = "";
    final idx = contentType.lastIndexOf("charset=");
    if (idx != -1) {
      charset = contentType.substring(idx + 8).trim();
    }
    Encoding? encoding;
    if (charset.startsWith("utf-8")) {
      encoding = utf8;
    } else if (charset.startsWith("utf-16")) {
      encoding = utf16;
    } else if (charset.startsWith("utf-32")) {
      encoding = utf32;
    } else {
      encoding = systemEncoding;
    }
    try {
      return encoding.decode(data);
    } catch (e) {
      //
    }
  }
  return null;
}

class GogsRESTClient extends SimpleRESTClient {
  GogsRESTClient() {
    user = GogsUser(this);
    repos = GogsRepos(this);
    issues = GogsIssues(this);
  }

  /// 用户接口
  late final GogsUser user;

  /// 仓库接口
  late final GogsRepos repos;

  /// issues接口
  late final GogsIssues issues;
}

typedef RESTJsonDecoder<T> = T Function(dynamic);

extension _RequestOptionsHelper on RequestOptions {
  /// 是否强制
  bool get isForce => extra['force'] ?? false;

  /// 无缓存
  bool get isNocache => extra['nocache'] ?? false;
}

// extension type xx(String text) implements String {}

/// RESTResult返回的
class RESTResult<T> {
  const RESTResult({
    required this.statusCode,
    required this.statusMessage,
    required this.data,
    this.contentType,
  });

  final int statusCode;
  final String? statusMessage;
  final T? data;
  final String? contentType;

  bool get succeed => _isOK(statusCode);

  static bool _isOK(int? statusCode) => switch (statusCode) {
        HttpStatus.ok || // GET
        HttpStatus.created || // POST or PATCH
        HttpStatus.accepted || // POST or PATCH
        HttpStatus.noContent || // DELETE
        HttpStatus.notModified => // from cache
          true,
        _ => false
      };

  RESTResult.fromResponse(Response resp, RESTJsonDecoder<T>? decoder)
      : statusCode = resp.statusCode ?? 0,
        statusMessage = resp.statusMessage,
        data = _isOK(resp.statusCode)
            ? (decoder == null ? resp.data : decoder(resp.data))
            : null,
        contentType = resp.headers.value(HttpHeaders.contentTypeHeader)?.trim();

  RESTResult.fromErrorMessage(String msg)
      : statusCode = 0,
        statusMessage = msg,
        data = null,
        contentType = null;
}

typedef FutureRESTResult<T> = Future<RESTResult<T>>;

/// 简易的REST客户端
class SimpleRESTClient {
  SimpleRESTClient() {
    /// 处理下url
    _dio = Dio(
      BaseOptions(
        headers: _baseHeaders,
        responseType: ResponseType.json,
        validateStatus: (status) {
          return true; // status != null && status >= 200 && status <= 500;
        },
        receiveDataWhenStatusError: true,
        //responseDecoder: responseDecode,
      ),
    );

    // cookie管理的
    _cookieJar = DefaultCookieJar();
    _dio.interceptors.add(CookieManager(_cookieJar));

    // 请求拦截的，主要测试用吧
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
            onRequest: _onRequest, onResponse: _onResponse, onError: _onError),
      );
    }
  }

  /// 基础头
  static const _baseHeaders = {
    HttpHeaders.userAgentHeader: 'GitApp_client/1.0',
    HttpHeaders.acceptEncodingHeader: 'gzip, deflate',
    HttpHeaders.acceptLanguageHeader: 'zh-CN,zh;q=0.9,en-US,en;q=0.8',
  };

  static const _tokenKey = "rest_token";

  /// 基础url

  late Uri _baseUri;
  Uri get baseUri => _baseUri;

  String _host = "";
  String get host => _host;

  String _token = "";
  String get token => _token;

  /// cookies管理
  late final CookieJar _cookieJar;

  /// 网络请求的
  late final Dio _dio;

  /// 缓存管理，只缓存GET的
  final _cache = _GogsCache();

  /// 移除缓存
  void removeCache(String key) {
    _cache.remove(key);
  }

  /// 设置gogs服务端的主机
  void setServerHost(String host) {
    var newUrl = host.trim();
    if (newUrl.isEmpty) return;
    if (newUrl.endsWith("/")) newUrl = newUrl.substring(0, newUrl.length - 1);
    _baseUri = Uri.parse(newUrl);
    _dio.options.baseUrl = "$newUrl/api/v1/";
    _host = host;
  }

  /// 合并
  String? mergeUrl(String? url) =>
      url != null ? _baseUri.resolve(url).toString() : null;

  String _checkUrl(String url) {
    if (url.startsWith("/")) return url;
    return "/$url";
  }

  /// 生成一个缓存key 以request的path+query值
  String _getRequestCacheKey(RequestOptions options) =>
      // 这里不取uri.path的值
      "${options.path}${options.uri.hasQuery ? '?${options.uri.query}' : ''}";

  /// 将token设置到[_dio]头中
  void _setHeaderToken(String token) {
    _token = token;
    _dio.options.headers[HttpHeaders.authorizationHeader] = "token $token";
  }

  FutureOr<String?> responseDecode(
    List<int> responseBytes,
    RequestOptions options,
    ResponseBody responseBody,
  ) {
    if (kDebugMode) {
      print(
          "==========================responseDecode==========================");
      print("==============================================================");
    }
    return null;
  }

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print("==========================Request==========================");
      print("method:${options.method}");
      print("uri:${options.uri}");
      print(
          "uri: host=${options.uri.host}, path=${options.uri.path}, query=${options.uri.query}, fragment=${options.uri.fragment}");
      print("force:${options.isForce}");
      print("path:${options.path}");
      print("headers:${options.headers}");
      print("data=${options.data}");
      print("queryParameters=${options.queryParameters}");
      print("==============================================================");
    }
    // 从缓存中加载，如果force标识为true则不加载缓存
    if (options.method == "GET" && !options.isForce && !options.isNocache) {
      final key = _getRequestCacheKey(options);
      final cache = _cache.load(key);
      if (cache != null && cache.resp is Response) {
        // 这里要检测有没有过期
        //if(cache.expired.su)
        if (DateTime.now().compareTo(cache.expired) <= 0) {
          final resp = cache.resp;
          // 修改结果为304
          resp.statusCode = HttpStatus.notModified;
          if (kDebugMode) {
            // resp.headers['']
            //print("time=${HttpDate.parse('Fri, 11 Oct 2024 07:27:57 GMT')}");
            print('from cache, key = $key');
            print(
                "==============================================================");
          }
          return handler.resolve(resp);
        } else {
          _cache.remove(key);
        }
      }
    }
    return handler.next(options);
  }

  /// 返回太多无用数据了，所以这里干掉一些
  void _cleanJsonFields(Response response) {
    if (response.requestOptions.responseType != ResponseType.json) {
      return;
    }
    void processData(dynamic a) {
      if (a == null) return;
      if (a is Map) {
        a.remove("_links");
        a.remove("url");
        a.remove("html_url");
        a.remove("git_url");
        a.remove("download_url");
        a.remove("submodule_git_url");
        a.remove("ssh_url");
        a.remove("languages_url");
        a.remove("clone_url");
        a.remove("original_url");
        a.remove("link");
        a.remove("permissions");
        a.remove("internal_tracker");
        processData(a['owner']);
        processData(a['act_user']);
        processData(a['repo']);
        // 移除文件内容的
        if (a['type'] == 'file' && a['encoding'] != null) {
          a.remove('content');
        }
      }
    }

    if (response.data is Map || response.data is List) {
      if (response.data is List) {
        for (final a in response.data) {
          processData(a);
        }
      } else {
        processData(response.data);
      }
    }
  }

  ///
  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    _cleanJsonFields(response);
    if (kDebugMode) {
      print("==========================Response==========================");
      print("realUri=${response.requestOptions.uri}");
      print("force:${response.requestOptions.isForce}");
      //print("realUri=${response.realUri}");
      print("statusCode=${response.statusCode}");
      print("statusMessage=${response.statusMessage}");
      print("headers=${response.headers}");
      // print("headers=${response.requestOptions.path}");
      if (response.requestOptions.responseType == ResponseType.json) {
        print(jsonEncode(response.data));
      }
      print("==============================================================");
    }
    // 缓存get请求，状态code必须为200，且为GET方法的，并且扩展中没有nocache标识
    if (response.statusCode == HttpStatus.ok &&
        response.requestOptions.method == "GET" &&
        !response.requestOptions.isNocache) {
      _cache.store(_getRequestCacheKey(response.requestOptions), response);
    }
    return handler.next(response);
  }

  void _onError(DioException error, ErrorInterceptorHandler handler) {
    // if (kDebugMode) {
    //   print("==========================error==========================");
    //   print("statusCode: ${error.response?.statusCode}");
    //   print("statusMessage: ${error.response?.statusMessage}");
    //   print("error: ${error.error}");
    //   print("type: ${error.type}");
    //   print("==============================================================");
    // }
    return handler.next(error);
  }

  /// 从配置文件中加载保存的token
  Future<bool> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null && token.isNotEmpty) {
      _setHeaderToken(token);
      return true;
    }
    return false;
  }

  /// 保存token
  Future<bool> authorize(String token) async {
    _setHeaderToken(token);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_tokenKey, token);
    return true;
  }

  /// 取消token
  Future<void> unAuthorize([bool removeConfig = false]) async {
    _dio.options.headers.remove(HttpHeaders.authorizationHeader);
    if (removeConfig) {
      final prefs = await SharedPreferences.getInstance();
      prefs.remove(_tokenKey);
    }
    _cache.clear();
  }

  /// token已经设置
  bool get isAuthorized {
    final key =
        _dio.options.headers[HttpHeaders.authorizationHeader] as String?;
    return key != null && key.isNotEmpty;
  }

  Options? _getOptions(Options? options, bool? force, bool? nocache) {
    if (force != null || nocache != null) {
      options ??= Options(extra: {});
      options.extra ??= {};
      if (force != null) options.extra!["force"] = force;
      if (nocache != null) options.extra!["nocache"] = nocache;
    }
    return options;
  }

  /// 执行请求并一个根据response处理返回结果
  FutureRESTResult<T> _execRequest<T>(
      AsyncValueGetter<Response> request, RESTJsonDecoder<T>? decoder) async {
    try {
      if (kDebugMode) {
        print("result type = ${T.toString()}");
      }
      final resp = await request();
      return RESTResult<T>.fromResponse(resp, decoder);
    } on SocketException catch (e) {
      return RESTResult<T>.fromErrorMessage(e.osError?.message ?? e.message);
    } catch (e) {
      return RESTResult<T>.fromErrorMessage(e.toString());
    }
  }

  /// 获取
  FutureRESTResult<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool? force,
    bool? nocache,
    RESTJsonDecoder<T>? decoder,
  }) =>
      _execRequest<T>(
          () => _dio.get(_checkUrl(path),
              queryParameters: queryParameters,
              options: _getOptions(options, force, nocache)),
          decoder);

  /// 新建
  FutureRESTResult<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    RESTJsonDecoder<T>? decoder,
  }) async {
    final res = await _execRequest<T>(
        () => _dio.post(_checkUrl(path),
            queryParameters: queryParameters, data: data, options: options),
        decoder);
    // 一个二逼的移除缓存方法
    if (res.succeed) removeCache(path);
    return res;
  }

  /// 编辑
  FutureRESTResult<T> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    RESTJsonDecoder<T>? decoder,
  }) async {
    final res = await _execRequest<T>(
        () => _dio.patch(_checkUrl(path),
            queryParameters: queryParameters, data: data, options: options),
        decoder);

    if (res.succeed) {
      // 一个二逼的移除缓存方法
      // 比如： 当前path为`/issues/12`，更新数据后，此path的数据与parent（`/issues`）都会受影响，
      // 所以删除2个缓存。
      removeCache(path);
      //todo: 这里还要判断有没有 queryParameters
      removeCache(path.substring(0, path.lastIndexOf("/")));
    }
    return res;
  }

  /// 删除
  FutureRESTResult<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final res = await _execRequest<T>(
        () => _dio.delete(_checkUrl(path),
            queryParameters: queryParameters, data: data, options: options),
        null);
    // 一个二逼的移除缓存方法
    if (res.succeed) removeCache(path);
    return res;
  }
}
