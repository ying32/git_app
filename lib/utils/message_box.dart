import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:gogs_app/utils/build_context_helper.dart';
import 'package:gogs_app/utils/global_navigator.dart';
import 'package:gogs_app/widgets/adaptive_widgets.dart';

void showToast(String msg) => SmartDialog.showToast(msg);

Future<void> showMessage(String msg, {String? title, BuildContext? context}) =>
    showAdaptiveDialog(
        context: context ?? GlobalNavigator.context!,
        builder: (BuildContext context) {
          return AlertDialog.adaptive(
            title: Text(title ?? ''),
            content: Text(msg),
            actions: [
              AdaptiveButton(
                child: Text(context.platformIsIOS ? '好' : '确定'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        });
