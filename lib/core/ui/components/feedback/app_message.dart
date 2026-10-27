// 【消息界面】提供成功、失败、警告和加载提示及其队列宿主。
// 消息归属调用方所在视图；加载提示由返回的句柄关闭。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_radii.dart';
import 'package:mochi_player/core/ui/theme/app_spacing.dart';

/// 供页面调用的短时应用消息入口。
abstract final class AppMessage {
  static const _defaultDuration = Duration(seconds: 3);

  static void success(BuildContext context, String content, {Duration duration = _defaultDuration}) {
    _show(context, content, _MessageType.success, duration);
  }

  static void error(BuildContext context, String content, {Duration duration = _defaultDuration}) {
    _show(context, content, _MessageType.error, duration);
  }

  static void warning(BuildContext context, String content, {Duration duration = _defaultDuration}) {
    _show(context, content, _MessageType.warning, duration);
  }

  static AppMessageHandle loading(BuildContext context, String content, {Duration? duration}) {
    return _show(context, content, _MessageType.loading, duration);
  }

  static AppMessageHandle _show(BuildContext context, String content, _MessageType type, Duration? duration) {
    final controller = context.getInheritedWidgetOfExactType<_MessageScope>()?.controller;
    if (controller == null) {
      throw StateError('AppMessageHost is not mounted.');
    }
    return controller.show(message: content, type: type, duration: duration);
  }
}

/// 允许任务完成后主动关闭持续显示的加载提示。
class AppMessageHandle {
  AppMessageHandle._(this._dismiss);

  VoidCallback? _dismiss;

  void dismiss() {
    _dismiss?.call();
    _dismiss = null;
  }
}

/// 安装 [AppMessage] 内部使用的队列与展示宿主。
class AppMessageHost extends StatefulWidget {
  const AppMessageHost({super.key, required this.child, this.top = 70, this.horizontalPadding = AppSpacing.page});

  final Widget child;
  final double top;
  final double horizontalPadding;

  @override
  State<AppMessageHost> createState() => _AppMessageHostState();
}

class _AppMessageHostState extends State<AppMessageHost> {
  final _controller = _MessageQueueController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MessageScope(
      controller: _controller,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
            top: widget.top,
            left: widget.horizontalPadding,
            right: widget.horizontalPadding,
            child: IgnorePointer(child: _MessageStack(controller: _controller)),
          ),
        ],
      ),
    );
  }
}

class _MessageScope extends InheritedWidget {
  const _MessageScope({required this.controller, required super.child});
  final _MessageQueueController controller;
  @override
  bool updateShouldNotify(_MessageScope oldWidget) => oldWidget.controller != controller;
}

class _MessageQueueController extends ChangeNotifier {
  static const dismissAnimationDuration = Duration(milliseconds: 140);

  final List<_QueuedMessage> messages = [];
  final Map<int, Timer> _timers = {};
  final Set<int> _dismissingIds = {};
  var _nextId = 0;
  var _disposed = false;

  AppMessageHandle show({required String message, required _MessageType type, required Duration? duration}) {
    if (_disposed) throw StateError('The message host has been disposed.');

    final id = _nextId++;
    messages.add(_QueuedMessage(id: id, message: message, type: type, visible: false));
    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dismissingIds.contains(id)) return;
      _updateVisibility(id, visible: true);
    });
    if (duration != null) {
      _timers[id] = Timer(duration, () => dismiss(id));
    }
    return AppMessageHandle._(() => dismiss(id));
  }

  void dismiss(int id) {
    if (_disposed) return;

    _timers.remove(id)?.cancel();
    if (!messages.any((message) => message.id == id)) return;
    _dismissingIds.add(id);
    _updateVisibility(id, visible: false);
    _timers[id] = Timer(dismissAnimationDuration, () => _remove(id));
  }

  bool _updateVisibility(int id, {required bool visible}) {
    if (_disposed) return false;
    final index = messages.indexWhere((message) => message.id == id);
    if (index == -1 || messages[index].visible == visible) return false;

    messages[index] = messages[index].copyWith(visible: visible);
    notifyListeners();
    return true;
  }

  void _remove(int id) {
    if (_disposed) return;
    _timers.remove(id)?.cancel();
    _dismissingIds.remove(id);
    messages.removeWhere((message) => message.id == id);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _dismissingIds.clear();
    messages.clear();
    super.dispose();
  }
}

class _MessageStack extends StatelessWidget {
  const _MessageStack({required this.controller});

  final _MessageQueueController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < controller.messages.length; index++)
              _AnimatedQueuedMessage(
                key: ValueKey(controller.messages[index].id),
                message: controller.messages[index],
                bottomSpacing: index == controller.messages.length - 1 ? 0 : AppSpacing.sm,
              ),
          ],
        );
      },
    );
  }
}

class _AnimatedQueuedMessage extends StatefulWidget {
  const _AnimatedQueuedMessage({super.key, required this.message, required this.bottomSpacing});

  final _QueuedMessage message;
  final double bottomSpacing;

  @override
  State<_AnimatedQueuedMessage> createState() => _AnimatedQueuedMessageState();
}

class _AnimatedQueuedMessageState extends State<_AnimatedQueuedMessage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  var _isExiting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _MessageQueueController.dismissAnimationDuration,
      value: widget.message.visible ? 1 : 0,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
  }

  @override
  void didUpdateWidget(covariant _AnimatedQueuedMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.visible == widget.message.visible) return;
    if (widget.message.visible) {
      _isExiting = false;
      _controller.forward();
    } else {
      _isExiting = true;
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Align(
          alignment: Alignment.topCenter,
          heightFactor: _isExiting ? _animation.value : 1,
          child: Opacity(
            opacity: _animation.value,
            child: Transform.translate(offset: Offset(0, -10 * (1 - _animation.value)), child: child),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.bottomSpacing),
        child: _MessageCard(message: widget.message.message, type: widget.message.type),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.type});

  final String message;
  final _MessageType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = _accentColor(context);
    final surfaceColor = Color.alphaBlend(accentColor.withAlpha(26), AppColors.activitySurface(context));

    return DefaultTextStyle.merge(
      style: const TextStyle(decoration: TextDecoration.none),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.compact),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppRadii.control),
            border: Border.all(color: accentColor.withAlpha(150)),
            boxShadow: [BoxShadow(color: accentColor.withAlpha(42), blurRadius: 22, offset: const Offset(0, 10))],
          ),
          child: Row(
            children: [
              _leading(accentColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leading(Color color) {
    return switch (type) {
      _MessageType.success => Icon(Icons.check_circle_outline_rounded, size: 18, color: color),
      _MessageType.error => Icon(Icons.error_outline_rounded, size: 18, color: color),
      _MessageType.warning => Icon(Icons.info_outline_rounded, size: 18, color: color),
      _MessageType.loading => SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      ),
    };
  }

  Color _accentColor(BuildContext context) {
    return switch (type) {
      _MessageType.success => AppColors.success(context),
      _MessageType.error => AppColors.danger(context),
      _MessageType.warning => AppColors.rating,
      _MessageType.loading => Theme.of(context).colorScheme.primary,
    };
  }
}

enum _MessageType { success, error, warning, loading }

class _QueuedMessage {
  const _QueuedMessage({required this.id, required this.message, required this.type, required this.visible});

  final int id;
  final String message;
  final _MessageType type;
  final bool visible;

  _QueuedMessage copyWith({required bool visible}) {
    return _QueuedMessage(id: id, message: message, type: type, visible: visible);
  }
}
