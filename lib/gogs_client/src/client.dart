part of gogs.client;

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
    required this.succeed,
    required this.statusMessage,
    required this.data,
  });

  final bool succeed;
  final String? statusMessage;
  final T? data;

  static bool _isOK(Response resp) => switch (resp.statusCode) {
        HttpStatus.ok || // GET
        HttpStatus.created || // POST or PATCH
        HttpStatus.accepted || // POST or PATCH
        HttpStatus.noContent => // DELETE
          true,
        _ => false
      };

  RESTResult.fromResponse(Response resp, RESTJsonDecoder<T>? decoder)
      : succeed = _isOK(resp),
        statusMessage = resp.statusMessage,
        data = _isOK(resp)
            ? (decoder == null ? resp.data : decoder(resp.data))
            : null;

  RESTResult.fromErrorMessage(String msg)
      : succeed = false,
        statusMessage = msg,
        data = null;
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
    HttpHeaders.userAgentHeader: 'Gogs_client/1.0',
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
      final resp = _cache.load(_getRequestCacheKey(options));
      if (resp != null && resp is Response) {
        if (kDebugMode) {
          // resp.headers['']
          //print("time=${HttpDate.parse('Fri, 11 Oct 2024 07:27:57 GMT')}");
          print('from cache, key = ${_getRequestCacheKey(options)}');
          print(
              "==============================================================");
        }
        return handler.resolve(resp);
      }
    }
    return handler.next(options);
  }

  ///
  void _onResponse(Response response, ResponseInterceptorHandler handler) {
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
    // 缓存get请求，以uri为key
    if (response.requestOptions.method == "GET") {
      if (!response.requestOptions.isNocache) {
        _cache.store(_getRequestCacheKey(response.requestOptions), response);
      }
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

  Options? _getForceOptions(Options? options, bool? force) {
    if (force != null) {
      if (options != null) {
        options.extra ??= <String, dynamic>{};
        options.extra!["force"] = force;
      } else {
        options ??= Options(extra: {"force": force});
      }
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
    RESTJsonDecoder<T>? decoder,
  }) =>
      _execRequest<T>(
          () => _dio.get(_checkUrl(path),
              queryParameters: queryParameters,
              options: _getForceOptions(options, force)),
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
