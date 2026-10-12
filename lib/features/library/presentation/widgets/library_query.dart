import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/application/media_library_provider.dart';
import 'package:mochi_player/features/library/infrastructure/library_repository.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

/// Keeps a query subscription stable across unrelated parent rebuilds.
class LibraryQuery<T> extends StatefulWidget {
  const LibraryQuery({
    super.key,
    required this.queryKey,
    required this.query,
    required this.initialData,
    required this.builder,
    this.sliver = false,
    this.showLoading = false,
  });

  final Object queryKey;
  final Stream<T> Function(LibraryRepository) query;
  final T initialData;
  final Widget Function(BuildContext, T) builder;
  final bool sliver;
  final bool showLoading;

  @override
  State<LibraryQuery<T>> createState() => _LibraryQueryState<T>();
}

class _LibraryQueryState<T> extends State<LibraryQuery<T>> {
  Stream<T>? _stream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stream ??= widget.query(context.read<MediaLibraryProvider>().repository);
  }

  @override
  void didUpdateWidget(covariant LibraryQuery<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queryKey != widget.queryKey) {
      _stream = widget.query(context.read<MediaLibraryProvider>().repository);
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

/// Loads a bounded prefix, expanding it only as the reader scrolls.
class PagedLibraryQuery<T> extends StatefulWidget {
  const PagedLibraryQuery({super.key, required this.queryKey, required this.query, required this.builder});

  final Object queryKey;
  final Stream<List<T>> Function(LibraryRepository, int limit) query;
  final Widget Function(BuildContext, List<T>) builder;

  @override
  State<PagedLibraryQuery<T>> createState() => _PagedLibraryQueryState<T>();
}

class _PagedLibraryQueryState<T> extends State<PagedLibraryQuery<T>> {
  int _limit = 100;
  bool _awaiting = false;

  @override
  void didUpdateWidget(covariant PagedLibraryQuery<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queryKey != widget.queryKey) {
      _limit = 100;
      _awaiting = false;
    }
  }

  @override
  Widget build(BuildContext context) => LibraryQuery<List<T>>(
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
