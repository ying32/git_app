import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:git_app/utils/build_context_helper.dart';
import 'package:markdown_toolbar/markdown_toolbar.dart';

import 'adaptive_widgets.dart';
import 'platform_page_scaffold.dart';

typedef EditCompletedCallback<T> = Future<T?> Function(
    String? title, String? content);

class EditorPage extends StatefulWidget {
  const EditorPage({
    super.key,
    required this.title,
    required this.trailingTitle,
    required this.contentPlaceholder,
    this.showTitleEdit = true,
    required this.onEditCompleted,
    this.defaultTitle,
    this.defaultContent,
    this.contentTextInputAction = TextInputAction.newline,
  });

  final Widget title;
  final Widget trailingTitle;
  final String contentPlaceholder;
  final bool showTitleEdit;
  final EditCompletedCallback onEditCompleted;
  final String? defaultTitle;
  final String? defaultContent;
  final TextInputAction? contentTextInputAction;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late final FocusNode _focusNode;
  String? _title;
  String? _content;
  final _submitting = ValueNotifier(false);
  late final ValueNotifier<bool> _contentHaveFocus;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    if (widget.showTitleEdit) {
      _contentHaveFocus = ValueNotifier(false);
      _focusNode.addListener(_onListener);
    }
    if (widget.defaultTitle != null) {
      _titleController.text = widget.defaultTitle ?? '';
    }
    if (widget.defaultContent != null) {
      _contentController.text = widget.defaultContent ?? '';
    }
  }

  void _onListener() {
    //???
    if (!FocusScope.of(context).hasPrimaryFocus) {
      _contentHaveFocus.value = _focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    _focusNode.dispose();
    if (widget.showTitleEdit) {
      _focusNode.removeListener(_onListener);
      _contentHaveFocus.dispose();
    }
    _submitting.dispose();
    super.dispose();
  }

  String? _validatorTitle(String? value) {
    if (value?.isEmpty ?? true) {
      return '标题不能为空';
    }
    return null;
  }

  Widget _buildTextField(
    String hintText, {
    FocusNode? focusNode,
    TextEditingController? controller,
    bool autofocus = false,
    TextStyle? style,
    TextStyle? hintStyle,
    FormFieldValidator<String>? validator,
    required FormFieldSetter<String> onSaved,
    TextInputAction? textInputAction,
  }) =>
      AdaptiveTextFormField(
        focusNode: focusNode,
        controller: controller,
        autofocus: autofocus,
        placeholder: hintText,
        style: style,
        onSaved: onSaved,
        textInputAction: textInputAction,
      );

  void _doCancel() => Navigator.of(context).pop();

  void _doSubmit() {
    if (_formKey.currentState?.validate() == true) {
      _formKey.currentState?.save();
      _submitting.value = true;
      widget.onEditCompleted(_title, _content).then((value) {
        if (value != null) {
          Navigator.of(context).pop(value);
        }
      }).whenComplete(() => setState(() {
            _submitting.value = false;
          }));
    }
  }

  Widget _buildForm() {
    Widget child = _buildTextField(
      focusNode: _focusNode,
      controller: _contentController,
      widget.contentPlaceholder,
      autofocus: !widget.showTitleEdit,
      hintStyle: const TextStyle(
        fontWeight: FontWeight.w400,
        color: CupertinoColors.placeholderText,
      ),
      onSaved: (String? value) {
        _content = value;
      },
      textInputAction: widget.contentTextInputAction,
    );
    if (widget.showTitleEdit) {
      child = Column(
        // mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextField('标题',
              controller: _titleController,
              autofocus: true,
              style: const TextStyle(fontSize: 22),
              hintStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 22,
                color: CupertinoColors.placeholderText,
              ),
              validator: _validatorTitle, onSaved: (String? value) {
            _title = value;
          }),
          const SizedBox(height: 10),
          child,
        ],
      );
    }
    return Form(key: _formKey, child: child);
  }

  Widget _buildRightButton() {
    return ValueListenableBuilder(
      valueListenable: _submitting,
      builder: (BuildContext context, bool value, Widget? child) {
        if (value) return const CircularProgressIndicator.adaptive();
        return widget.trailingTitle;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget navLeft = AdaptiveButton(
      onPressed: _doCancel,
      child: const Text('取消'),
    );
    Widget navRight = ValueListenableBuilder(
      valueListenable:
          widget.showTitleEdit ? _titleController : _contentController,
      builder: (BuildContext context, TextEditingValue value, Widget? child) {
        return AdaptiveButton(
            onPressed: value.text.isNotEmpty ? _doSubmit : null,
            child: _buildRightButton());
      },
    );

    Widget mkToolBar = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: MarkdownToolbar(
        // iconSize: 20,
        width: 40,
        height: 40,
        runSpacing: 2,
        spacing: 3,
        collapsable: false,
        borderRadius: BorderRadius.circular(0),
        useIncludedTextField: false,
        controller: _contentController,
        focusNode: _focusNode,
        backgroundColor:
            context.isLight ? const Color(0xFFEEEEEE) : Colors.black12,
        iconColor: context.isLight ? const Color(0xFF303030) : Colors.white60,
        headingTooltip: '标题',
        boldTooltip: '加粗',
        italicTooltip: '斜体',
        strikethroughTooltip: '删除线',
        linkTooltip: '超链接',
        imageTooltip: '图像',
        codeTooltip: '代码',
        bulletedListTooltip: '项目符号列表',
        numberedListTooltip: '编号列表',
        checkboxTooltip: '复选框',
        quoteTooltip: '引用',
        horizontalRuleTooltip: '横线',
      ),
    );

    return PlatformPageScaffold(
      // materialAppBar: () => AppBar(
      //   leading: navLeft,
      //   title: widget.title,
      //   centerTitle: true,
      //   actions: [navRight],
      // ),
      // cupertinoNavigationBar: () => CupertinoNavigationBar(
      //   leading: navLeft,
      //   middle: widget.title,
      //   trailing: navRight,
      //   previousPageTitle: context.previousPageTitle,
      //   // border: null,
      //   transitionBetweenRoutes: false,
      // ),
      appBar: PlatformPageAppBar(
        leading: navLeft,
        title: widget.title,
        centerTitle: true,
        actions: [navRight],
        previousPageTitle: context.previousPageTitle,
        transitionBetweenRoutes: false,
      ),

      bottomBar: !widget.showTitleEdit
          ? mkToolBar
          : ValueListenableBuilder<bool>(
              valueListenable: _contentHaveFocus,
              builder: (_, bool value, __) =>
                  value ? mkToolBar : const SizedBox(),
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        child: SingleChildScrollView(child: _buildForm()),
      ),
    );

    // return _buildBody();
  }
}
