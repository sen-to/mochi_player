import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mochi_player/core/ui/components/input/app_input.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';

/// A search-specific composition of [AppInput].
class AppSearchInput extends StatefulWidget {
  const AppSearchInput({super.key, this.placeholder = '搜索...', this.onChanged, this.focusNode});

  final String placeholder;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  @override
  State<AppSearchInput> createState() => _AppSearchInputState();
}

class _AppSearchInputState extends State<AppSearchInput> {
  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  final TextEditingController _controller = TextEditingController();
  bool _hasFocus = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _attachFocusNode(widget.focusNode);
    _controller.addListener(_handleTextChange);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void didUpdateWidget(AppSearchInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;
    _detachFocusNode();
    _attachFocusNode(widget.focusNode);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _detachFocusNode();
    _controller.removeListener(_handleTextChange);
    _controller.dispose();
    super.dispose();
  }

  void _attachFocusNode(FocusNode? focusNode) {
    _ownsFocusNode = focusNode == null;
    _focusNode = focusNode ?? FocusNode();
    _hasFocus = _focusNode.hasFocus;
    _focusNode.addListener(_handleFocusChange);
  }

  void _detachFocusNode() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
  }

  void _handleFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (_hasFocus == hasFocus) return;
    setState(() => _hasFocus = hasFocus);
  }

  void _handleTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (_hasText == hasText) return;
    setState(() => _hasText = hasText);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || !TickerMode.valuesOf(context).enabled) {
      return false;
    }
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;

    if (event.logicalKey == LogicalKeyboardKey.keyK &&
        (HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed)) {
      if (!_focusNode.hasFocus) _focusNode.requestFocus();
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape && _focusNode.hasFocus) {
      _focusNode.unfocus();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RepaintBoundary(
      child: AppInput.search(
        controller: _controller,
        focusNode: _focusNode,
        placeholder: widget.placeholder,
        onChanged: widget.onChanged,
        prefix: Icon(
          CupertinoIcons.search,
          size: 18,
          color: _hasFocus ? theme.textTheme.bodyMedium?.color : AppColors.placeholderForeground(context),
        ),
        suffix: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: _hasText ? _buildClearButton() : _buildShortcutHint(),
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          _controller.clear();
          widget.onChanged?.call('');
        },
        child: Container(
          key: const ValueKey('clear_button'),
          width: 18,
          height: 18,
          decoration: BoxDecoration(color: Colors.grey[300]?.withAlpha(128), shape: BoxShape.circle),
          child: Icon(Icons.close, size: 12, color: Colors.grey[700]),
        ),
      ),
    );
  }

  Widget _buildShortcutHint() {
    final modifierKey = Theme.of(context).platform == TargetPlatform.macOS ? '⌘' : 'Ctrl';

    return Row(
      key: const ValueKey('key_cap_hint'),
      mainAxisSize: MainAxisSize.min,
      children: [_ShortcutKeyCap(modifierKey), const SizedBox(width: 4), const _ShortcutKeyCap('K')],
    );
  }
}

class _ShortcutKeyCap extends StatelessWidget {
  const _ShortcutKeyCap(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: label.length > 1 ? 28 : 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.keyCapBackground(context),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(26), offset: const Offset(0, 1), blurRadius: 1)],
        border: Border.all(color: Colors.black.withAlpha(13)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.keyCapForeground(context)),
      ),
    );
  }
}
