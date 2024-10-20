import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:git_app/models/app_model.dart';
import 'package:git_app/utils/app_config.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:git_app/utils/global_navigator.dart';
import 'package:git_app/utils/utils.dart';
import 'package:provider/provider.dart';

import 'navigation.dart';

/// windows用于pc端下支持手势的
class CustomMaterialScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

// useMaterial3: true,
// pageTransitionsTheme: const PageTransitionsTheme(
//     builders: <TargetPlatform, PageTransitionsBuilder>{
//       // 老版本他默认用的这个效果，但新版本他改为了ZoomPageTransitionsBuilder，感觉还是Fade的效果好
//       TargetPlatform.android: CupertinoPageTransitionsBuilder(),
//       TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
//       TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
//       TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
//     }),

// appBarTheme: const AppBarTheme(
//   systemOverlayStyle: SystemUiOverlayStyle(
//     statusBarColor: Colors.transparent, // 全局设置透明
//     // 根据不同样式显示反色标题栏的字体
//     statusBarIconBrightness: _statusBarBrightness,
//     systemNavigationBarIconBrightness: _statusBarBrightness,
//     statusBarBrightness: _statusBarBrightness,
//
//     // systemNavigationBarColor:
//     //  light:黑色图标 dark：白色图标
//     //在此处设置statusBarIconBrightness为全局设置
//   ),
// ),

class GogsApp extends StatelessWidget {
  const GogsApp({super.key});

  static final _fontFamily = Platform.isWindows ? '微软雅黑' : null;

  static const _themeColor = CupertinoColors.systemBlue;
  static const _platform = TargetPlatform.iOS;
  // static const _platform = TargetPlatform.android;

  static const cupertinoLightTheme = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: _themeColor,
  );

  static const cupertinoDarkTheme = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: _themeColor,
  );

  Widget _buildMaterialApp() => ChangeNotifierProvider<AppModel>(
        create: (_) => AppModel(AppConfig.instance.themeMode),
        child: Builder(builder: (context) {
          return MaterialApp(
            title: 'GitApp',
            navigatorKey: GlobalNavigator.navigatorKey,
            themeMode: context.watch<AppModel>().themeMode, // ThemeMode.dark,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: _fontFamily,
              colorScheme: ColorScheme.fromSeed(
                  seedColor: _themeColor,
                  primary: _themeColor,
                  brightness: Brightness.light),
              platform: _platform,
              useMaterial3: false,
            ),
            darkTheme: ThemeData(
              fontFamily: _fontFamily,
              colorScheme: ColorScheme.fromSeed(
                  seedColor: _themeColor,
                  primary: _themeColor,
                  brightness: Brightness.dark),
              platform: _platform,
              useMaterial3: false,
            ),
            scrollBehavior: isDesktop ? CustomMaterialScrollBehavior() : null,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            locale: const Locale("zh"),
            supportedLocales: const <Locale>[
              Locale('zh', 'CH'),
              Locale('en', 'US'),
            ],

            // routes: {
            // "/home": (context) => const HomePage(),
            // "/my_repos": (context) => const RepositoriesPage(),
            // "/my_orgs": (context) => const OrganizationsPage(),
            // "/login": (context) => const LoginPage(),
            // },
            home: const NavigationPage(),

            navigatorObservers: [FlutterSmartDialog.observer],
            builder: FlutterSmartDialog.init(
                // builder: (BuildContext context, Widget? child) => child!),
                builder: (BuildContext context, Widget? child) =>
                    _platform == TargetPlatform.iOS
                        ? CupertinoTheme(
                            data: context.isDark
                                ? cupertinoDarkTheme
                                : cupertinoLightTheme,
                            child: child!)
                        : child!),
            // onGenerateRoute: (RouteSettings settings) {
            //   switch (settings.name) {
            //     case '/':
            //       // return MaterialPageRoute(
            //       return MaterialWithModalsPageRoute(
            //           builder: (_) => const NavigationPage(),
            //           settings: settings); //const NavigationPage()
            //   }
            //   return null;
            // },
          );
        }),
      );

  @override
  Widget build(BuildContext context) => _buildMaterialApp();
}
