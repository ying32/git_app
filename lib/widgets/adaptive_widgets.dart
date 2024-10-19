import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gogs_app/utils/build_context_helper.dart';

TextStyle iOSPlaceholderStyle = const TextStyle(
  fontWeight: FontWeight.w400,
  color: CupertinoColors.placeholderText,
);

class AdaptiveTextField extends StatelessWidget {
  const AdaptiveTextField({
    super.key,
    this.controller,
    this.autofocus = false,
    this.readOnly = false,
    this.placeholder,
    this.style,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.obscureText = false,
    this.maxLength,
    this.onChanged,
    this.onEditingComplete,
    this.useUnderlineInputBorder = true,
    this.clearButtonMode = OverlayVisibilityMode.never,
  });

  final TextEditingController? controller;
  final bool autofocus;
  final bool readOnly;
  final String? placeholder;
  final TextStyle? style;
  final int? maxLines;

  final Widget? prefixIcon;
  final Widget? suffixIcon;

  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextDirection? textDirection;
  final TextAlign textAlign; // = TextAlign.start;
  final TextAlignVertical? textAlignVertical;
  final bool obscureText; // = false;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  final VoidCallback? onEditingComplete;

  final bool useUnderlineInputBorder;

  // only iOS
  final OverlayVisibilityMode clearButtonMode;

  @override
  Widget build(BuildContext context) {
    return context.platformIsIOS
        ? CupertinoTextField(
            controller: controller,
            autofocus: autofocus,
            placeholder: placeholder,
            maxLines: maxLines,
            style: style,
            prefix: prefixIcon,
            suffix: suffixIcon,
            placeholderStyle:
                iOSPlaceholderStyle.copyWith(fontSize: style?.fontSize),
            focusNode: focusNode,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            textDirection: textDirection,
            textAlign: textAlign,
            textAlignVertical: textAlignVertical,
            obscureText: obscureText,
            maxLength: maxLength,
            onChanged: onChanged,
            onEditingComplete: onEditingComplete,
            clearButtonMode: clearButtonMode,
            decoration: useUnderlineInputBorder
                ? const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: Color(0x33000000))))
                : null,
          )
        : TextField(
            controller: controller,
            autofocus: autofocus,
            maxLines: maxLines,
            style: style,
            decoration: InputDecoration(
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              hintText: placeholder,
              border:
                  useUnderlineInputBorder ? const UnderlineInputBorder() : null,
            ),
            focusNode: focusNode,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            textDirection: textDirection,
            textAlign: textAlign,
            textAlignVertical: textAlignVertical,
            obscureText: obscureText,
            maxLength: maxLength,
            onChanged: onChanged,
            onEditingComplete: onEditingComplete,
          );
  }
}

class AdaptiveTextFormField extends StatelessWidget {
  const AdaptiveTextFormField({
    super.key,
    this.controller,
    this.autofocus = false,
    this.readOnly = false,
    this.placeholder,
    this.style,
    this.maxLines,
    this.minLines,
    this.prefixIcon,
    this.textInputAction,
    this.onSaved,
    this.validator,
    this.focusNode,
    this.keyboardType,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.obscureText = false,
    this.maxLength,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
  });

  final TextEditingController? controller;
  final bool autofocus;
  final bool readOnly;
  final String? placeholder;
  final TextStyle? style;
  final int? maxLines;
  final int? minLines;
  final FormFieldSetter<String?>? onSaved;
  final FormFieldValidator<String?>? validator;

  final Widget? prefixIcon;
  final TextInputAction? textInputAction;

  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final bool obscureText;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return context.platformIsIOS
        ? CupertinoTextFormFieldRow(
            controller: controller,
            autofocus: autofocus,
            placeholder: placeholder,
            maxLines: maxLines,
            minLines: minLines,
            style: style,
            prefix: prefixIcon,
            textInputAction: textInputAction,
            validator: validator,
            placeholderStyle:
                iOSPlaceholderStyle.copyWith(fontSize: style?.fontSize),
            onSaved: onSaved,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textDirection: textDirection,
            textAlign: textAlign,
            textAlignVertical: textAlignVertical,
            obscureText: obscureText,
            maxLength: maxLength,
            onChanged: onChanged,
            onEditingComplete: onEditingComplete,
            onFieldSubmitted: onFieldSubmitted,
          )
        : TextFormField(
            controller: controller,
            autofocus: autofocus,
            maxLines: maxLines,
            minLines: minLines,
            style: style,
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: prefixIcon,
              hintText: placeholder,
            ),
            textInputAction: textInputAction,
            onSaved: onSaved,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textDirection: textDirection,
            textAlign: textAlign,
            textAlignVertical: textAlignVertical,
            obscureText: obscureText,
            maxLength: maxLength,
            onChanged: onChanged,
            onEditingComplete: onEditingComplete,
            onFieldSubmitted: onFieldSubmitted,
          );
  }
}

enum _AdaptiveButtonType { text, icon, outlined }

class AdaptiveButton extends StatelessWidget {
  final Widget child;
  final Color? color;
  final BoxBorder? border;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onPressed;
  final double? width;

  final _AdaptiveButtonType _adaptiveButtonType;

  const AdaptiveButton({
    super.key,
    required this.child,
    this.color,
    this.border,
    this.borderRadius,
    this.padding,
    this.onPressed,
  })  : _adaptiveButtonType = _AdaptiveButtonType.text,
        width = null;

  const AdaptiveButton.icon({
    super.key,
    required this.child,
    this.color,
    this.border,
    this.borderRadius,
    this.padding,
    this.onPressed,
  })  : _adaptiveButtonType = _AdaptiveButtonType.icon,
        width = null;

  const AdaptiveButton.outlined({
    super.key,
    required this.child,
    this.color,
    this.border,
    this.borderRadius = const BorderRadius.all(Radius.circular(3.0)),
    this.padding,
    this.onPressed,
    this.width,
  }) : _adaptiveButtonType = _AdaptiveButtonType.outlined;

  Widget _buildButton() {
    Widget widget = switch (_adaptiveButtonType) {
      _AdaptiveButtonType.text => TextButton(
          onPressed: onPressed,
          child: child,
        ),
      _AdaptiveButtonType.icon => IconButton(onPressed: onPressed, icon: child),
      _AdaptiveButtonType.outlined => MaterialButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          // style: const ButtonStyle(
          //   shape: MaterialStatePropertyAll(StadiumBorder()),
          //   side: MaterialStatePropertyAll(BorderSide.none),
          //   splashFactory: InkSparkle.constantTurbulenceSeedSplashFactory,
          // ),
          child: child,
        ),
      //  _ => const SizedBox(),
    };
    return widget;
  }

  @override
  Widget build(BuildContext context) {
    // 为了2种样式切换，iOS下不再使用原来的背景和边框
    Widget widget = context.platformIsIOS
        ? CupertinoButton(
            //color: color,
            borderRadius: null,
            //  borderRadius ?? const BorderRadius.all(Radius.circular(8.0)),

            onPressed: onPressed,
            padding: EdgeInsets.zero,
            child: child,
          )
        : _buildButton();
    if (padding != null) {
      widget = Padding(padding: padding!, child: widget);
    }
    if (color != null || borderRadius != null || border != null) {
      final borderStyle = border ??
          (_adaptiveButtonType == _AdaptiveButtonType.outlined
              ? Border.all(
                  color: context.theme.colorScheme.onSurface.withOpacity(0.12))
              : null);
      widget = Container(
          width: width,
          decoration: BoxDecoration(
            color: color,
            border: borderStyle,
            borderRadius: borderRadius,
          ),
          child: widget);
    }
    return widget;
  }
}

class AdaptiveIconButton extends StatelessWidget {
  const AdaptiveIconButton({
    super.key,
    required this.icon,
    this.color,
    this.borderRadius,
    this.onPressed,
  });

  final Widget icon;

  /// only iOS
  final Color? color;

  /// only iOS
  final BorderRadius? borderRadius;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => context.platformIsIOS
      ? CupertinoButton(
          color: color,
          onPressed: onPressed,
          borderRadius:
              borderRadius ?? const BorderRadius.all(Radius.circular(8.0)),
          padding: EdgeInsets.zero,
          child: icon,
        )
      : IconButton(onPressed: onPressed, icon: icon);
}

class AdaptiveTextButton extends StatelessWidget {
  const AdaptiveTextButton({
    super.key,
    required this.child,
    this.color,
    this.borderRadius,
    this.onPressed,
  });

  final Widget child;

  /// only iOS
  final Color? color;

  /// only iOS
  final BorderRadius? borderRadius;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => context.platformIsIOS
      ? CupertinoButton(
          color: color,
          onPressed: onPressed,
          borderRadius:
              borderRadius ?? const BorderRadius.all(Radius.circular(8.0)),
          padding: EdgeInsets.zero,
          child: child,
        )
      : TextButton(onPressed: onPressed, child: child);
}
