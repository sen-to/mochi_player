// 【界面适配】将 Flutter 文本编辑操作接入应用菜单。
// 只适配编辑器菜单，不定义业务快捷键。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/components/overlay/internal/menu_parts.dart';
import 'package:mochi_player/l10n/l10n.dart';

/// 将 Flutter 文本编辑操作适配为应用菜单。
class AppTextContextMenu extends StatelessWidget {
  const AppTextContextMenu({super.key, required this.editableTextState});

  static const _screenMargin = 8.0;
  static const _menuWidth = 136.0;

  final EditableTextState editableTextState;

  static Widget buildForEditableText(BuildContext context, EditableTextState editableTextState) {
    return AppTextContextMenu(editableTextState: editableTextState);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ClipboardStatus>(
      valueListenable: editableTextState.clipboardStatus,
      builder: (context, clipboardStatus, child) {
        final topPadding = MediaQuery.paddingOf(context).top + _screenMargin;
        final localAdjustment = Offset(_screenMargin, topPadding);
        final buttonItems = _resolvedButtonItems(clipboardStatus);
        return Padding(
          padding: EdgeInsets.fromLTRB(_screenMargin, topPadding, _screenMargin, _screenMargin),
          child: CustomSingleChildLayout(
            delegate: DesktopTextSelectionToolbarLayoutDelegate(
              anchor: editableTextState.contextMenuAnchors.primaryAnchor - localAdjustment,
            ),
            child: SizedBox(
              width: _menuWidth,
              child: MenuPanel(
                children: [
                  for (final item in buttonItems)
                    MenuOptionRow(onPressed: item.onPressed, child: Text(_labelFor(context, item))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<ContextMenuButtonItem> _resolvedButtonItems(ClipboardStatus clipboardStatus) {
    final items = [...editableTextState.contextMenuButtonItems];
    final value = editableTextState.textEditingValue;
    final selection = value.selection;

    if (!items.any((item) => item.type == ContextMenuButtonType.paste)) {
      items.add(
        ContextMenuButtonItem(
          type: ContextMenuButtonType.paste,
          onPressed: clipboardStatus == ClipboardStatus.pasteable && !editableTextState.widget.readOnly
              ? () => editableTextState.pasteText(SelectionChangedCause.toolbar)
              : null,
        ),
      );
    }

    if (!items.any((item) => item.type == ContextMenuButtonType.selectAll)) {
      final allTextSelected = selection.isValid && selection.start == 0 && selection.end == value.text.length;
      items.add(
        ContextMenuButtonItem(
          type: ContextMenuButtonType.selectAll,
          onPressed: value.text.isNotEmpty && !allTextSelected
              ? () => editableTextState.selectAll(SelectionChangedCause.toolbar)
              : null,
        ),
      );
    }

    return items;
  }

  static String _labelFor(BuildContext context, ContextMenuButtonItem item) {
    return switch (item.type) {
      ContextMenuButtonType.cut => MaterialLocalizations.of(context).cutButtonLabel,
      ContextMenuButtonType.copy => MaterialLocalizations.of(context).copyButtonLabel,
      ContextMenuButtonType.paste => MaterialLocalizations.of(context).pasteButtonLabel,
      ContextMenuButtonType.selectAll => MaterialLocalizations.of(context).selectAllButtonLabel,
      ContextMenuButtonType.delete => MaterialLocalizations.of(context).deleteButtonTooltip,
      ContextMenuButtonType.lookUp => MaterialLocalizations.of(context).lookUpButtonLabel,
      ContextMenuButtonType.searchWeb => MaterialLocalizations.of(context).searchWebButtonLabel,
      ContextMenuButtonType.share => MaterialLocalizations.of(context).shareButtonLabel,
      ContextMenuButtonType.liveTextInput => context.l10n.liveTextInput,
      ContextMenuButtonType.custom => item.label ?? context.l10n.action,
    };
  }
}
