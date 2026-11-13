import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Loads query results in small pages and fetches the next page near the end.
class FirestorePagedList extends StatefulWidget {
  const FirestorePagedList({
    required this.query,
    required this.queryKey,
    required this.itemBuilder,
    required this.emptyMessage,
    super.key,
  });

  final Query<Map<String, dynamic>> query;
  final String queryKey;
  final Widget Function(
    BuildContext,
    QueryDocumentSnapshot<Map<String, dynamic>>,
  ) itemBuilder;
  final String emptyMessage;

  @override
  State<FirestorePagedList> createState() => _FirestorePagedListState();
}

class _FirestorePagedListState extends State<FirestorePagedList> {
  static const _pageSize = 50;
  final _scrollController = ScrollController();
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _documents = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
    _loadFirstPage();
  }

  @override
  void didUpdateWidget(covariant FirestorePagedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queryKey != widget.queryKey) {
      _documents.clear();
      _hasMore = true;
      _error = null;
      _loadFirstPage();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() => _loading = true);
    try {
      final page = await widget.query.limit(_pageSize).get();
      if (!mounted) return;
      setState(() {
        _documents
          ..clear()
          ..addAll(page.docs);
        _hasMore = page.docs.length == _pageSize;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _maybeLoadMore() {
    if (_scrollController.position.extentAfter < 300) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _documents.isEmpty) return;
    setState(() {
      _loadingMore = true;
      _error = null;
    });
    try {
      final page = await widget.query
          .startAfterDocument(_documents.last)
          .limit(_pageSize)
          .get();
      if (!mounted) return;
      setState(() {
        _documents.addAll(page.docs);
        _hasMore = page.docs.length == _pageSize;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loadingMore = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _documents.isEmpty) {
      return const Center(child: Text('Error loading data'));
    }
    if (_documents.isEmpty) return Center(child: Text(widget.emptyMessage));
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: _documents.length + (_loadingMore || _error != null ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == _documents.length) {
          return Center(
            child: _loadingMore
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  )
                : TextButton(
                    onPressed: _loadMore,
                    child: const Text('Could not load more. Retry'),
                  ),
          );
        }
        return widget.itemBuilder(context, _documents[index]);
      },
    );
  }
}
