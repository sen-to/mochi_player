// 【查询界面】维护稳定的数据流订阅，并在滚动时扩展有限查询范围。
// 查询由媒体库 Provider 发起，组件不直接访问数据库。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/application/media_library_provider.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

/// 父级无关重建时保持查询订阅稳定。
class LibraryQueryView<T> extends StatefulWidget {
  const LibraryQueryView({
    super.key,
    required this.queryKey,
    required this.query,
    required this.initialData,
    required this.builder,
    this.sliver = false,
    this.showLoading = false,
  });

  final Object queryKey;
  final Stream<T> Function(MediaLibraryProvider) query;
  final T initialData;
  final Widget Function(BuildContext, T) builder;
  final bool sliver;
  final bool showLoading;

  @override
  State<LibraryQueryView<T>> createState() => _LibraryQueryViewState<T>();
}

class _LibraryQueryViewState<T> extends State<LibraryQueryView<T>> {
  Stream<T>? _stream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stream ??= widget.query(context.read<MediaLibraryProvider>());
  }

  @override
  void didUpdateWidget(covariant LibraryQueryView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queryKey != widget.queryKey) {
      _stream = widget.query(context.read<MediaLibraryProvider>());
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<T>(
    stream: _stream,
    initialData: widget.initialData,
    builder: (context, snapshot) {
      if (widget.showLoading && snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        final error = AppResult(status: AppResultStatus.error, title: context.l10n.contentLoadFailed);
        return widget.sliver ? SliverToBoxAdapter(child: error) : error;
      }
      return widget.builder(context, snapshot.data ?? widget.initialData);
    },
  );
}

/// 先加载有限结果前缀，只在用户滚动时扩展范围。
class PagedLibraryQueryView<T> extends StatefulWidget {
  const PagedLibraryQueryView({super.key, required this.queryKey, required this.query, required this.builder});

  final Object queryKey;
  final Stream<List<T>> Function(MediaLibraryProvider, int limit) query;
  final Widget Function(BuildContext, List<T>) builder;

  @override
  State<PagedLibraryQueryView<T>> createState() => _PagedLibraryQueryViewState<T>();
}

class _PagedLibraryQueryViewState<T> extends State<PagedLibraryQueryView<T>> {
  int _limit = 100;
  bool _awaiting = false;

  @override
  void didUpdateWidget(covariant PagedLibraryQueryView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queryKey != widget.queryKey) {
      _limit = 100;
      _awaiting = false;
    }
  }

  @override
  Widget build(BuildContext context) => LibraryQueryView<List<T>>(
    queryKey: (widget.queryKey, _limit),
    query: (repository) => widget.query(repository, _limit),
    initialData: const [],
    showLoading: _limit == 100,
    builder: (context, items) {
      if (items.length >= _limit) _awaiting = false;
      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical &&
              notification.metrics.extentAfter < 500 &&
              items.length >= _limit &&
              !_awaiting) {
            setState(() {
              _limit += 100;
              _awaiting = true;
            });
          }
          return false;
        },
        child: widget.builder(context, items),
      );
    },
  );
}
